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
        // Observe messages
        messageObservationTask?.cancel()
        messageObservationTask = Task {
            for await message in messageService.observeMessages(conversationId: conversation.id) {
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index] = message
                } else {
                    messages.append(message)
                }
                
                // Sort by timestamp
                messages.sort { $0.timestamp < $1.timestamp }
                
                // Mark as read if not from current user
                if !message.isFromCurrentUser, let userId = authService.currentUser?.id {
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
    
    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText
        messageText = ""
        
        isSending = true
        
        // Stop typing indicator
        if let userId = authService.currentUser?.id {
            try? await presenceService.setTyping(
                userId: userId,
                conversationId: conversation.id,
                isTyping: false
            )
        }
        
        do {
            let message = try await messageService.sendMessage(
                conversationId: conversation.id,
                content: content,
                mediaUrl: nil,
                mediaType: nil
            )
            
            // Optimistically add message
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        } catch {
            errorMessage = error.localizedDescription
            messageText = content // Restore text on error
        }
        
        isSending = false
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

