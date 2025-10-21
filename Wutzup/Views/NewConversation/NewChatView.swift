//
//  NewChatView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Foundation

struct NewChatView: View {
    @StateObject private var userPickerViewModel: UserPickerViewModel

    // Pass User directly - mark as @MainActor to avoid async boundary corruption
    let createOrFetchConversation: @MainActor (User) async -> Conversation?
    let onConversationCreated: (Conversation) -> Void

    @State private var isCreatingConversation = false
    @State private var creationErrorMessage: String?
    @State private var showErrorAlert = false

    init(userService: UserService,
         currentUserId: String?,
         createOrFetchConversation: @escaping @MainActor (User) async -> Conversation?,
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
            AppConstants.Colors.background
                .ignoresSafeArea()

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
                                        .foregroundColor(AppConstants.Colors.textPrimary)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .disabled(isCreatingConversation)
                        .listRowBackground(AppConstants.Colors.surface)
                        .listRowSeparatorTint(AppConstants.Colors.border)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .background(AppConstants.Colors.background)

            if isCreatingConversation {
                ProgressView("Starting chat...")
                    .tint(AppConstants.Colors.accent)
                    .padding()
                    .background(AppConstants.Colors.surface.opacity(0.95))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppConstants.Colors.border, lineWidth: 1)
                    )
            } else if userPickerViewModel.isLoading {
                ProgressView("Loading users...")
                    .tint(AppConstants.Colors.accent)
                    .padding()
                    .background(AppConstants.Colors.surface.opacity(0.95))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppConstants.Colors.border, lineWidth: 1)
                    )
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
                    .foregroundColor(AppConstants.Colors.mutedIcon)
                Text("No other users found")
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                Text("Invite teammates so you can start chatting.")
                    .font(.subheadline)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(AppConstants.Colors.mutedIcon)
                Text("No matches")
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                Text("Try a different name or email.")
                    .font(.subheadline)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        }
    }

    private func handleUserSelection(_ user: User) {
        guard !isCreatingConversation else { return }

        isCreatingConversation = true
        creationErrorMessage = nil

        Task { @MainActor in
            // Pass User object directly - @MainActor should prevent corruption
            let conversation = await createOrFetchConversation(user)

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

#Preview {
    NavigationStack {
        NewChatView(
            userService: PreviewUserService(),
            currentUserId: "current",
            createOrFetchConversation: { @MainActor user in
                Conversation(
                    participantIds: ["current", user.id],
                    participantNames: ["current": "Me", user.id: user.displayName],
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
