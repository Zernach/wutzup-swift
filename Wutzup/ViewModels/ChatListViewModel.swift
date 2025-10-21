//
//  ChatListViewModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI
import Combine

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
                upsertConversation(conversation)
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

    func upsertConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }

        conversations.sort { ($0.lastMessageTimestamp ?? $0.updatedAt) > ($1.lastMessageTimestamp ?? $1.updatedAt) }
    }

    func createDirectConversation(with otherUserId: String, otherDisplayName: String, otherEmail: String, currentUser: User?) async -> Conversation? {
        // Early validation of otherUserId
        guard !otherUserId.isEmpty else {
            errorMessage = "Unable to start chat. The selected user has an invalid ID."
            return nil
        }

        // Step 1: Resolve current user
        var resolvedUser: User?
        if let providedUser = currentUser {
            resolvedUser = providedUser
        } else {
            resolvedUser = authService.currentUser
        }

        guard let activeUser = resolvedUser else {
            errorMessage = "Unable to start chat. Current user not found."
            return nil
        }

        // Extract current user info
        let currentUserId = activeUser.id
        let currentDisplayName = activeUser.displayName

        // Step 3: Validate current user ID
        guard !currentUserId.isEmpty else {
            errorMessage = "Unable to start chat. Missing current user identifier."
            return nil
        }

        // Step 4: Check for self-chat
        guard otherUserId != currentUserId else {
            errorMessage = "You can't start a chat with yourself."
            return nil
        }

        // Step 6: Create conversation
        do {
            let conversation = try await chatService.fetchOrCreateDirectConversation(
                userId: currentUserId,
                otherUserId: otherUserId,
                participantNames: [
                    currentUserId: currentDisplayName,
                    otherUserId: otherDisplayName
                ]
            )

            // Step 7: Ensure participant names are set
            var updatedConversation = conversation
            var needsUpdate = false

            if updatedConversation.participantNames[currentUserId] == nil {
                updatedConversation.participantNames[currentUserId] = currentDisplayName
                needsUpdate = true
            }

            if updatedConversation.participantNames[otherUserId] == nil {
                updatedConversation.participantNames[otherUserId] = otherDisplayName
                needsUpdate = true
            }

            if needsUpdate {
                try? await chatService.updateConversation(updatedConversation)
                return updatedConversation
            }

            return conversation
        } catch let convError {
            let errorDesc = convError.localizedDescription
            errorMessage = errorDesc
            return nil
        }
    }

    func createGroupConversation(with users: [User], groupName: String, currentUser: User?) async -> Conversation? {
        // Validate that we have at least 2 other users (+ current user = 3 minimum for group)
        guard users.count >= 2 else {
            errorMessage = "Please select at least 2 people to create a group chat."
            return nil
        }
        
        var participants = Set(users.map { $0.id })
        var participantNames = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.displayName) })

        if let currentUser = currentUser ?? authService.currentUser {
            participants.insert(currentUser.id)
            participantNames[currentUser.id] = currentUser.displayName
        }

        let participantIds = Array(participants).sorted()
        
        // Final safety check - must have at least 2 participants total for Firestore rules
        guard participantIds.count >= 2 else {
            errorMessage = "A conversation must have at least 2 participants."
            return nil
        }
        
        print("🔍 Creating group with \(participantIds.count) participants: \(participantIds)")
        
        do {
            return try await chatService.createConversation(
                withUserIds: participantIds,
                isGroup: true,
                groupName: groupName,
                participantNames: participantNames
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
