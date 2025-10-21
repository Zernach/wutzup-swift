//
//  ConversationRowView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation
    let currentUserId: String
    let otherUser: User? // For 1-on-1 chats, pass the other user to show their online status
    let presenceService: PresenceService?
    let typingIndicatorText: String? // Pass from ChatListViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if conversation.isGroup {
                // Group chat icon (no online status)
                ZStack {
                    Circle()
                        .fill(AppConstants.Colors.accent.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.3.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(AppConstants.Colors.accent)
                }
            } else {
                // 1-on-1 chat - use UserProfileImageView with online status
                UserProfileImageView(
                    user: otherUser ?? placeholderUser,
                    size: 50,
                    showOnlineStatus: otherUser != nil,
                    presenceService: presenceService
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Conversation Name
                Text(conversation.displayName(currentUserId: currentUserId))
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                // Draft indicator, Typing indicator, or Last Message
                if let typingText = typingIndicatorText {
                    // Show typing indicator with highest priority
                    HStack(spacing: 4) {
                        Text(typingText)
                            .font(.subheadline)
                            .foregroundColor(AppConstants.Colors.accent)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                } else if hasDraft {
                    HStack(spacing: 4) {
                        Text("Draft:")
                            .font(.subheadline)
                            .foregroundColor(AppConstants.Colors.error)
                            .fontWeight(.medium)
                        Text(draftPreview)
                            .font(.subheadline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                            .lineLimit(1)
                    }
                } else if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Timestamp
                if let timestamp = conversation.lastMessageTimestamp {
                    Text(timestamp.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                
                // Unread Badge
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .padding(6)
                        .background(AppConstants.Colors.accent)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Create a placeholder user from conversation data if no user object is provided
    private var placeholderUser: User {
        let otherParticipantId = conversation.participantIds.first { $0 != currentUserId } ?? ""
        let displayName = conversation.participantNames[otherParticipantId] ?? "Unknown User"
        
        return User(
            id: otherParticipantId,
            email: "",
            displayName: displayName
        )
    }
    
    // Check if this conversation has a draft message
    private var hasDraft: Bool {
        DraftManager.shared.loadDraft(for: conversation.id) != nil
    }
    
    // Preview of draft message (first 50 characters)
    private var draftPreview: String {
        guard let draft = DraftManager.shared.loadDraft(for: conversation.id) else {
            return ""
        }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 50 ? String(trimmed.prefix(50)) + "..." : trimmed
    }
}

#Preview("Direct Chat - Online") {
    List {
        ConversationRowView(
            conversation: Conversation(
                participantIds: ["1", "2"],
                participantNames: ["1": "Me", "2": "Alice Johnson"],
                lastMessage: "Hey, how are you?",
                lastMessageTimestamp: Date()
            ),
            currentUserId: "1",
            otherUser: User(
                id: "2",
                email: "alice@test.com",
                displayName: "Alice Johnson"
            ),
            presenceService: PreviewPresenceService(isOnline: true),
            typingIndicatorText: nil
        )
    }
    .background(AppConstants.Colors.background)
}

#Preview("Direct Chat - Offline") {
    List {
        ConversationRowView(
            conversation: Conversation(
                participantIds: ["1", "3"],
                participantNames: ["1": "Me", "3": "Bob Smith"],
                lastMessage: "Talk to you later!",
                lastMessageTimestamp: Date().addingTimeInterval(-3600)
            ),
            currentUserId: "1",
            otherUser: User(
                id: "3",
                email: "bob@test.com",
                displayName: "Bob Smith"
            ),
            presenceService: PreviewPresenceService(isOnline: false),
            typingIndicatorText: nil
        )
    }
    .background(AppConstants.Colors.background)
}

#Preview("Group Chat") {
    List {
        ConversationRowView(
            conversation: Conversation(
                participantIds: ["1", "2", "3", "4"],
                participantNames: ["1": "Me", "2": "Alice", "3": "Bob", "4": "Charlie"],
                isGroup: true,
                groupName: "Team Chat",
                lastMessage: "Alice: Great idea!",
                lastMessageTimestamp: Date().addingTimeInterval(-300)
            ),
            currentUserId: "1",
            otherUser: nil,
            presenceService: nil,
            typingIndicatorText: nil
        )
    }
    .background(AppConstants.Colors.background)
}

#Preview("Typing Indicator") {
    List {
        ConversationRowView(
            conversation: Conversation(
                participantIds: ["1", "2"],
                participantNames: ["1": "Me", "2": "Alice Johnson"],
                lastMessage: "Hey, how are you?",
                lastMessageTimestamp: Date()
            ),
            currentUserId: "1",
            otherUser: User(
                id: "2",
                email: "alice@test.com",
                displayName: "Alice Johnson"
            ),
            presenceService: PreviewPresenceService(isOnline: true),
            typingIndicatorText: "Alice Johnson is typing..."
        )
    }
    .background(AppConstants.Colors.background)
}

// MARK: - Preview Helpers

private class PreviewPresenceService: PresenceService {
    let isOnline: Bool
    
    init(isOnline: Bool) {
        self.isOnline = isOnline
    }
    
    func setOnline(userId: String) async throws { }
    func setOffline(userId: String) async throws { }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
            let presence = Presence(
                userId: userId,
                status: isOnline ? .online : .offline,
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
