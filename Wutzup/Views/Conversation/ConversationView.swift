//
//  ConversationView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData
import Combine

struct ConversationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ConversationViewModel
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingGroupMembers = false
    @State private var showingAIMenu = false
    @State private var inputFooterHeight: CGFloat = 60 // Default height estimate
    @Environment(\.scenePhase) private var scenePhase
    
    let userService: UserService
    
    init(viewModel: ConversationViewModel, userService: UserService) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Connection Status Banner
                ConnectionStatusView()
                
                // Messages List
                ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                conversation: viewModel.conversation,
                                conversationMessages: viewModel.messages,
                                learningLanguageCode: appState.currentUser?.learningLanguageCode,
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
                        
                        // Bottom spacer to prevent black space when content shrinks
                        Color.clear
                            .frame(height: 1)
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.interactively)
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
                        Task { @MainActor in
                            await viewModel.sendMessage(content: content)
                            scrollToBottom()
                        }
                    },
                    onTextChanged: {
                        viewModel.onTypingChanged()
                    }
                )
            }
            .onPreferenceChange(MessageInputHeightKey.self) { height in
                withAnimation(.easeInOut(duration: 0.2)) {
                    inputFooterHeight = height
                }
            }
            
            // Floating AI Menu
            VStack {
                Spacer()
                HStack {
                    AIMenuView(
                        isExpanded: $showingAIMenu,
                        isGeneratingAI: viewModel.isGeneratingAI,
                        onThoughtfulReplies: {
                            Task { @MainActor in
                                await viewModel.generateAIResponseSuggestions()
                            }
                        },
                        onConductResearch: {
                            viewModel.showResearch()
                        },
                        onGenerateGIF: {
                            viewModel.showGIFGenerator()
                        }
                    )
                    .padding(.leading, 16)
                    .padding(.bottom, max(inputFooterHeight + 16, 76))
                    .animation(.easeInOut(duration: 0.2), value: inputFooterHeight)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle(viewModel.conversation.displayName(currentUserId: appState.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingGroupMembers = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingGroupMembers) {
            GroupMembersView(
                conversation: viewModel.conversation,
                userService: userService,
                presenceService: viewModel.presenceService
            )
        }
        .sheet(isPresented: $viewModel.showingAISuggestion) {
            ResponseSuggestionView(
                suggestion: viewModel.aiSuggestion,
                isLoading: viewModel.isGeneratingAI,
                onSelect: { response in
                    viewModel.selectAISuggestion(response)
                },
                onDismiss: {
                    viewModel.dismissAISuggestion()
                }
            )
        }
        .sheet(isPresented: $viewModel.showingGIFGenerator) {
            GIFGeneratorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingResearch) {
            ResearchView { prompt in
                await viewModel.conductResearch(prompt: prompt)
            }
        }
        .overlay(
            Group {
                if viewModel.isConductingResearch {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppConstants.Colors.accent)
                            
                            Text("Conducting Research...")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Text("Searching the web and analyzing results")
                                .font(.subheadline)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
        )
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
            Task { @MainActor in
                switch newPhase {
                case .active:
                    // Resume listeners when app becomes active
                    await viewModel.resumeListeners()
                    
                    // Mark messages as delivered when app becomes active/foreground
                    await viewModel.markUndeliveredMessagesAsDelivered()
                    
                case .background:
                    // Pause listeners to save battery
                    viewModel.pauseListeners()
                    
                case .inactive:
                    // Do nothing for inactive (transitional state)
                    break
                    
                @unknown default:
                    break
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
        // Create a minimal ModelContainer for preview
        let container = try! ModelContainer(for: UserModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let viewModel = ConversationViewModel(
            conversation: Conversation(
                participantIds: ["1", "2", "3"],
                participantNames: ["1": "Alice", "2": "Bob", "3": "Charlie"],
                isGroup: true,
                groupName: "Team Chat"
            ),
            messageService: previewService,
            presenceService: previewPresence,
            authService: previewAuth,
            modelContainer: container
        )
        let previewState = AppState(modelContainer: container)
        ConversationView(viewModel: viewModel, userService: previewUser)
            .environmentObject(previewState)
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
    
    func setAway(userId: String) async throws { }

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
    
    func resetPassword(email: String) async throws { }
}

private final class PreviewUserServiceForConversation: UserService {
    func fetchAllUsers() async throws -> [User] {
        [
            User(id: "1", email: "alice@wutzup.app", displayName: "Alice"),
            User(id: "2", email: "bob@wutzup.app", displayName: "Bob"),
            User(id: "3", email: "charlie@wutzup.app", displayName: "Charlie")
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
