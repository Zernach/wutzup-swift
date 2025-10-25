//
//  GroupMembersView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct GroupMembersView: View {
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    let userService: UserService
    let presenceService: PresenceService
    let chatService: ChatService
    
    @State private var members: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddMembers = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading members...")
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error Loading Members")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 0) {
                        List {
                            Section {
                                ForEach(members) { member in
                                    HStack(spacing: 12) {
                                        // Profile Image with online status
                                        UserProfileImageView(
                                            user: member,
                                            size: 44,
                                            showOnlineStatus: true,
                                            presenceService: presenceService
                                        )
                                        
                                        // Member Info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(member.displayName)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            
                                            Text(member.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                Text("\(members.count) Members")
                            }
                        }
                        .listStyle(.plain)
                        
                        // Add Members Button
                        if conversation.isGroup {
                            VStack(spacing: 0) {
                                Divider()
                                    .background(AppConstants.Colors.border)
                                
                                Button {
                                    showingAddMembers = true
                                } label: {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(AppConstants.Colors.accent)
                                        
                                        Text("Add Members")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppConstants.Colors.accent)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppConstants.Colors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(AppConstants.Colors.border, lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle(conversation.isGroup ? (conversation.groupName ?? "Group Members") : "Chat Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadMembers()
            }
            .sheet(isPresented: $showingAddMembers) {
                AddMembersView(
                    conversation: conversation,
                    userService: userService,
                    chatService: chatService,
                    onMembersAdded: { newMembers in
                        // Refresh the members list
                        Task {
                            await loadMembers()
                        }
                    }
                )
            }
        }
    }
    
    @MainActor
    private func loadMembers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all users
            let allUsers = try await userService.fetchAllUsers()
            
            // Filter to only participants in this conversation
            members = allUsers.filter { user in
                conversation.participantIds.contains(user.id)
            }
            
            // Sort by display name
            members.sort { $0.displayName.lowercased() < $1.displayName.lowercased() }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    let previewConversation = Conversation(
        participantIds: ["user1", "user2", "user3"],
        participantNames: [
            "user1": "Alice Johnson",
            "user2": "Bob Smith",
            "user3": "Charlie Davis"
        ],
        isGroup: true,
        groupName: "Work Team"
    )
    
    GroupMembersView(
        conversation: previewConversation,
        userService: PreviewUserService(),
        presenceService: PreviewPresenceService(),
        chatService: PreviewChatService()
    )
}

// Preview-only service
private final class PreviewUserService: UserService {
    func fetchAllUsers() async throws -> [User] {
        [
            User(
                id: "user1",
                email: "alice@example.com",
                displayName: "Alice Johnson",
                profileImageUrl: nil
            ),
            User(
                id: "user2",
                email: "bob@example.com",
                displayName: "Bob Smith",
                profileImageUrl: nil
            ),
            User(
                id: "user3",
                email: "charlie@example.com",
                displayName: "Charlie Davis",
                profileImageUrl: nil
            )
        ]
    }
    
    func fetchUsers(isTutor: Bool?) async throws -> [User] {
        let allUsers = try await fetchAllUsers()
        guard let isTutor = isTutor else {
            return allUsers
        }
        // For preview purposes, just return all users regardless of tutor status
        return allUsers
    }
    
    func fetchUser(userId: String) async throws -> User {
        let users = try await fetchAllUsers()
        guard let user = users.first(where: { $0.id == userId }) else {
            throw NSError(domain: "PreviewUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    func updatePersonality(userId: String, personality: String?) async throws { }
    
    func updateProfileImageUrl(userId: String, imageUrl: String?) async throws { }
    
    func updateLanguages(userId: String, primaryLanguageCode: String?, learningLanguageCode: String?) async throws { }
}

private final class PreviewPresenceService: PresenceService {
    func setOnline(userId: String) async throws { }
    
    func setOffline(userId: String) async throws { }
    
    func setAway(userId: String) async throws { }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
            let presence = Presence(
                userId: userId,
                status: userId == "user1" ? .online : .offline, // Make Alice online for variety
                lastSeen: Date(),
                typing: [:]
            )
            continuation.yield(presence)
            continuation.finish()
        }
    }
    
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws { }
    
    func observeTyping(conversationId: String) -> AsyncStream<[String: Bool]> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private final class PreviewChatService: ChatService {
    func createConversation(withUserIds userIds: [String], isGroup: Bool, groupName: String?, participantNames: [String: String]) async throws -> Conversation {
        return Conversation(
            participantIds: userIds,
            participantNames: participantNames,
            isGroup: isGroup,
            groupName: groupName
        )
    }
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        return []
    }
    
    func observeConversations(userId: String) -> AsyncStream<Conversation> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    func fetchOrCreateDirectConversation(userId: String, otherUserId: String, participantNames: [String: String]) async throws -> Conversation {
        return Conversation(
            participantIds: [userId, otherUserId],
            participantNames: participantNames,
            isGroup: false
        )
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        // Preview implementation - no-op
    }
}

