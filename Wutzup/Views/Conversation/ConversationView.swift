//
//  ConversationView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Combine

struct ConversationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ConversationViewModel
    @State private var scrollProxy: ScrollViewProxy?
    
    init(viewModel: ConversationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message) { failedMessage in
                                Task { @MainActor in
                                    await viewModel.retryMessage(failedMessage)
                                }
                            }
                            .id(message.id)
                        }
                        
                        // Typing Indicator
                        if let typingText = viewModel.typingIndicatorText {
                            HStack {
                                Text(typingText)
                                    .font(.caption)
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                    .italic()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom()
                }
            }
            
            // Message Input
            MessageInputView(
                text: $viewModel.messageText,
                isSending: viewModel.isSending,
                onSend: { content in
                    print("🔵 [ConversationView] Send button tapped")
                    Task { @MainActor in
                        print("🔵 [ConversationView] About to call sendMessage()")
                        await viewModel.sendMessage(content: content)
                        print("🔵 [ConversationView] sendMessage() completed")
                        scrollToBottom()
                    }
                },
                onTextChanged: {
                    viewModel.onTypingChanged()
                }
            )
        }
        .navigationTitle(viewModel.conversation.displayName(currentUserId: appState.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { @MainActor in
                await viewModel.fetchMessages()
                viewModel.startObserving()
            }
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .background(
            AppConstants.Colors.background
                .ignoresSafeArea()
        )
    }
    
    private func scrollToBottom() {
        guard let lastMessage = viewModel.messages.last else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    NavigationStack {
        let previewService = PreviewMessageService()
        let previewPresence = PreviewPresenceService()
        let previewAuth = PreviewAuthenticationService()
        let viewModel = ConversationViewModel(
            conversation: Conversation(
                participantIds: ["1", "2"],
                participantNames: ["1": "Alice", "2": "Bob"]
            ),
            messageService: previewService,
            presenceService: previewPresence,
            authService: previewAuth
        )
        ConversationView(viewModel: viewModel)
            .environmentObject(AppState())
    }
}

private final class PreviewMessageService: MessageService {
    func fetchMessages(conversationId: String, limit: Int) async throws -> [Message] {
        [
            Message(
                id: "msg-1",
                conversationId: conversationId,
                senderId: "1",
                senderName: "Alice",
                content: "Hello!",
                timestamp: Date().addingTimeInterval(-120),
                status: .sent
            ),
            Message(
                id: "msg-2",
                conversationId: conversationId,
                senderId: "2",
                senderName: "Bob",
                content: "Hi there 👋",
                timestamp: Date().addingTimeInterval(-60),
                status: .sent
            )
        ]
    }
    
    func observeMessages(conversationId: String) -> AsyncStream<Message> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?, messageId: String?) async throws -> Message {
        Message(
            id: messageId ?? UUID().uuidString,
            conversationId: conversationId,
            senderId: "1",
            senderName: "Alice",
            content: content,
            timestamp: Date(),
            status: .sent,
            isFromCurrentUser: true
        )
    }
    
    func markAsRead(conversationId: String, messageId: String, userId: String) async throws { }
    
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws { }
}

private final class PreviewPresenceService: PresenceService {
    func setOnline(userId: String) async throws { }
    
    func setOffline(userId: String) async throws { }

    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws { }
    
    func observeTyping(conversationId: String) -> AsyncStream<[String : Bool]> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private final class PreviewAuthenticationService: AuthenticationService {
    var authStatePublisher: AnyPublisher<User?, Never> {
        Just(User(id: "1", email: "alice@wutzup.app", displayName: "Alice")).eraseToAnyPublisher()
    }
    
    var currentUser: User? {
        User(id: "1", email: "alice@wutzup.app", displayName: "Alice")
    }
    
    func register(email: String, password: String, displayName: String) async throws -> User {
        currentUser!
    }
    
    func login(email: String, password: String) async throws -> User {
        currentUser!
    }
    
    func logout() async throws { }
    
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws { }
    
    func deleteAccount() async throws { }
}
