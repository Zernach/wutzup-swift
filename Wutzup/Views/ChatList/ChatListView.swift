//
//  ChatListView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData
import Combine

struct ChatListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ChatListViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showTooltip = false

    init(viewModel: ChatListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        return
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading conversations...")
                            .tint(AppConstants.Colors.accent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 60)
                            .padding(.horizontal)
                    } else if viewModel.conversations.isEmpty {
                        emptyStateView
                    } else {
                        conversationListView
                    }
                }
                
                // Floating Action Button with Tooltip
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            if showTooltip {
                                GlassTooltip(
                                    isPresented: $showTooltip,
                                    onNewChat: openNewChat,
                                    onNewGroup: openNewGroup
                                )
                                .padding(.bottom, 8)
                                .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                            }
                            
                            GlassFloatingActionButton(
                                isExpanded: showTooltip,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showTooltip.toggle()
                                    }
                                }
                            )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: openAccount) {
                        UserProfileImageView(
                            user: appState.currentUser,
                            size: 32,
                            showOnlineStatus: false,
                            presenceService: nil
                        )
                    }
                }
            }
            .navigationDestination(for: Conversation.self) { conversation in
                ConversationView(
                    viewModel: appState.makeConversationViewModel(for: conversation),
                    userService: appState.userService,
                    chatService: viewModel.chatService
                )
            }
            .navigationDestination(for: NewChatRoute.self) { _ in
                TabbedNewChatView(
                    userService: appState.userService,
                    currentUserId: appState.currentUser?.id,
                    presenceService: appState.presenceService,
                    modelContainer: appState.modelContainer,
                    createOrFetchConversation: { @MainActor user in
                        // Get current user
                        guard let currentUser = appState.currentUser else {
                            return nil
                        }
                        // Call with user properties
                        return await viewModel.createDirectConversation(
                            with: user.id,
                            otherDisplayName: user.displayName,
                            otherEmail: user.email,
                            currentUser: currentUser
                        )
                    },
                    onConversationCreated: { conversation in
                        navigateToConversation(conversation)
                    }
                )
            }
            .navigationDestination(for: NewGroupRoute.self) { _ in
                TabbedNewGroupView(
                    userService: appState.userService,
                    currentUserId: appState.currentUser?.id,
                    chatListViewModel: viewModel,
                    modelContainer: appState.modelContainer,
                    onGroupCreated: { conversation in
                        navigateToConversation(conversation)
                    }
                )
            }
            .navigationDestination(for: AccountRoute.self) { _ in
                AccountView(presenceService: appState.presenceService)
            }
        }
        .toolbarBackground(AppConstants.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture {
            if showTooltip {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showTooltip = false
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "message.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(AppConstants.Colors.mutedIcon)

            Text("No conversations yet")
                .font(.title2)
                .foregroundColor(AppConstants.Colors.textPrimary)

            Text("Start a new chat to begin messaging")
                .font(.body)
                .foregroundColor(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
        .padding(.horizontal)
    }

    private var conversationListView: some View {
        List {
            ForEach(viewModel.conversations, id: \.id) { conversation in
                Button(action: {
                    navigationPath.append(conversation)
                }) {
                    ConversationRowView(
                        conversation: conversation,
                        currentUserId: appState.currentUser?.id ?? "",
                        otherUser: otherUser(for: conversation),
                        presenceService: appState.presenceService,
                        typingIndicatorText: viewModel.getTypingIndicatorText(for: conversation)
                    )
                }
                .buttonStyle(ConversationRowButtonStyle())
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .id(conversation.id) // Ensure SwiftUI can track row identity properly
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .background(AppConstants.Colors.background)
    }
    
    // Get the other user for a direct conversation
    private func otherUser(for conversation: Conversation) -> User? {
        guard !conversation.isGroup else { return nil }
        
        let currentUserId = appState.currentUser?.id ?? ""
        let otherParticipantId = conversation.participantIds.first { $0 != currentUserId }
        
        // Try to get user from viewModel's user cache
        if let userId = otherParticipantId {
            return viewModel.getUser(byId: userId)
        }
        
        return nil
    }

    private func openNewChat() {
        navigationPath.append(NewChatRoute())
    }

    private func openNewGroup() {
        navigationPath.append(NewGroupRoute())
    }

    private func openAccount() {
        navigationPath.append(AccountRoute())
    }


    @MainActor
    private func navigateToConversation(_ conversation: Conversation) {
        // Update view model first
        viewModel.upsertConversation(conversation)

        // Batch navigation state changes to avoid multiple updates per frame
        Task { @MainActor in
            // Yield to next run loop to ensure view updates complete
            await Task.yield()
            
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }

            navigationPath.append(conversation)
        }
    }
}

// MARK: - Button Style

struct ConversationRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    let previewService = PreviewChatService()
    let previewAuth = PreviewAuthenticationService()
    let previewPresence = PreviewPresenceServiceForChat()
    let viewModel = ChatListViewModel(
        chatService: previewService,
        authService: previewAuth,
        presenceService: previewPresence
    )
    // Create a minimal ModelContainer for preview
    let container = try! ModelContainer(for: UserModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let previewState = AppState(modelContainer: container)
    return ChatListView(viewModel: viewModel)
        .environmentObject(previewState)
}

private struct NewChatRoute: Hashable {}
private struct NewGroupRoute: Hashable {}
private struct AccountRoute: Hashable {}

private final class PreviewChatService: ChatService {
    func createConversation(withUserIds userIds: [String], isGroup: Bool, groupName: String?, participantNames: [String : String]) async throws -> Conversation {
        Conversation(
            participantIds: userIds,
            participantNames: participantNames,
            isGroup: isGroup,
            groupName: groupName
        )
    }

    func fetchConversations(userId: String) async throws -> [Conversation] {
        [
            Conversation(
                participantIds: ["current", "user-1"],
                participantNames: ["current": "Me", "user-1": "Alex"],
                lastMessage: "Hey there!",
                lastMessageTimestamp: Date()
            )
        ]
    }

    func observeConversations(userId: String) -> AsyncStream<Conversation> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func fetchOrCreateDirectConversation(userId: String, otherUserId: String, participantNames: [String : String]) async throws -> Conversation {
        Conversation(
            participantIds: [userId, otherUserId],
            participantNames: participantNames
        )
    }

    func updateConversation(_ conversation: Conversation) async throws { }
}

private final class PreviewAuthenticationService: AuthenticationService {
    var authStatePublisher: AnyPublisher<User?, Never> {
        Just(User(id: "current", email: "me@wutzup.app", displayName: "Me")).eraseToAnyPublisher()
    }
    
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    var currentUser: User? {
        User(id: "current", email: "me@wutzup.app", displayName: "Me")
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

private final class PreviewPresenceServiceForChat: PresenceService {
    func setOnline(userId: String) async throws { }
    func setOffline(userId: String) async throws { }
    func setAway(userId: String) async throws { }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
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
