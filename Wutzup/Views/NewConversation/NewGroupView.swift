//
//  NewGroupView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Combine

struct NewGroupView: View {
    @StateObject private var userPickerViewModel: UserPickerViewModel
    @ObservedObject var chatListViewModel: ChatListViewModel
    
    let onGroupCreated: (Conversation) -> Void
    
    @State private var selectedUserIds: Set<String> = []
    @State private var groupName: String = ""
    @State private var isCreatingGroup = false
    @State private var showErrorAlert = false
    
    init(userService: UserService,
         currentUserId: String?,
         chatListViewModel: ChatListViewModel,
         onGroupCreated: @escaping (Conversation) -> Void) {
        _userPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: currentUserId
            )
        )
        self.chatListViewModel = chatListViewModel
        self.onGroupCreated = onGroupCreated
    }
    
    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var selectedUsers: [User] {
        userPickerViewModel.users.filter { selectedUserIds.contains($0.id) }
    }
    
    private var canCreateGroup: Bool {
        !trimmedGroupName.isEmpty && selectedUsers.count >= 2 && !isCreatingGroup
    }
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            Form {
                Section("Group Name") {
                    TextField("Name your group", text: $groupName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .tint(AppConstants.Colors.accent)
                }
                
                Section("Participants") {
                    if userPickerViewModel.filteredUsers.isEmpty {
                        emptyState
                    } else {
                        ForEach(userPickerViewModel.filteredUsers) { user in
                            Button {
                                toggleSelection(for: user)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.displayName)
                                            .font(.body)
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                        Text(user.email)
                                            .font(.footnote)
                                            .foregroundColor(AppConstants.Colors.textSecondary)
                                    }
                                    Spacer()
                                    if selectedUserIds.contains(user.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppConstants.Colors.accent)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(AppConstants.Colors.textSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .disabled(isCreatingGroup)
                            .listRowBackground(AppConstants.Colors.surface)
                            .listRowSeparatorTint(AppConstants.Colors.border)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppConstants.Colors.background)
            .listRowBackground(AppConstants.Colors.surface)
        }
        .navigationTitle("New Group")
        .searchable(text: $userPickerViewModel.searchText, prompt: "Search users")
        .task {
            await userPickerViewModel.loadUsers()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isCreatingGroup {
                    ProgressView()
                        .tint(AppConstants.Colors.accent)
                } else {
                    Button("Create") {
                        handleCreateGroup()
                    }
                    .tint(AppConstants.Colors.accent)
                    .disabled(!canCreateGroup)
                }
            }
        }
        .alert("Unable to Create Group", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                chatListViewModel.errorMessage = nil
            }
        } message: {
            Text(chatListViewModel.errorMessage ?? "Please try again.")
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if userPickerViewModel.isLoading {
            ProgressView()
                .tint(AppConstants.Colors.accent)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if userPickerViewModel.searchText.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.3")
                    .font(.system(size: 48))
                    .foregroundColor(AppConstants.Colors.mutedIcon)
                Text("No teammates yet")
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                Text("Invite people to your workspace to start a group chat.")
                    .font(.subheadline)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 32)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(AppConstants.Colors.mutedIcon)
                Text("No matches")
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                Text("Try searching by a different name or email.")
                    .font(.subheadline)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 32)
        }
    }
    
    private func toggleSelection(for user: User) {
        if selectedUserIds.contains(user.id) {
            selectedUserIds.remove(user.id)
        } else {
            selectedUserIds.insert(user.id)
        }
    }
    
    private func handleCreateGroup() {
        guard canCreateGroup else {
            chatListViewModel.errorMessage = "Please select at least 2 people and provide a group name."
            showErrorAlert = true
            return
        }
        
        // Additional validation
        if selectedUsers.count < 2 {
            chatListViewModel.errorMessage = "Please select at least 2 people to create a group chat."
            showErrorAlert = true
            return
        }
        
        isCreatingGroup = true
        chatListViewModel.errorMessage = nil
        
        let name = trimmedGroupName
        let users = selectedUsers
        
        print("🔍 Creating group with \(users.count) selected users")
        print("🔍 Selected user IDs: \(users.map { $0.id })")
        
        Task { @MainActor in
            let conversation = await chatListViewModel.createGroupConversation(
                with: users,
                groupName: name,
                currentUser: nil
            )
            isCreatingGroup = false
            
            if let conversation = conversation {
                onGroupCreated(conversation)
            } else {
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    let authService = PreviewAuthService()
    let chatService = PreviewChatService()
    let userService = PreviewUserService()
    let viewModel = ChatListViewModel(chatService: chatService, authService: authService)
    
    return NavigationStack {
        NewGroupView(
            userService: userService,
            currentUserId: "current",
            chatListViewModel: viewModel,
            onGroupCreated: { _ in }
        )
    }
}

private final class PreviewAuthService: AuthenticationService {
    var currentUser: User? = User(id: "current", email: "me@test.com", displayName: "Me")
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        Just(currentUser).eraseToAnyPublisher()
    }
    
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, displayName: String) async throws -> User {
        User(id: "current", email: email, displayName: displayName)
    }
    
    func login(email: String, password: String) async throws -> User {
        User(id: "current", email: email, displayName: "Me")
    }
    
    func logout() async throws {}
    
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws {}
    
    func deleteAccount() async throws {}
}

private final class PreviewChatService: ChatService {
    func createConversation(withUserIds userIds: [String], isGroup: Bool, groupName: String?, participantNames: [String: String]) async throws -> Conversation {
        Conversation(
            participantIds: userIds,
            participantNames: participantNames,
            isGroup: isGroup,
            groupName: groupName
        )
    }
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        []
    }
    
    func observeConversations(userId: String) -> AsyncStream<Conversation> {
        AsyncStream { _ in }
    }
    
    func fetchOrCreateDirectConversation(userId: String, otherUserId: String, participantNames: [String: String]) async throws -> Conversation {
        Conversation(
            participantIds: [userId, otherUserId],
            participantNames: participantNames,
            isGroup: false
        )
    }
    
    func updateConversation(_ conversation: Conversation) async throws {}
}

private final class PreviewUserService: UserService {
    func fetchAllUsers() async throws -> [User] {
        [
            User(id: "1", email: "alice@test.com", displayName: "Alice"),
            User(id: "2", email: "bob@test.com", displayName: "Bob"),
            User(id: "3", email: "charlie@test.com", displayName: "Charlie"),
            User(id: "4", email: "diana@test.com", displayName: "Diana")
        ]
    }
}
