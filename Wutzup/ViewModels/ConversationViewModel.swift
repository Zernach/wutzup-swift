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
    
    // Expose presenceService for use by child views
    var presenceService: PresenceService {
        _presenceService
    }
    
    private var messageObservationTask: Task<Void, Never>?
    private var typingObservationTask: Task<Void, Never>?
    private var typingTimer: Timer?
    private var readReceiptDebounceTask: Task<Void, Never>?
    
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
    }
    
    /// Load any saved draft message for this conversation
    func loadDraft() {
        if let draft = draftManager.loadDraft(for: conversation.id) {
            messageText = draft
            print("📝 [ConversationViewModel] Loaded draft: '\(draft)'")
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
        
        print("👁️ [ConversationViewModel] Marking \(unreadVisibleMessages.count) visible messages as read")
        
        // Use batch operation for efficiency
        let messageIds = unreadVisibleMessages.map { $0.id }
        do {
            try await messageService.batchMarkAsRead(
                conversationId: conversation.id,
                messageIds: messageIds,
                userId: currentUserId
            )
        } catch {
            print("❌ [ConversationViewModel] Failed to batch mark as read: \(error)")
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
        
        print("📬 [ConversationViewModel] Marking \(undeliveredMessages.count) messages as delivered")
        
        // Use batch operation for efficiency
        let messageIds = undeliveredMessages.map { $0.id }
        do {
            try await messageService.batchMarkAsDelivered(
                conversationId: conversation.id,
                messageIds: messageIds,
                userId: currentUserId
            )
        } catch {
            print("❌ [ConversationViewModel] Failed to batch mark as delivered: \(error)")
        }
    }
    
    func startObserving() {
        print("🟢 [ConversationViewModel] startObserving() - ENTRY")
        
        // Observe messages
        messageObservationTask?.cancel()
        messageObservationTask = Task {
            print("🟢 [ConversationViewModel] Starting message observation Task")
            for await message in messageService.observeMessages(conversationId: conversation.id) {
                print("🟢 [ConversationViewModel] Received message from listener:")
                print("🟢 [ConversationViewModel]   messageId: \(message.id)")
                print("🟢 [ConversationViewModel]   content: '\(message.content)'")
                print("🟢 [ConversationViewModel]   status: \(message.status)")
                
                // Calculate status based on readBy/deliveredTo arrays
                var updatedMessage = message
                
                if message.isFromCurrentUser {
                    // For sent messages, calculate status based on recipient's actions
                    let otherParticipants = conversation.participantIds.filter { $0 != authService.currentUser?.id }
                    
                    if otherParticipants.allSatisfy({ message.readBy.contains($0) }) {
                        updatedMessage.status = .read
                        print("🟢 [ConversationViewModel]   Calculated status: .read (all read)")
                    } else if otherParticipants.allSatisfy({ message.deliveredTo.contains($0) }) {
                        updatedMessage.status = .delivered
                        print("🟢 [ConversationViewModel]   Calculated status: .delivered (all delivered)")
                    } else if !message.deliveredTo.isEmpty || !message.readBy.isEmpty {
                        updatedMessage.status = .sent
                        print("🟢 [ConversationViewModel]   Calculated status: .sent")
                    }
                }
                
                // Update or add message
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    print("🟢 [ConversationViewModel]   Updating existing message at index \(index)")
                    messages[index] = updatedMessage
                } else {
                    print("🟢 [ConversationViewModel]   Adding new message to array")
                    messages.append(updatedMessage)
                }
                
                // Sort by timestamp
                messages.sort { $0.timestamp < $1.timestamp }
                print("🟢 [ConversationViewModel]   Total messages: \(messages.count)")
                
                // Auto-mark received messages as delivered (NOT read - that happens via visibility)
                if !message.isFromCurrentUser, let userId = authService.currentUser?.id {
                    if !message.deliveredTo.contains(userId) {
                        print("🟢 [ConversationViewModel]   Auto-marking new message as delivered")
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
            print("🟢 [ConversationViewModel] Message observation Task ended")
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
        print("🟢 [ConversationViewModel] sendMessage() - ENTRY")
        print("🟢 [ConversationViewModel] content: '\(content)'")
        print("🟢 [ConversationViewModel] conversationId: \(conversation.id)")
        
        guard let currentUser = authService.currentUser else {
            print("❌ [ConversationViewModel] No current user")
            errorMessage = "User not authenticated"
            return
        }
        
        print("🟢 [ConversationViewModel] Setting isSending = true")
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
        
        print("🟢 [ConversationViewModel] Adding optimistic message to UI")
        print("🟢 [ConversationViewModel]   messageId: \(optimisticMessage.id)")
        print("🟢 [ConversationViewModel]   status: .sending")
        
        // Add to UI immediately (optimistic update)
        messages.append(optimisticMessage)
        messages.sort { $0.timestamp < $1.timestamp }
        
        // Remove draft since we're sending
        print("📝 [ConversationViewModel] Removing draft after sending message")
        draftManager.removeDraft(for: conversation.id)
        
        // Stop typing indicator
        print("🟢 [ConversationViewModel] Stopping typing indicator for user: \(currentUser.id)")
        try? await _presenceService.setTyping(
            userId: currentUser.id,
            conversationId: conversation.id,
            isTyping: false
        )
        
        // Send to server in background (pass the optimistic message ID)
        print("🟢 [ConversationViewModel] Calling messageService.sendMessage()")
        do {
            let serverMessage = try await messageService.sendMessage(
                conversationId: conversation.id,
                content: content,
                mediaUrl: nil,
                mediaType: nil,
                messageId: optimisticMessage.id  // Use same ID as optimistic message
            )
            
            print("✅ [ConversationViewModel] Message sent successfully!")
            print("✅ [ConversationViewModel]   messageId: \(serverMessage.id)")
            print("✅ [ConversationViewModel]   status: \(serverMessage.status)")
            
            // Update optimistic message with server response
            if let index = messages.firstIndex(where: { $0.id == optimisticMessage.id }) {
                print("🟢 [ConversationViewModel] Updating optimistic message with server data")
                messages[index] = serverMessage
            }
            // Note: The Firestore listener will also pick up this message and may add it again,
            // but the duplicate check in startObserving() will handle that
            
        } catch {
            print("❌ [ConversationViewModel] ERROR sending message: \(error)")
            print("❌ [ConversationViewModel] Error type: \(type(of: error))")
            print("❌ [ConversationViewModel] Error description: \(error.localizedDescription)")
            
            // Update optimistic message to failed status
            if let index = messages.firstIndex(where: { $0.id == optimisticMessage.id }) {
                print("🟢 [ConversationViewModel] Updating message status to .failed")
                var failedMessage = messages[index]
                failedMessage.status = .failed
                messages[index] = failedMessage
            }
            
            errorMessage = error.localizedDescription
            messageText = content // Restore text on error
        }
        
        print("🟢 [ConversationViewModel] Setting isSending = false")
        isSending = false
        print("🟢 [ConversationViewModel] sendMessage() - EXIT")
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
        print("🟢 [ConversationViewModel] retryMessage() - ENTRY")
        print("🟢 [ConversationViewModel] messageId: \(message.id)")
        
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
            
            print("✅ [ConversationViewModel] Message retry successful!")
            
            // Update with server response
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = serverMessage
            }
            
        } catch {
            print("❌ [ConversationViewModel] Message retry failed: \(error)")
            
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
            print("❌ No messages to generate suggestions from")
            return
        }
        
        isGeneratingAI = true
        
        do {
            let userPersonality = authService.currentUser?.personality
            
            print("🤖 Generating AI suggestions...")
            print("   Conversation history: \(messages.count) messages")
            print("   User personality: \(userPersonality ?? "none")")
            
            let suggestion = try await aiService.generateResponseSuggestions(
                conversationHistory: messages,
                userPersonality: userPersonality
            )
            
            print("✅ AI suggestions generated!")
            print("   Positive: \(suggestion.positiveResponse)")
            print("   Negative: \(suggestion.negativeResponse)")
            
            aiSuggestion = suggestion
            showingAISuggestion = true
            
        } catch {
            print("❌ Error generating AI suggestions: \(error)")
            errorMessage = "Failed to generate suggestions: \(error.localizedDescription)"
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
            print("❌ No messages to generate suggestions from")
            return
        }
        
        isGeneratingCoreMLAI = true
        
        do {
            let userPersonality = authService.currentUser?.personality
            
            print("🧠 Generating CoreML AI suggestions...")
            print("   Conversation history: \(messages.count) messages")
            print("   User personality: \(userPersonality ?? "none")")
            
            let suggestion = try await coreMLAIService.generateResponseSuggestions(
                conversationHistory: messages,
                userPersonality: userPersonality
            )
            
            print("✅ CoreML AI suggestions generated!")
            print("   Positive: \(suggestion.positiveResponse)")
            print("   Negative: \(suggestion.negativeResponse)")
            
            aiSuggestion = suggestion
            showingAISuggestion = true
            
        } catch {
            print("❌ Error generating CoreML AI suggestions: \(error)")
            errorMessage = "Failed to generate suggestions: \(error.localizedDescription)"
        }
        
        isGeneratingCoreMLAI = false
    }
    
    // MARK: - GIF Generation
    
    func showGIFGenerator() {
        showingGIFGenerator = true
    }
    
    func generateGIF(prompt: String) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Invalid GIF prompt")
            return
        }
        
        isGeneratingGIF = true
        showingGIFGenerator = false
        
        do {
            print("🎬 Generating GIF with prompt: \(prompt)")
            
            // Generate GIF
            let gifURL = try await gifService.generateGIF(prompt: prompt)
            
            print("✅ GIF generated successfully: \(gifURL)")
            
            // Send as message
            try await messageService.sendMessage(
                conversationId: conversation.id,
                content: "🎬 Generated GIF: \(prompt)",
                mediaUrl: gifURL,
                mediaType: "image/gif",
                messageId: nil
            )
            
            print("✅ GIF message sent!")
            
        } catch {
            print("❌ Error generating GIF: \(error)")
            errorMessage = "Failed to generate GIF: \(error.localizedDescription)"
        }
        
        isGeneratingGIF = false
    }
    
    // MARK: - Research
    
    func showResearch() {
        showingResearch = true
    }
    
    func conductResearch(prompt: String) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Invalid research prompt")
            return
        }
        
        isConductingResearch = true
        showingResearch = false
        
        do {
            print("🔍 Conducting research: \(prompt)")
            
            // Conduct research
            let summary = try await researchService.conductResearch(prompt: prompt)
            
            print("✅ Research complete!")
            print("   Summary: \(summary.prefix(100))...")
            
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
            
            print("✅ Research message sent!")
            
        } catch {
            print("❌ Error conducting research: \(error)")
            errorMessage = "Failed to conduct research: \(error.localizedDescription)"
        }
        
        isConductingResearch = false
    }
}


