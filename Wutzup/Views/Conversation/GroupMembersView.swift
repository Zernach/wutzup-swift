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
    
    @State private var members: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
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
        presenceService: PreviewPresenceService()
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
    
    func fetchUser(userId: String) async throws -> User {
        let users = try await fetchAllUsers()
        guard let user = users.first(where: { $0.id == userId }) else {
            throw NSError(domain: "PreviewUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    func updatePersonality(userId: String, personality: String?) async throws { }
    
    func updateProfileImageUrl(userId: String, imageUrl: String?) async throws { }
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

