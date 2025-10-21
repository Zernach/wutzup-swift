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
    @Published var typingStatus: [String: [String: Bool]] = [:] // conversationId -> [userId: isTyping]

    private let chatService: ChatService
    private let authService: AuthenticationService
    private let userService: UserService?
    private let presenceService: PresenceService?
    private var observationTask: Task<Void, Never>?
    private var typingObservationTasks: [String: Task<Void, Never>] = [:] // conversationId -> Task
    
    // Cache for user data (for showing online status in conversation rows)
    private var userCache: [String: User] = [:]

    init(chatService: ChatService, authService: AuthenticationService, userService: UserService? = nil, presenceService: PresenceService? = nil) {
        self.chatService = chatService
        self.authService = authService
        self.userService = userService
        self.presenceService = presenceService
    }
    
    // Get cached user by ID
    func getUser(byId userId: String) -> User? {
        return userCache[userId]
    }
    
    // Cache a user
    func cacheUser(_ user: User) {
        userCache[user.id] = user
    }
    
    // Cache multiple users
    func cacheUsers(_ users: [User]) {
        for user in users {
            userCache[user.id] = user
        }
    }

    func startObserving() {
        guard let userId = authService.currentUser?.id else {
            print("⚠️ [ChatListViewModel] Cannot start observing - no user ID")
            return
        }

        print("🔥 [ChatListViewModel] Starting conversation observation for user: \(userId)")
        observationTask?.cancel()
        observationTask = Task { @MainActor in
            for await conversation in chatService.observeConversations(userId: userId) {
                print("🔥 [ChatListViewModel] Received conversation update: \(conversation.id)")
                print("🔥 [ChatListViewModel]   lastMessage: \(conversation.lastMessage ?? "nil")")
                print("🔥 [ChatListViewModel]   lastMessageTimestamp: \(conversation.lastMessageTimestamp?.description ?? "nil")")
                upsertConversation(conversation)
                
                // Start observing typing for this conversation if not already observing
                startObservingTyping(for: conversation.id)
            }
        }
    }

    func stopObserving() {
        print("🔥 [ChatListViewModel] Stopping all observations")
        observationTask?.cancel()
        observationTask = nil
        
        // Stop all typing observations
        for task in typingObservationTasks.values {
            task.cancel()
        }
        typingObservationTasks.removeAll()
        typingStatus.removeAll()
    }
    
    private func startObservingTyping(for conversationId: String) {
        // Don't start if already observing
        guard typingObservationTasks[conversationId] == nil else { return }
        guard let presenceService = presenceService else { return }
        
        print("👀 [ChatListViewModel] Starting typing observation for conversation: \(conversationId)")
        
        let task = Task { @MainActor in
            for await typingUsers in presenceService.observeTyping(conversationId: conversationId) {
                print("👀 [ChatListViewModel] Typing update for \(conversationId): \(typingUsers)")
                typingStatus[conversationId] = typingUsers
            }
        }
        
        typingObservationTasks[conversationId] = task
    }
    
    func getTypingIndicatorText(for conversation: Conversation) -> String? {
        guard let typingUsers = typingStatus[conversation.id] else { return nil }
        
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

    func fetchConversations() async {
        guard let userId = authService.currentUser?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            conversations = try await chatService.fetchConversations(userId: userId)
            
            // Fetch and cache user data for all participants
            await fetchAndCacheParticipants()
            
            // Start observing typing for all existing conversations
            for conversation in conversations {
                startObservingTyping(for: conversation.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    // Fetch and cache user data for all conversation participants
    private func fetchAndCacheParticipants() async {
        guard let userService = userService else { return }
        
        // Get all unique participant IDs from conversations (excluding current user)
        let currentUserId = authService.currentUser?.id ?? ""
        var participantIds = Set<String>()
        
        for conversation in conversations {
            for participantId in conversation.participantIds where participantId != currentUserId {
                participantIds.insert(participantId)
            }
        }
        
        // Fetch all users at once
        do {
            let allUsers = try await userService.fetchAllUsers()
            
            // Cache users that are participants
            for user in allUsers where participantIds.contains(user.id) {
                cacheUser(user)
            }
        } catch {
            print("⚠️ Failed to fetch participant user data: \(error)")
        }
    }

    func upsertConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            print("🔄 [ChatListViewModel] Updating existing conversation at index \(index)")
            conversations[index] = conversation
        } else {
            print("➕ [ChatListViewModel] Adding new conversation")
            conversations.append(conversation)
        }

        // Sort by most recent message
        conversations.sort { ($0.lastMessageTimestamp ?? $0.updatedAt) > ($1.lastMessageTimestamp ?? $1.updatedAt) }
        
        print("📋 [ChatListViewModel] Conversations list updated, count: \(conversations.count)")
        
        // Force UI refresh by triggering objectWillChange
        objectWillChange.send()
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
