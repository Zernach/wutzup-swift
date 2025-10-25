//
//  TabbedNewGroupView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Combine
import SwiftData

struct TabbedNewGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userPickerViewModel: UserPickerViewModel
    @StateObject private var tutorPickerViewModel: UserPickerViewModel
    @ObservedObject var chatListViewModel: ChatListViewModel
    
    let onGroupCreated: (Conversation) -> Void
    
    @State private var selectedUserIds: Set<String> = []
    @State private var groupName: String = ""
    @State private var isCreatingGroup = false
    @State private var showErrorAlert = false
    @State private var selectedTab = 0
    
    init(userService: UserService,
         currentUserId: String?,
         chatListViewModel: ChatListViewModel,
         modelContainer: ModelContainer? = nil,
         onGroupCreated: @escaping (Conversation) -> Void) {
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
        self.chatListViewModel = chatListViewModel
        self.onGroupCreated = onGroupCreated
    }
    
    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var selectedUsers: [User] {
        let allUsers = userPickerViewModel.users + tutorPickerViewModel.users
        return allUsers.filter { selectedUserIds.contains($0.id) }
    }
    
    private var canCreateGroup: Bool {
        selectedUsers.count >= 1 && !isCreatingGroup
    }
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // Custom Navigation Bar with Search
                HStack(spacing: 8) {
                    // Back Button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.accent)
                    }
                    .padding(.leading, 8)
                    
                    // Search Bar - Takes up remaining space
                    HStack(spacing: 8) {
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
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppConstants.Colors.border.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.trailing, 16)
                }
                .frame(height: 44)
                .background(AppConstants.Colors.background)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Group Name Section
                VStack(spacing: 0) {
                    HStack {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    TextField("Name your group", text: $groupName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .tint(AppConstants.Colors.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppConstants.Colors.surface)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .background(AppConstants.Colors.background)
                
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
                .padding(.bottom, 8)
                
                // Content based on selected tab with bottom padding for fixed button
                TabView(selection: $selectedTab) {
                    // Users Tab
                    GroupParticipantListView(
                        viewModel: userPickerViewModel,
                        selectedUserIds: $selectedUserIds,
                        isCreatingGroup: isCreatingGroup
                    )
                    .tag(0)
                    
                    // Tutors Tab
                    GroupParticipantListView(
                        viewModel: tutorPickerViewModel,
                        selectedUserIds: $selectedUserIds,
                        isCreatingGroup: isCreatingGroup
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .padding(.bottom, 100) // Add bottom padding to prevent content from being hidden behind the fixed button
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Fixed Create Group Button at the bottom
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Create Group Button
                    if isCreatingGroup {
                        HStack {
                            ProgressView()
                                .tint(AppConstants.Colors.accent)
                                .scaleEffect(0.8)
                            Text("Creating Group...")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppConstants.Colors.background)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppConstants.Colors.border),
                            alignment: .top
                        )
                    } else {
                        Button(action: handleCreateGroup) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 16, weight: .medium))
                                if selectedUsers.isEmpty {
                                    Text("Create Group")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Create Group (\(selectedUsers.count))")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(canCreateGroup ? .white : AppConstants.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .disabled(!canCreateGroup)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(canCreateGroup ? Color.blue : AppConstants.Colors.background)
                        )
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppConstants.Colors.border),
                            alignment: .top
                        )
                    }
                }
                .background(AppConstants.Colors.background)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Load both user types
            await userPickerViewModel.loadUsers()
            await tutorPickerViewModel.loadUsers()
        }
        .alert("Unable to Create Group", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                chatListViewModel.errorMessage = nil
            }
        } message: {
            Text(chatListViewModel.errorMessage ?? "Please try again.")
        }
    }
    
    private func handleCreateGroup() {
        guard canCreateGroup else {
            chatListViewModel.errorMessage = "Please select at least 1 person to create a group chat."
            showErrorAlert = true
            return
        }
        
        // Additional validation
        if selectedUsers.count < 1 {
            chatListViewModel.errorMessage = "Please select at least 1 person to create a group chat."
            showErrorAlert = true
            return
        }
        
        isCreatingGroup = true
        chatListViewModel.errorMessage = nil
        
        let name = trimmedGroupName
        let users = selectedUsers
        
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Group Participant List View Component
struct GroupParticipantListView: View {
    @ObservedObject var viewModel: UserPickerViewModel
    @Binding var selectedUserIds: Set<String>
    let isCreatingGroup: Bool
    
    var body: some View {
        ZStack {
            List {
                if viewModel.filteredUsers.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.filteredUsers) { user in
                        Button {
                            toggleSelection(for: user)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.body)
                                        .foregroundColor(AppConstants.Colors.textPrimary)
                                    Text(user.personality ?? user.email)
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
            .scrollContentBackground(.hidden)
            .background(AppConstants.Colors.background)
            .listRowBackground(AppConstants.Colors.surface)

            if viewModel.isLoading {
                ProgressView()
                    .tint(AppConstants.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(AppConstants.Colors.accent)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if viewModel.searchText.isEmpty {
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
                Text("Try searching by name, email, or personality.")
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
}

#Preview {
    let authService = PreviewAuthService()
    let chatService = PreviewChatService()
    let userService = PreviewUserService()
    let viewModel = ChatListViewModel(chatService: chatService, authService: authService)
    
    return NavigationStack {
        TabbedNewGroupView(
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
    
    func resetPassword(email: String) async throws {
        // No-op for preview
    }
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
