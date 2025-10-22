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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // Glass morphism background
    private var glassBackground: some View {
        ZStack {
            // Base semi-transparent layer
            Color.white.opacity(0.08)
            
            // Gradient overlay for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .background(.ultraThinMaterial)
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
    VStack(spacing: 12) {
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
        .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppConstants.Colors.background)
}

#Preview("Direct Chat - Offline") {
    VStack(spacing: 12) {
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
        .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppConstants.Colors.background)
}

#Preview("Group Chat") {
    VStack(spacing: 12) {
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
        .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppConstants.Colors.background)
}

#Preview("Typing Indicator") {
    VStack(spacing: 12) {
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
        .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppConstants.Colors.background)
}

#Preview("Multiple Rows - Glass Effect") {
    ScrollView {
        VStack(spacing: 12) {
            ConversationRowView(
                conversation: Conversation(
                    participantIds: ["1", "2"],
                    participantNames: ["1": "Me", "2": "Alice Johnson"],
                    lastMessage: "Hey, how are you?",
                    lastMessageTimestamp: Date(),
                    unreadCount: 3
                ),
                currentUserId: "1",
                otherUser: User(id: "2", email: "alice@test.com", displayName: "Alice Johnson"),
                presenceService: PreviewPresenceService(isOnline: true),
                typingIndicatorText: nil
            )
            
            ConversationRowView(
                conversation: Conversation(
                    participantIds: ["1", "3"],
                    participantNames: ["1": "Me", "3": "Bob Smith"],
                    lastMessage: "Talk to you later!",
                    lastMessageTimestamp: Date().addingTimeInterval(-3600),
                    unreadCount: 0
                ),
                currentUserId: "1",
                otherUser: User(id: "3", email: "bob@test.com", displayName: "Bob Smith"),
                presenceService: PreviewPresenceService(isOnline: false),
                typingIndicatorText: nil
            )
            
            ConversationRowView(
                conversation: Conversation(
                    participantIds: ["1", "2", "3", "4"],
                    participantNames: ["1": "Me", "2": "Alice", "3": "Bob", "4": "Charlie"],
                    isGroup: true,
                    groupName: "Team Chat",
                    lastMessage: "Alice: Great idea!",
                    lastMessageTimestamp: Date().addingTimeInterval(-300),
                    unreadCount: 1
                ),
                currentUserId: "1",
                otherUser: nil,
                presenceService: nil,
                typingIndicatorText: nil
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
