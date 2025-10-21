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
    @State private var selectedConversation: Conversation?
    
    init() {
        let appState = AppState()
        _viewModel = StateObject(wrappedValue: ChatListViewModel(
            chatService: appState.chatService,
            authService: appState.authService
        ))
    }
    
    var body: some View {
        NavigationStack {
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
                        Button(action: {
                            // TODO: Navigate to user search/new chat
                        }) {
                            Label("New Chat", systemImage: "square.and.pencil")
                        }
                        
                        Button(action: {
                            // TODO: Navigate to new group
                        }) {
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
        .navigationDestination(for: Conversation.self) { conversation in
            ConversationView(conversation: conversation)
        }
    }
}

#Preview {
    ChatListView()
        .environmentObject(AppState())
}

