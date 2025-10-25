//
//  TabbedNewChatView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Foundation
import SwiftData

struct TabbedNewChatView: View {
    @StateObject private var userPickerViewModel: UserPickerViewModel
    @StateObject private var tutorPickerViewModel: UserPickerViewModel
    
    // Pass User directly - mark as @MainActor to avoid async boundary corruption
    let createOrFetchConversation: @MainActor (User) async -> Conversation?
    let onConversationCreated: (Conversation) -> Void
    let presenceService: PresenceService?
    
    @State private var isCreatingConversation = false
    @State private var creationErrorMessage: String?
    @State private var showErrorAlert = false
    @State private var selectedTab = 0

    init(userService: UserService,
         currentUserId: String?,
         presenceService: PresenceService?,
         modelContainer: ModelContainer? = nil,
         createOrFetchConversation: @escaping @MainActor (User) async -> Conversation?,
         onConversationCreated: @escaping (Conversation) -> Void) {
        // Initialize view model for regular users
        _userPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: currentUserId,
                tutorFilter: false,
                modelContainer: modelContainer
            )
        )
        // Initialize view model for tutors
        _tutorPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: currentUserId,
                tutorFilter: true,
                modelContainer: modelContainer
            )
        )
        self.createOrFetchConversation = createOrFetchConversation
        self.onConversationCreated = onConversationCreated
        self.presenceService = presenceService
    }

    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Tab Picker
                HStack(spacing: 0) {
                    TabButton(
                        title: "Users",
                        icon: "person.2",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Tutors",
                        icon: "graduationcap",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Users Tab
                    UserListView(
                        viewModel: userPickerViewModel,
                        presenceService: presenceService,
                        isCreatingConversation: isCreatingConversation,
                        onUserSelected: handleUserSelection
                    )
                    .tag(0)
                    
                    // Tutors Tab
                    UserListView(
                        viewModel: tutorPickerViewModel,
                        presenceService: presenceService,
                        isCreatingConversation: isCreatingConversation,
                        onUserSelected: handleUserSelection
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search users", text: selectedTab == 0 ? $userPickerViewModel.searchText : $tutorPickerViewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .textFieldStyle(.plain)
                    
                    if !(selectedTab == 0 ? userPickerViewModel.searchText : tutorPickerViewModel.searchText).isEmpty {
                        Button(action: {
                            if selectedTab == 0 {
                                userPickerViewModel.searchText = ""
                            } else {
                                tutorPickerViewModel.searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppConstants.Colors.textSecondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                        
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppConstants.Colors.accent.opacity(0.3),
                                        AppConstants.Colors.border.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
            }
        }
        .task {
            // Load both user types
            await userPickerViewModel.loadUsers()
            await tutorPickerViewModel.loadUsers()
        }
        .alert("Unable to Start Chat", isPresented: $showErrorAlert, presenting: creationErrorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
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

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSelected ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? AppConstants.Colors.accent.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - User List View Component
struct UserListView: View {
    @ObservedObject var viewModel: UserPickerViewModel
    let presenceService: PresenceService?
    let isCreatingConversation: Bool
    let onUserSelected: (User) -> Void
    
    var body: some View {
        ZStack {
            List {
                if viewModel.filteredUsers.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.filteredUsers) { user in
                        Button {
                            onUserSelected(user)
                        } label: {
                            HStack(spacing: 12) {
                                // User profile image with online status
                                UserProfileImageView(
                                    user: user,
                                    size: 50,
                                    showOnlineStatus: true,
                                    presenceService: presenceService
                                )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.headline)
                                        .foregroundColor(AppConstants.Colors.textPrimary)
                                    Text(user.personality ?? user.email)
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
            } else if viewModel.isLoading {
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
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isLoading {
            EmptyView()
        } else if viewModel.searchText.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclam")
                    .font(.system(size: 48))
                    .foregroundColor(AppConstants.Colors.mutedIcon)
                Text("No users found")
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
                Text("Try searching by name, email, or personality.")
                    .font(.subheadline)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        }
    }
}

#Preview {
    NavigationStack {
        TabbedNewChatView(
            userService: PreviewUserService(),
            currentUserId: "current",
            presenceService: PreviewPresenceService(),
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
            User(id: "1", email: "alice@test.com", displayName: "Alice Johnson"),
            User(id: "2", email: "bob@test.com", displayName: "Bob Smith"),
            User(id: "3", email: "charlie@test.com", displayName: "Charlie Brown")
        ]
    }
    
    func fetchUsers(isTutor: Bool?) async throws -> [User] {
        let allUsers = try await fetchAllUsers()
        guard let isTutor = isTutor else {
            return allUsers
        }
        return allUsers.filter { $0.isTutor == isTutor }
    }
    
    func fetchUser(userId: String) async throws -> User {
        let users = try await fetchAllUsers()
        guard let user = users.first(where: { $0.id == userId }) else {
            throw NSError(domain: "PreviewUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    func updatePersonality(userId: String, personality: String?) async throws {
        // No-op for preview
    }
    
    func updateProfileImageUrl(userId: String, imageUrl: String?) async throws {
        // No-op for preview
    }
    
    func updateLanguages(userId: String, primaryLanguageCode: String?, learningLanguageCode: String?) async throws {
        // No-op for preview
    }
}

private class PreviewPresenceService: PresenceService {
    func setOnline(userId: String) async throws { }
    func setOffline(userId: String) async throws { }
    func setAway(userId: String) async throws { }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
            // Alternate between online and offline for preview variety
            let isOnline = userId.hashValue % 2 == 0
            let presence = Presence(
                userId: userId,
                status: isOnline ? .online : .offline,
                lastSeen: Date(),
                typing: [:]
            )
            continuation.yield(presence)
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
