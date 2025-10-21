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
    
    let conversation: Conversation
    private let messageService: MessageService
    private let presenceService: PresenceService
    private let authService: AuthenticationService
    
    private var messageObservationTask: Task<Void, Never>?
    private var typingObservationTask: Task<Void, Never>?
    private var typingTimer: Timer?
    
    init(conversation: Conversation, messageService: MessageService, presenceService: PresenceService, authService: AuthenticationService) {
        self.conversation = conversation
        self.messageService = messageService
        self.presenceService = presenceService
        self.authService = authService
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
                
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    print("🟢 [ConversationViewModel]   Updating existing message at index \(index)")
                    messages[index] = message
                } else {
                    print("🟢 [ConversationViewModel]   Adding new message to array")
                    messages.append(message)
                }
                
                // Sort by timestamp
                messages.sort { $0.timestamp < $1.timestamp }
                print("🟢 [ConversationViewModel]   Total messages: \(messages.count)")
                
                // Handle status updates for received messages
                if !message.isFromCurrentUser, let userId = authService.currentUser?.id {
                    // Mark as delivered if not already
                    if !message.deliveredTo.contains(userId) {
                        print("🟢 [ConversationViewModel]   Marking message as delivered")
                        Task {
                            try? await messageService.markAsDelivered(
                                conversationId: conversation.id,
                                messageId: message.id,
                                userId: userId
                            )
                        }
                    }
                    
                    // Mark as read (happens automatically when user views it)
                    if !message.readBy.contains(userId) {
                        print("🟢 [ConversationViewModel]   Marking message as read")
                        Task {
                            try? await messageService.markAsRead(
                                conversationId: conversation.id,
                                messageId: message.id,
                                userId: userId
                            )
                        }
                    }
                }
            }
            print("🟢 [ConversationViewModel] Message observation Task ended")
        }
        
        // Observe typing indicators
        typingObservationTask?.cancel()
        typingObservationTask = Task {
            for await typing in presenceService.observeTyping(conversationId: conversation.id) {
                typingUsers = typing
            }
        }
    }
    
    func stopObserving() {
        messageObservationTask?.cancel()
        messageObservationTask = nil
        typingObservationTask?.cancel()
        typingObservationTask = nil
        
        // Stop typing indicator on leave
        if let userId = authService.currentUser?.id {
            Task {
                try? await presenceService.setTyping(
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
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func sendMessage(content: String) async {
        print("🟢 [ConversationViewModel] sendMessage() - ENTRY")
        print("🟢 [ConversationViewModel] content: '\(content)'")
        print("🟢 [ConversationViewModel] conversationId: \(conversation.id)")
        
        print("🟢 [ConversationViewModel] Setting isSending = true")
        isSending = true
        
        // Stop typing indicator
        if let userId = authService.currentUser?.id {
            print("🟢 [ConversationViewModel] Stopping typing indicator for user: \(userId)")
            try? await presenceService.setTyping(
                userId: userId,
                conversationId: conversation.id,
                isTyping: false
            )
            print("🟢 [ConversationViewModel] Typing indicator stopped")
        }
        
        print("🟢 [ConversationViewModel] Calling messageService.sendMessage()")
        do {
            let message = try await messageService.sendMessage(
                conversationId: conversation.id,
                content: content,
                mediaUrl: nil,
                mediaType: nil
            )
            
            print("✅ [ConversationViewModel] Message sent successfully!")
            print("✅ [ConversationViewModel]   messageId: \(message.id)")
            print("✅ [ConversationViewModel]   status: \(message.status)")
            
            // Optimistically add message
            if !messages.contains(where: { $0.id == message.id }) {
                print("🟢 [ConversationViewModel] Adding message to local array")
                messages.append(message)
            } else {
                print("⚠️ [ConversationViewModel] Message already exists in local array")
            }
        } catch {
            print("❌ [ConversationViewModel] ERROR sending message: \(error)")
            print("❌ [ConversationViewModel] Error type: \(type(of: error))")
            print("❌ [ConversationViewModel] Error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            messageText = content // Restore text on error
        }
        
        print("🟢 [ConversationViewModel] Setting isSending = false")
        isSending = false
        print("🟢 [ConversationViewModel] sendMessage() - EXIT")
    }
    
    func onTypingChanged() {
        guard let userId = authService.currentUser?.id else { return }
        
        // Cancel previous timer
        typingTimer?.invalidate()
        
        // Set typing indicator
        Task {
            try? await presenceService.setTyping(
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
                    try? await self.presenceService.setTyping(
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
}

