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
    @State private var showingGroupMembers = false
    @Environment(\.scenePhase) private var scenePhase
    
    let userService: UserService
    
    init(viewModel: ConversationViewModel, userService: UserService) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                conversation: viewModel.conversation,
                                onRetry: { failedMessage in
                                    Task { @MainActor in
                                        await viewModel.retryMessage(failedMessage)
                                    }
                                },
                                onAppear: {
                                    viewModel.markMessageVisible(message.id)
                                },
                                onDisappear: {
                                    viewModel.markMessageInvisible(message.id)
                                }
                            )
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
        .toolbar {
            if viewModel.conversation.isGroup || viewModel.conversation.participantIds.count > 2 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGroupMembers = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingGroupMembers) {
            GroupMembersView(
                conversation: viewModel.conversation,
                userService: userService
            )
        }
        .onAppear {
            // Load any saved draft for this conversation
            viewModel.loadDraft()
            
            Task { @MainActor in
                await viewModel.fetchMessages()
                viewModel.startObserving()
            }
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Mark messages as delivered when app becomes active/foreground
                Task {
                    await viewModel.markUndeliveredMessagesAsDelivered()
                }
            }
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
        let previewUser = PreviewUserServiceForConversation()
        let viewModel = ConversationViewModel(
            conversation: Conversation(
                participantIds: ["1", "2", "3"],
                participantNames: ["1": "Alice", "2": "Bob", "3": "Charlie"],
                isGroup: true,
                groupName: "Team Chat"
            ),
            messageService: previewService,
            presenceService: previewPresence,
            authService: previewAuth
        )
        ConversationView(viewModel: viewModel, userService: previewUser)
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
    
    func batchMarkAsRead(conversationId: String, messageIds: [String], userId: String) async throws { }
    
    func batchMarkAsDelivered(conversationId: String, messageIds: [String], userId: String) async throws { }
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
    
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
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

private final class PreviewUserServiceForConversation: UserService {
    func fetchAllUsers() async throws -> [User] {
        [
            User(id: "1", email: "alice@wutzup.app", displayName: "Alice"),
            User(id: "2", email: "bob@wutzup.app", displayName: "Bob"),
            User(id: "3", email: "charlie@wutzup.app", displayName: "Charlie")
        ]
    }
}
