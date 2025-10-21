//
//  ChatListView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ChatListViewModel
    @State private var navigationPath = NavigationPath()
    
    init(
        chatService: ChatService? = nil,
        authService: AuthenticationService? = nil
    ) {
        if let chatService, let authService {
            _viewModel = StateObject(wrappedValue: ChatListViewModel(
                chatService: chatService,
                authService: authService
            ))
        } else {
            let appState = AppState()
            _viewModel = StateObject(wrappedValue: ChatListViewModel(
                chatService: appState.chatService,
                authService: appState.authService
            ))
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                } else if viewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationListView
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
                            Task {
                                try? await appState.authService.logout()
                            }
                        }) {
                            Label("Log Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(for: Conversation.self) { conversation in
                ConversationView(conversation: conversation)
            }
            .navigationDestination(for: NewChatRoute.self) { _ in
                NewChatView(
                    userService: appState.userService,
                    currentUserId: appState.currentUser?.id,
                    createOrFetchConversation: { userId in
                        await viewModel.createDirectConversation(with: userId, currentUserId: appState.currentUser?.id)
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
                    createGroupConversation: { userIds, groupName in
                        await viewModel.createGroupConversation(
                            with: userIds,
                            groupName: groupName,
                            currentUserId: appState.currentUser?.id
                        )
                    },
                    onGroupCreated: { conversation in
                        navigateToConversation(conversation)
                    }
                )
            }
            .onAppear {
                Task {
                    await viewModel.fetchConversations()
                    viewModel.startObserving()
                }
            }
            .onDisappear {
                viewModel.stopObserving()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            
            Text("No conversations yet")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Start a new chat to begin messaging")
                .font(.body)
                .foregroundColor(.secondary)
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
            }
        }
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
    ChatListView()
        .environmentObject(AppState())
}

private struct NewChatRoute: Hashable {}
private struct NewGroupRoute: Hashable {}
