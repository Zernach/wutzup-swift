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
        // DEBUG: Print received parameters
        print("🔍 [DEBUG] createDirectConversation called with separate parameters")
        print("🔍 [DEBUG] otherUserId parameter:", otherUserId)
        print("🔍 [DEBUG] otherDisplayName parameter:", otherDisplayName)
        print("🔍 [DEBUG] otherEmail parameter:", otherEmail)

        // Early validation of otherUserId
        guard !otherUserId.isEmpty else {
            print("❌ [ERROR] otherUserId is EMPTY")
            errorMessage = "Unable to start chat. The selected user has an invalid ID."
            return nil
        }

        print("🔍 [DEBUG] currentUser provided:", currentUser != nil)

        // Step 1: Resolve current user
        var resolvedUser: User?
        if let providedUser = currentUser {
            resolvedUser = providedUser
            let providedId = providedUser.id
            print("🔍 [DEBUG] Using provided currentUser:", providedId)
        } else {
            resolvedUser = authService.currentUser
            if let authUser = authService.currentUser {
                let authId = authUser.id
                print("🔍 [DEBUG] Using authService.currentUser:", authId)
            } else {
                print("❌ [ERROR] authService.currentUser is nil")
            }
        }

        guard let activeUser = resolvedUser else {
            print("❌ [ERROR] No active user found")
            errorMessage = "Unable to start chat. Current user not found."
            return nil
        }

        // Extract current user info
        let currentUserId = activeUser.id
        let currentDisplayName = activeUser.displayName

        print("✅ [DEBUG] Active user resolved:", currentUserId)
        print("🔍 [DEBUG] currentUserId:", currentUserId)
        print("🔍 [DEBUG] otherUserId:", otherUserId)

        // Step 3: Validate current user ID
        guard !currentUserId.isEmpty else {
            print("❌ [ERROR] currentUserId is empty")
            errorMessage = "Unable to start chat. Missing current user identifier."
            return nil
        }

        // Step 4: Check for self-chat
        guard otherUserId != currentUserId else {
            print("❌ [ERROR] Attempting to chat with self")
            print("❌ [ERROR] otherUserId:", otherUserId)
            print("❌ [ERROR] currentUserId:", currentUserId)
            errorMessage = "You can't start a chat with yourself."
            return nil
        }

        print("✅ [DEBUG] User validation passed")
        print("🔍 [DEBUG] currentDisplayName:", currentDisplayName)
        print("🔍 [DEBUG] otherDisplayName:", otherDisplayName)

        // Step 6: Create conversation
        do {
            print("🔍 [DEBUG] Calling chatService.fetchOrCreateDirectConversation...")
            let conversation = try await chatService.fetchOrCreateDirectConversation(
                userId: currentUserId,
                otherUserId: otherUserId,
                participantNames: [
                    currentUserId: currentDisplayName,
                    otherUserId: otherDisplayName
                ]
            )

            let convId = conversation.id
            print("✅ [DEBUG] Conversation fetched/created:", convId)

            // Step 7: Ensure participant names are set
            var updatedConversation = conversation
            var needsUpdate = false

            if updatedConversation.participantNames[currentUserId] == nil {
                print("🔍 [DEBUG] Adding missing currentUser name to conversation")
                updatedConversation.participantNames[currentUserId] = currentDisplayName
                needsUpdate = true
            }

            if updatedConversation.participantNames[otherUserId] == nil {
                print("🔍 [DEBUG] Adding missing otherUser name to conversation")
                updatedConversation.participantNames[otherUserId] = otherDisplayName
                needsUpdate = true
            }

            if needsUpdate {
                print("🔍 [DEBUG] Updating conversation with participant names...")
                try? await chatService.updateConversation(updatedConversation)
                print("✅ [DEBUG] Conversation updated successfully")
                return updatedConversation
            }

            print("✅ [DEBUG] Returning conversation (no update needed)")
            return conversation
        } catch let convError {
            let errorDesc = convError.localizedDescription
            print("❌ [ERROR] Failed to create conversation:", errorDesc)
            errorMessage = errorDesc
            return nil
        }
    }

    func createGroupConversation(with users: [User], groupName: String, currentUser: User?) async -> Conversation? {
        var participants = Set(users.map { $0.id })
        var participantNames = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.displayName) })

        if let currentUser = currentUser ?? authService.currentUser {
            participants.insert(currentUser.id)
            participantNames[currentUser.id] = currentUser.displayName
        }

        do {
            let participantIds = Array(participants).sorted()
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
