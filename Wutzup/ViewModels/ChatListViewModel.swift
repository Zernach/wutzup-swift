//
//  ChatListViewModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let chatService: ChatService
    private let authService: AuthenticationService
    private var observationTask: Task<Void, Never>?
    
    init(chatService: ChatService, authService: AuthenticationService) {
        self.chatService = chatService
        self.authService = authService
    }
    
    func startObserving() {
        guard let userId = authService.currentUser?.id else { return }
        
        observationTask?.cancel()
        observationTask = Task {
            for await conversation in chatService.observeConversations(userId: userId) {
                if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                    conversations[index] = conversation
                } else {
                    conversations.append(conversation)
                }
                
                // Sort by last message timestamp
                conversations.sort { ($0.lastMessageTimestamp ?? $0.updatedAt) > ($1.lastMessageTimestamp ?? $1.updatedAt) }
            }
        }
    }
    
    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    func fetchConversations() async {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            conversations = try await chatService.fetchConversations(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createDirectConversation(with userId: String) async -> Conversation? {
        guard let currentUserId = authService.currentUser?.id else { return nil }
        
        do {
            return try await chatService.fetchOrCreateDirectConversation(
                userId: currentUserId,
                otherUserId: userId
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

