//
//  ChatListView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Combine

struct ChatListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ChatListViewModel
    @State private var navigationPath = NavigationPath()

    init(viewModel: ChatListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading conversations...")
                            .tint(AppConstants.Colors.accent)
                    } else if viewModel.conversations.isEmpty {
                        emptyStateView
                    } else {
                        conversationListView
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: openNewChat) {
                            Label("New Chat", systemImage: "square.and.pencil")
                        }

                        Button(action: openNewGroup) {
                            Label("New Group", systemImage: "person.3")
                        }

                        Divider()

                        Button(role: .destructive, action: {
                            Task { @MainActor in
                                try? await appState.authService.logout()
                            }
                        }) {
                            Label("Log Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppConstants.Colors.textPrimary)
                    }
                }
            }
            .navigationDestination(for: Conversation.self) { conversation in
                ConversationView(
                    viewModel: appState.makeConversationViewModel(for: conversation)
                )
            }
            .navigationDestination(for: NewChatRoute.self) { _ in
                NewChatView(
                    userService: appState.userService,
                    currentUserId: appState.currentUser?.id,
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
                NewGroupView(
                    userService: appState.userService,
                    currentUserId: appState.currentUser?.id,
                    createGroupConversation: { users, groupName in
                        let currentUser = await MainActor.run { appState.currentUser }
                        return await viewModel.createGroupConversation(
                            with: users,
                            groupName: groupName,
                            currentUser: currentUser
                        )
                    },
                    onGroupCreated: { conversation in
                        navigateToConversation(conversation)
                    }
                )
            }
            .onAppear {
                Task { @MainActor in
                    await viewModel.fetchConversations()
                    viewModel.startObserving()
                }
            }
            .onDisappear {
                viewModel.stopObserving()
            }
        }
        .toolbarBackground(AppConstants.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
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
        .padding()
    }

    private var conversationListView: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                NavigationLink(value: conversation) {
                    ConversationRowView(conversation: conversation, currentUserId: appState.currentUser?.id ?? "")
                }
                .listRowBackground(AppConstants.Colors.surface)
                .listRowSeparatorTint(AppConstants.Colors.border)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .background(AppConstants.Colors.background)
    }

    private func openNewChat() {
        navigationPath.append(NewChatRoute())
    }

    private func openNewGroup() {
        navigationPath.append(NewGroupRoute())
    }

    @MainActor
    private func navigateToConversation(_ conversation: Conversation) {
        viewModel.upsertConversation(conversation)

        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }

        navigationPath.append(conversation)
    }
}

#Preview {
    let previewService = PreviewChatService()
    let previewAuth = PreviewAuthenticationService()
    let viewModel = ChatListViewModel(chatService: previewService, authService: previewAuth)
    return ChatListView(viewModel: viewModel)
        .environmentObject(AppState())
}

private struct NewChatRoute: Hashable {}
private struct NewGroupRoute: Hashable {}

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
}
