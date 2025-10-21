//
//  MessageBubbleView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let conversation: Conversation?
    var onRetry: ((Message) -> Void)?
    var onAppear: (() -> Void)?
    var onDisappear: (() -> Void)?
    @State private var showingReadReceipts = false
    
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
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                
                // Message bubble
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        // Timestamp
                        Text(message.timestamp.timeAgoDisplay())
                            .font(.caption2)
                            .foregroundColor(AppConstants.Colors.textTertiary)
                        
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
                        ? AppConstants.Colors.messageOutgoing
                        : AppConstants.Colors.messageIncoming
                )
                .cornerRadius(AppConstants.Sizes.messageBubbleCornerRadius)
                .onTapGesture {
                    // Retry sending if message failed
                    if message.status == .failed {
                        onRetry?(message)
                    }
                }
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .onAppear {
            onAppear?()
        }
        .onDisappear {
            onDisappear?()
        }
        .onLongPressGesture {
            // Only show details for group chats and sent messages
            if let conversation = conversation,
               conversation.isGroup && message.isFromCurrentUser {
                showingReadReceipts = true
            }
        }
        .sheet(isPresented: $showingReadReceipts) {
            if let conversation = conversation {
                ReadReceiptDetailView(message: message, conversation: conversation)
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(AppConstants.Colors.textTertiary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(AppConstants.Colors.textTertiary)
        case .delivered:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundColor(AppConstants.Colors.textTertiary)
        case .read:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundColor(AppConstants.Colors.accent)
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundColor(AppConstants.Colors.destructive)
                Text("Tap to retry")
                    .font(.caption2)
                    .foregroundColor(AppConstants.Colors.destructive)
            }
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        MessageBubbleView(
            message: Message(
                conversationId: "1",
                senderId: "1",
                content: "Hey, how are you?",
                status: .sent,
                isFromCurrentUser: true
            ),
            conversation: nil
        )
        
        MessageBubbleView(
            message: Message(
                conversationId: "1",
                senderId: "2",
                senderName: "Alice",
                content: "I'm good! How about you?",
                status: .read,
                isFromCurrentUser: false
            ),
            conversation: nil
        )
    }
    .padding()
}
