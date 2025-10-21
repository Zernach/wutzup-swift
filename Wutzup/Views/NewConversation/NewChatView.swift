//
//  NewChatView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct NewChatView: View {
    @StateObject private var userPickerViewModel: UserPickerViewModel
    
    let createOrFetchConversation: (String) async -> Conversation?
    let onConversationCreated: (Conversation) -> Void
    
    @State private var isCreatingConversation = false
    @State private var creationErrorMessage: String?
    @State private var showErrorAlert = false
    
    init(userService: UserService,
         currentUserId: String?,
         createOrFetchConversation: @escaping (String) async -> Conversation?,
         onConversationCreated: @escaping (Conversation) -> Void) {
        _userPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: currentUserId
            )
        )
        self.createOrFetchConversation = createOrFetchConversation
        self.onConversationCreated = onConversationCreated
    }
    
    var body: some View {
        ZStack {
            List {
                if userPickerViewModel.filteredUsers.isEmpty {
                    emptyState
                } else {
                    ForEach(userPickerViewModel.filteredUsers) { user in
                        Button {
                            handleUserSelection(user)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .disabled(isCreatingConversation)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            if isCreatingConversation {
                ProgressView("Starting chat...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if userPickerViewModel.isLoading {
                ProgressView("Loading users...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .navigationTitle("New Chat")
        .searchable(text: $userPickerViewModel.searchText, prompt: "Search users")
        .task {
            await userPickerViewModel.loadUsers()
        }
        .alert("Unable to Start Chat", isPresented: $showErrorAlert, presenting: creationErrorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if userPickerViewModel.isLoading {
            EmptyView()
        } else if userPickerViewModel.searchText.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclam")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No other users found")
                    .font(.headline)
                Text("Invite teammates so you can start chatting.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No matches")
                    .font(.headline)
                Text("Try a different name or email.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        }
    }
    
    private func handleUserSelection(_ user: User) {
        guard !isCreatingConversation else { return }
        
        isCreatingConversation = true
        creationErrorMessage = nil
        
        Task {
            let conversation = await createOrFetchConversation(user.id)
            await MainActor.run {
                isCreatingConversation = false
                
                if let conversation = conversation {
                    onConversationCreated(conversation)
                } else {
                    creationErrorMessage = "Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewChatView(
            userService: PreviewUserService(),
            currentUserId: "current",
            createOrFetchConversation: { _ in
                Conversation(
                    participantIds: ["current", "other"],
                    participantNames: ["current": "Me", "other": "Someone"],
                    isGroup: false
                )
            },
            onConversationCreated: { _ in }
        )
    }
}

private final class PreviewUserService: UserService {
    func fetchAllUsers() async throws -> [User] {
        [
            User(id: "1", email: "alice@test.com", displayName: "Alice"),
            User(id: "2", email: "bob@test.com", displayName: "Bob"),
            User(id: "3", email: "charlie@test.com", displayName: "Charlie")
        ]
    }
}
