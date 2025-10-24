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
    var conversationMessages: [Message] = []
    var learningLanguageCode: String? = nil
    var onRetry: ((Message) -> Void)?
    var onAppear: (() -> Void)?
    var onDisappear: (() -> Void)?
    @State private var showingReadReceipts = false
    @State private var isResearchExpanded = false
    @State private var hasInitialized = false
    @State private var showingFullScreenImage = false
    @State private var showingActionsToolbar = false
    @State private var translatedText: String?
    @State private var translationLanguage: String?
    @State private var contextText: String?
    
    var body: some View {
        ZStack {
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
                    VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 0) {
                        // Message content with expand/collapse for research results
                        // Show text content if it exists and is not empty
                        if !message.content.isEmpty {
                            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 8) {
                                // Original message content
                                if let translatedText = translatedText, let translationLanguage = translationLanguage {
                                    // Show original and translation side-by-side
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Original message
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Original")
                                                .font(.caption2)
                                                .foregroundColor(message.isFromCurrentUser ? .white.opacity(0.7) : AppConstants.Colors.textSecondary)
                                            Text(displayedMessageContent)
                                                .foregroundColor(message.isFromCurrentUser ? .white : AppConstants.Colors.textPrimary)
                                        }
                                        
                                        Divider()
                                            .background(message.isFromCurrentUser ? Color.white.opacity(0.3) : AppConstants.Colors.border)
                                        
                                        // Translation
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(translationLanguage)
                                                .font(.caption2)
                                                .foregroundColor(message.isFromCurrentUser ? .white.opacity(0.7) : AppConstants.Colors.textSecondary)
                                            Text(translatedText)
                                                .foregroundColor(message.isFromCurrentUser ? .white : AppConstants.Colors.textPrimary)
                                        }
                                    }
                                } else {
                                    Text(displayedMessageContent)
                                        .foregroundColor(message.isFromCurrentUser ? .white : AppConstants.Colors.textPrimary)
                                }
                            
                                // Show more button for collapsed research results
                                if isResearchResult && !isResearchExpanded {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isResearchExpanded = true
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Text("Show more")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                Image(systemName: "chevron.down")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                
                                // Show context below if available
                                if let contextText = contextText {
                                    Divider()
                                        .background(message.isFromCurrentUser ? Color.white.opacity(0.3) : AppConstants.Colors.border)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Context")
                                            .font(.caption2)
                                            .foregroundColor(message.isFromCurrentUser ? .white.opacity(0.7) : AppConstants.Colors.textSecondary)
                                        Text(contextText)
                                            .foregroundColor(message.isFromCurrentUser ? .white.opacity(0.9) : AppConstants.Colors.textPrimary)
                                            .font(.system(size: 14))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            
                            // Add spacing between text and GIF if both exist
                            if message.mediaUrl != nil {
                                Spacer()
                                    .frame(height: 6)
                            }
                        }
                        
                        // Media content (GIF, images, etc.) - displayed after text
                        if let mediaUrl = message.mediaUrl,
                           let url = URL(string: mediaUrl) {
                            AnimatedImageView(
                                url: url,
                                cornerRadius: hasTextContent ? 8 : AppConstants.Sizes.messageBubbleCornerRadius
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        showingFullScreenImage = true
                                    }
                            )
                        }
                        
                        // Timestamp and status
                        HStack(spacing: 4) {
                            // Timestamp
                            Text(message.timestamp.timeAgoDisplay())
                                .font(.caption2)
                                .foregroundColor(message.isFromCurrentUser ? .white.opacity(0.7) : AppConstants.Colors.textTertiary)
                            
                            // Status indicators (for sent messages)
                            if message.isFromCurrentUser {
                                statusIcon
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .background(bubbleColor)
                    .cornerRadius(AppConstants.Sizes.messageBubbleCornerRadius)
                    .onTapGesture {
                        // Retry sending if message failed
                        if message.status == .failed {
                            onRetry?(message)
                        } else if !message.content.isEmpty {
                            // Show actions toolbar for messages with text content
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingActionsToolbar.toggle()
                            }
                        }
                    }
                    
                    // Actions Toolbar
                    if showingActionsToolbar {
                        MessageActionsToolbar(
                            messageText: message.content,
                            conversationHistory: conversationMessages,
                            learningLanguageCode: learningLanguageCode,
                            onDismiss: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingActionsToolbar = false
                                }
                            },
                            onTranslationComplete: { translatedText, languageName in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.translatedText = translatedText
                                    self.translationLanguage = languageName
                                }
                            },
                            onContextComplete: { contextText in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.contextText = contextText
                                }
                            }
                        )
                        .padding(.top, 8)
                        .transition(.scale(scale: 0.8, anchor: message.isFromCurrentUser ? .topTrailing : .topLeading).combined(with: .opacity))
                    }
                }
                
                if !message.isFromCurrentUser {
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // Initialize expansion state for research results on first appearance
            if !hasInitialized && isResearchResult {
                // Only expand if the message was created within the last 3 seconds
                let messageAge = Date().timeIntervalSince(message.timestamp)
                isResearchExpanded = messageAge < 3.0
                
                hasInitialized = true
            }
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
        .sheet(isPresented: $showingFullScreenImage) {
            if let mediaUrl = message.mediaUrl,
               let url = URL(string: mediaUrl) {
                FullScreenAnimatedImageView(url: url)
            }
        }
    }
    
    // Check if the message is a research result
    private var isResearchResult: Bool {
        message.content.hasPrefix("🔍 Research Results")
    }
    
    // Check if the message has text content
    private var hasTextContent: Bool {
        !message.content.isEmpty
    }
    
    // Get the bubble color based on message type
    private var bubbleColor: Color {
        if isResearchResult {
            return AppConstants.Colors.messageResearch
        } else if message.isFromCurrentUser {
            return AppConstants.Colors.messageOutgoing
        } else {
            return AppConstants.Colors.messageIncoming
        }
    }
    
    // Get the displayed message content (collapsed or full)
    private var displayedMessageContent: String {
        guard isResearchResult && !isResearchExpanded else {
            return message.content
        }
        
        // Show only first 3 lines
        let lines = message.content.components(separatedBy: .newlines)
        if lines.count > 1 {
            return lines.prefix(1).joined(separator: "\n")
        }
        return message.content
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        let iconColor = message.isFromCurrentUser ? Color.white.opacity(0.7) : AppConstants.Colors.textTertiary
        
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(iconColor)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(iconColor)
        case .delivered:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundColor(iconColor)
        case .read:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundColor(message.isFromCurrentUser ? Color.white : AppConstants.Colors.accent)
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
    ScrollView {
        VStack(spacing: 10) {
            // Regular text message (outgoing)
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
            
            // Regular text message (incoming)
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
            
            // GIF-only message (outgoing)
            MessageBubbleView(
                message: Message(
                    conversationId: "1",
                    senderId: "1",
                    content: "",
                    status: .sent,
                    mediaUrl: "https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif",
                    isFromCurrentUser: true
                ),
                conversation: nil
            )
            
            // Text + GIF message (incoming)
            MessageBubbleView(
                message: Message(
                    conversationId: "1",
                    senderId: "2",
                    senderName: "Alice",
                    content: "Check this out! 😄",
                    status: .read,
                    mediaUrl: "https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif",
                    isFromCurrentUser: false
                ),
                conversation: nil
            )
            
            // Research result message
            MessageBubbleView(
                message: Message(
                    conversationId: "1",
                    senderId: "2",
                    senderName: "AI Assistant",
                    content: "🔍 Research Results\n\nHere are the findings from my research:\n\n1. The first key point about the topic\n2. A second important finding\n3. Additional relevant information\n4. More details that extend beyond three lines\n5. Even more comprehensive data",
                    status: .sent,
                    isFromCurrentUser: false
                ),
                conversation: nil
            )
        }
        .padding()
    }
    .background(AppConstants.Colors.background)
}
