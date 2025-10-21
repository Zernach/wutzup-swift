//
//  MessageBubbleView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (for group chats or other users)
                if !message.isFromCurrentUser, let senderName = message.senderName {
                    Text(senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Message bubble
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    
                    HStack(spacing: 4) {
                        // Timestamp
                        Text(message.timestamp.timeAgoDisplay())
                            .font(.caption2)
                            .foregroundColor(message.isFromCurrentUser ? .white.opacity(0.8) : .secondary)
                        
                        // Status indicators (for sent messages)
                        if message.isFromCurrentUser {
                            statusIcon
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    message.isFromCurrentUser
                        ? Color.blue
                        : Color(UIColor.systemGray5)
                )
                .cornerRadius(AppConstants.Sizes.messageBubbleCornerRadius)
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        case .delivered:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundColor(.white.opacity(0.8))
        case .read:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundColor(.blue.opacity(0.8))
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        MessageBubbleView(message: Message(
            conversationId: "1",
            senderId: "1",
            content: "Hey, how are you?",
            status: .sent,
            isFromCurrentUser: true
        ))
        
        MessageBubbleView(message: Message(
            conversationId: "1",
            senderId: "2",
            senderName: "Alice",
            content: "I'm good! How about you?",
            status: .read,
            isFromCurrentUser: false
        ))
    }
    .padding()
}

