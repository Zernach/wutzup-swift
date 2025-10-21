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
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Image(systemName: conversation.isGroup ? "person.3.fill" : "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(conversation.isGroup ? AppConstants.Colors.accent : AppConstants.Colors.mutedIcon)
            
            VStack(alignment: .leading, spacing: 4) {
                // Conversation Name
                Text(conversation.displayName(currentUserId: currentUserId))
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                // Last Message
                if let lastMessage = conversation.lastMessage {
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
}

#Preview {
    List {
        ConversationRowView(
            conversation: Conversation(
                participantIds: ["1", "2"],
                participantNames: ["1": "Alice", "2": "Bob"],
                lastMessage: "Hey, how are you?",
                lastMessageTimestamp: Date()
            ),
            currentUserId: "1"
        )
    }
}
