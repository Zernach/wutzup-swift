//
//  ConversationViewModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var typingUsers: [String: Bool] = [:]
    @Published var visibleMessageIds: Set<String> = []
    @Published var isGeneratingAI = false
    @Published var aiSuggestion: AIResponseSuggestion?
    @Published var showingAISuggestion = false
    @Published var showingGIFGenerator = false
    @Published var isGeneratingGIF = false
    @Published var generatedGIFURL: String?
    @Published var generatedGIFPrompt: String?
    @Published var isGeneratingCoreMLAI = false
    @Published var showingResearch = false
    @Published var isConductingResearch = false
    
    let conversation: Conversation
    private let messageService: MessageService
    private let _presenceService: PresenceService
    private let authService: AuthenticationService
    private let draftManager: DraftManager
    private let aiService: AIService
    private let coreMLAIService: AIService
    private let gifService: GIFService
    private let researchService: ResearchService
    private let networkMonitor = NetworkMonitor.shared
    private let offlineQueue = OfflineMessageQueue.shared
    
    // Expose presenceService for use by child views
    var presenceService: PresenceService {
        _presenceService
    }
    
    private var messageObservationTask: Task<Void, Never>?
    private var typingObservationTask: Task<Void, Never>?
    private var typingTimer: Timer?
    private var readReceiptDebounceTask: Task<Void, Never>?
    private var networkObserver: Any?
    private var autoSyncTask: Task<Void, Never>?
    
    // Lifecycle state
    private var isObserving = false
    private var isPaused = false
    private var lastSyncTimestamp: Date?
    
    init(conversation: Conversation, messageService: MessageService, presenceService: PresenceService, authService: AuthenticationService, aiService: AIService = FirebaseAIService(), coreMLAIService: AIService = CoreMLAIService(), gifService: GIFService = FirebaseGIFService(), researchService: ResearchService = FirebaseResearchService(), draftManager: DraftManager = .shared) {
        self.conversation = conversation
        self.messageService = messageService
        self._presenceService = presenceService
        self.authService = authService
        self.aiService = aiService
        self.coreMLAIService = coreMLAIService
        self.gifService = gifService
        self.researchService = researchService
        self.draftManager = draftManager
        
        // Setup network reconnection observer
        setupNetworkObserver()
    }
    
    deinit {
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        autoSyncTask?.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkObserver() {
        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkDidReconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            Task { @MainActor in
                
                // Get downtime from notification
                let downtime = notification.userInfo?["downtime"] as? TimeInterval ?? 0
                
                // Sync offline queue
                await self.syncOfflineMessages()
                
                // Re-fetch messages if we were offline for more than 30 seconds
                if downtime > 30 {
                    await self.fetchMessages()
                }
            }
        }
    }
    
    /// Sync all pending offline messages
    func syncOfflineMessages() async {
        guard networkMonitor.isConnected else {
            return
        }
        
        await offlineQueue.syncPendingMessages(messageService: messageService)
    }
    
    /// Load any saved draft message for this conversation
    func loadDraft() {
        if let draft = draftManager.loadDraft(for: conversation.id) {
            messageText = draft
        }
    }
    
    /// Save the current message text as a draft
    func saveDraft() {
        draftManager.saveDraft(messageText, for: conversation.id)
    }
    
    // MARK: - Visibility Tracking for Read Receipts
    
    /// Mark a message as visible on screen
    func markMessageVisible(_ messageId: String) {
        visibleMessageIds.insert(messageId)
        scheduleReadReceiptUpdate()
    }
    
    /// Mark a message as no longer visible
    func markMessageInvisible(_ messageId: String) {
        visibleMessageIds.remove(messageId)
    }
    
    /// Debounce: wait 1 second before marking messages as read
    private func scheduleReadReceiptUpdate() {
        readReceiptDebounceTask?.cancel()
        readReceiptDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await markVisibleMessagesAsRead()
        }
    }
    
    /// Mark all currently visible messages as read (batch operation)
    private func markVisibleMessagesAsRead() async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        // Find visible messages that haven't been read yet
        let unreadVisibleMessages = messages.filter { message in
            visibleMessageIds.contains(message.id) &&
            !message.isFromCurrentUser &&
            !message.readBy.contains(currentUserId)
        }
        
        guard !unreadVisibleMessages.isEmpty else { return }
        
        
        // Use batch operation for efficiency
        let messageIds = unreadVisibleMessages.map { $0.id }
        do {
            try await messageService.batchMarkAsRead(
                conversationId: conversation.id,
                messageIds: messageIds,
                userId: currentUserId
            )
        } catch {
        }
    }
    
    // MARK: - Delivery Tracking
    
    /// Mark messages as delivered when conversation opens or app foregrounds
    func markUndeliveredMessagesAsDelivered() async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        // Find messages not yet delivered to current user
        let undeliveredMessages = messages.filter { message in
            !message.isFromCurrentUser && !message.deliveredTo.contains(currentUserId)
        }
        
        guard !undeliveredMessages.isEmpty else { return }
        
        
        // Use batch operation for efficiency
        let messageIds = undeliveredMessages.map { $0.id }
        do {
            try await messageService.batchMarkAsDelivered(
                conversationId: conversation.id,
                messageIds: messageIds,
                userId: currentUserId
            )
        } catch {
        }
    }
    
    func startObserving() {
        isObserving = true
        isPaused = false
        
        // Observe messages
        messageObservationTask?.cancel()
        messageObservationTask = Task {
            for await message in messageService.observeMessages(conversationId: conversation.id) {
                
                // Calculate status based on readBy/deliveredTo arrays
                var updatedMessage = message
                
                if message.isFromCurrentUser {
                    // For sent messages, calculate status based on recipient's actions
                    let otherParticipants = conversation.participantIds.filter { $0 != authService.currentUser?.id }
                    
                    if otherParticipants.allSatisfy({ message.readBy.contains($0) }) {
                        updatedMessage.status = .read
                    } else if otherParticipants.allSatisfy({ message.deliveredTo.contains($0) }) {
                        updatedMessage.status = .delivered
                    } else if !message.deliveredTo.isEmpty || !message.readBy.isEmpty {
                        updatedMessage.status = .sent
                    }
                }
                
                // Update or add message
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index] = updatedMessage
                } else {
                    messages.append(updatedMessage)
                }
                
                // Sort by timestamp
                messages.sort { $0.timestamp < $1.timestamp }
                
                // Auto-mark received messages as delivered (NOT read - that happens via visibility)
                if !message.isFromCurrentUser, let userId = authService.currentUser?.id {
                    if !message.deliveredTo.contains(userId) {
                        Task {
                            try? await messageService.markAsDelivered(
                                conversationId: conversation.id,
                                messageId: message.id,
                                userId: userId
                            )
                        }
                    }
                    // Read marking now handled by visibility tracking
                }
            }
        }
        
        // Observe typing indicators
        typingObservationTask?.cancel()
        typingObservationTask = Task {
            for await typing in _presenceService.observeTyping(conversationId: conversation.id) {
                typingUsers = typing
            }
        }
    }
    
    func stopObserving() {
        isObserving = false
        isPaused = false
        messageObservationTask?.cancel()
        messageObservationTask = nil
        typingObservationTask?.cancel()
        typingObservationTask = nil
        
        // Save draft before leaving
        saveDraft()
        
        // Stop typing indicator on leave
        if let userId = authService.currentUser?.id {
            Task {
                try? await _presenceService.setTyping(
                    userId: userId,
                    conversationId: conversation.id,
                    isTyping: false
                )
            }
        }
    }
    
    /// Pause listeners for battery efficiency (called when app goes to background)
    func pauseListeners() {
        guard isObserving && !isPaused else {
            return
        }
        
        isPaused = true
        lastSyncTimestamp = Date()
        
        // Cancel observation tasks but keep state to resume later
        messageObservationTask?.cancel()
        messageObservationTask = nil
        typingObservationTask?.cancel()
        typingObservationTask = nil
        
        // Save draft
        saveDraft()
        
    }
    
    /// Resume listeners after returning to foreground
    func resumeListeners() async {
        guard isPaused else {
            return
        }
        
        isPaused = false
        
        // Sync missed messages if needed
        await syncMissedMessages()
        
        // Restart observations
        startObserving()
        
    }
    
    /// Sync messages that arrived while app was in background
    func syncMissedMessages() async {
        guard let lastSync = lastSyncTimestamp else {
            return
        }
        
        let timeSinceSync = Date().timeIntervalSince(lastSync)
        
        // Only sync if we've been away for more than 10 seconds
        guard timeSinceSync > 10 else {
            return
        }
        
        
        do {
            // Fetch recent messages
            let recentMessages = try await messageService.fetchMessages(
                conversationId: conversation.id,
                limit: 50 // Fetch more to ensure we get everything
            )
            
            // Merge with existing messages (avoiding duplicates)
            var updatedMessages = messages
            for newMessage in recentMessages {
                if !updatedMessages.contains(where: { $0.id == newMessage.id }) {
                    updatedMessages.append(newMessage)
                }
            }
            
            // Sort by timestamp
            updatedMessages.sort { $0.timestamp < $1.timestamp }
            messages = updatedMessages
            
            // Mark undelivered messages as delivered
            await markUndeliveredMessagesAsDelivered()
            
            
        } catch {
        }
        
        lastSyncTimestamp = Date()
    }
    
    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            messages = try await messageService.fetchMessages(
                conversationId: conversation.id,
                limit: AppConstants.Limits.messagesPerPage
            )
            
            // Mark all undelivered messages as delivered after fetching
            await markUndeliveredMessagesAsDelivered()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func sendMessage(content: String) async {
        
        guard let currentUser = authService.currentUser else {
            errorMessage = "User not authenticated"
            return
        }
        
        isSending = true
        
        // Create optimistic message immediately with .sending status
        let optimisticMessage = Message(
            conversationId: conversation.id,
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            content: content,
            timestamp: Date(),
            status: .sending,  // Optimistic status
            isFromCurrentUser: true
        )
        
        
        // Add to UI immediately (optimistic update)
        messages.append(optimisticMessage)
        messages.sort { $0.timestamp < $1.timestamp }
        
        // Remove draft since we're sending
        draftManager.removeDraft(for: conversation.id)
        
        // Stop typing indicator
        try? await _presenceService.setTyping(
            userId: currentUser.id,
            conversationId: conversation.id,
            isTyping: false
        )
        
        // Check if we're offline - if so, queue the message
        if !networkMonitor.isConnected {
            offlineQueue.enqueue(optimisticMessage)
            
            // Update message status to indicate it's queued
            if let index = messages.firstIndex(where: { $0.id == optimisticMessage.id }) {
                var queuedMessage = messages[index]
                queuedMessage.status = .sending // Keep showing sending status
                messages[index] = queuedMessage
            }
            
            isSending = false
            return
        }
        
        // Send to server in background (pass the optimistic message ID)
        do {
            let serverMessage = try await messageService.sendMessage(
                conversationId: conversation.id,
                content: content,
                mediaUrl: nil,
                mediaType: nil,
                messageId: optimisticMessage.id  // Use same ID as optimistic message
            )
            
            
            // Update optimistic message with server response
            if let index = messages.firstIndex(where: { $0.id == optimisticMessage.id }) {
                messages[index] = serverMessage
            }
            // Note: The Firestore listener will also pick up this message and may add it again,
            // but the duplicate check in startObserving() will handle that
            
        } catch {
            
            // Check if error is network-related
            let isNetworkError = (error as NSError).domain == NSURLErrorDomain ||
                                 !networkMonitor.isConnected
            
            if isNetworkError {
                offlineQueue.enqueue(optimisticMessage)
                
                // Keep showing sending status (will sync when online)
                if let index = messages.firstIndex(where: { $0.id == optimisticMessage.id }) {
                    var queuedMessage = messages[index]
                    queuedMessage.status = .sending
                    messages[index] = queuedMessage
                }
            } else {
                // Non-network error - mark as failed
                if let index = messages.firstIndex(where: { $0.id == optimisticMessage.id }) {
                    var failedMessage = messages[index]
                    failedMessage.status = .failed
                    messages[index] = failedMessage
                }
                
                errorMessage = error.localizedDescription
                messageText = content // Restore text on error
            }
        }
        
        isSending = false
    }
    
    func onTypingChanged() {
        guard let userId = authService.currentUser?.id else { return }
        
        // Save draft whenever text changes
        saveDraft()
        
        // Cancel previous timer
        typingTimer?.invalidate()
        
        // Set typing indicator
        Task {
            try? await _presenceService.setTyping(
                userId: userId,
                conversationId: conversation.id,
                isTyping: !messageText.isEmpty
            )
        }
        
        // Auto-stop typing after 3 seconds
        if !messageText.isEmpty {
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    try? await self._presenceService.setTyping(
                        userId: userId,
                        conversationId: self.conversation.id,
                        isTyping: false
                    )
                }
            }
        }
    }
    
    var typingIndicatorText: String? {
        let currentUserId = authService.currentUser?.id
        let typingUserIds = typingUsers.filter { $0.key != currentUserId && $0.value }.map { $0.key }
        
        if typingUserIds.isEmpty {
            return nil
        }
        
        if typingUserIds.count == 1, let userId = typingUserIds.first {
            let name = conversation.participantNames[userId] ?? "Someone"
            return "\(name) is typing..."
        } else {
            return "Multiple people are typing..."
        }
    }
    
    func retryMessage(_ message: Message) async {
        
        // Update status to sending
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            var retryingMessage = messages[index]
            retryingMessage.status = .sending
            messages[index] = retryingMessage
        }
        
        // Attempt to send again
        do {
            let serverMessage = try await messageService.sendMessage(
                conversationId: conversation.id,
                content: message.content,
                mediaUrl: message.mediaUrl,
                mediaType: message.mediaType,
                messageId: message.id  // Use same ID
            )
            
            
            // Update with server response
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = serverMessage
            }
            
        } catch {
            
            // Update back to failed status
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                var failedMessage = messages[index]
                failedMessage.status = .failed
                messages[index] = failedMessage
            }
            
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - AI Response Suggestions
    
    func generateAIResponseSuggestions() async {
        guard !messages.isEmpty else {
            return
        }
        
        // Immediately show the sheet with loading state
        showingAISuggestion = true
        isGeneratingAI = true
        
        do {
            let userPersonality = authService.currentUser?.personality
            
            
            let suggestion = try await aiService.generateResponseSuggestions(
                conversationHistory: messages,
                userPersonality: userPersonality
            )
            
            
            aiSuggestion = suggestion
            
        } catch {
            errorMessage = "Failed to generate suggestions: \(error.localizedDescription)"
            showingAISuggestion = false  // Close sheet on error
        }
        
        isGeneratingAI = false
    }
    
    func selectAISuggestion(_ response: String) {
        messageText = response
        showingAISuggestion = false
        aiSuggestion = nil
    }
    
    func dismissAISuggestion() {
        showingAISuggestion = false
        aiSuggestion = nil
    }
    
    // MARK: - CoreML AI Response Suggestions
    
    func generateCoreMLAIResponseSuggestions() async {
        guard !messages.isEmpty else {
            return
        }
        
        // Immediately show the sheet with loading state
        showingAISuggestion = true
        isGeneratingCoreMLAI = true
        
        do {
            let userPersonality = authService.currentUser?.personality
            
            
            let suggestion = try await coreMLAIService.generateResponseSuggestions(
                conversationHistory: messages,
                userPersonality: userPersonality
            )
            
            
            aiSuggestion = suggestion
            
        } catch {
            errorMessage = "Failed to generate suggestions: \(error.localizedDescription)"
            showingAISuggestion = false  // Close sheet on error
        }
        
        isGeneratingCoreMLAI = false
    }
    
    // MARK: - GIF Generation
    
    func showGIFGenerator() {
        showingGIFGenerator = true
    }
    
    func generateGIF(prompt: String) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isGeneratingGIF = true
        generatedGIFURL = nil // Clear previous GIF
        
        do {
            
            // Generate GIF
            let gifURL = try await gifService.generateGIF(prompt: prompt)
            
            
            // Store the generated GIF for preview (don't send yet)
            generatedGIFURL = gifURL
            generatedGIFPrompt = prompt
            
        } catch {
            errorMessage = "Failed to generate GIF: \(error.localizedDescription)"
            showingGIFGenerator = false
        }
        
        isGeneratingGIF = false
    }
    
    func approveAndSendGIF() async {
        guard let gifURL = generatedGIFURL,
              let prompt = generatedGIFPrompt else {
            return
        }
        
        do {
            
            // Send as message
            try await messageService.sendMessage(
                conversationId: conversation.id,
                content: "🎬 Generated GIF: \(prompt)",
                mediaUrl: gifURL,
                mediaType: "image/gif",
                messageId: nil
            )
            
            
            // Clean up
            generatedGIFURL = nil
            generatedGIFPrompt = nil
            showingGIFGenerator = false
            
        } catch {
            errorMessage = "Failed to send GIF: \(error.localizedDescription)"
        }
    }
    
    func rejectGIF() {
        generatedGIFURL = nil
        generatedGIFPrompt = nil
        // Keep the sheet open for regeneration
    }
    
    func cancelGIFGenerator() {
        generatedGIFURL = nil
        generatedGIFPrompt = nil
        showingGIFGenerator = false
    }
    
    // MARK: - Research
    
    func showResearch() {
        showingResearch = true
    }
    
    func conductResearch(prompt: String) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isConductingResearch = true
        showingResearch = false
        
        do {
            
            // Conduct research
            let summary = try await researchService.conductResearch(prompt: prompt)
            
            
            // Send as message
            let researchMessage = """
            🔍 Research Results: \(prompt)
            
            \(summary)
            """
            
            try await messageService.sendMessage(
                conversationId: conversation.id,
                content: researchMessage,
                mediaUrl: nil,
                mediaType: nil,
                messageId: nil
            )
            
            
        } catch {
            errorMessage = "Failed to conduct research: \(error.localizedDescription)"
        }
        
        isConductingResearch = false
    }
}


