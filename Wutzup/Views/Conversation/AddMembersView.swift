//
//  AddMembersView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData

struct AddMembersView: View {
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    let userService: UserService
    let chatService: ChatService
    let onMembersAdded: ([User]) -> Void
    
    @StateObject private var userPickerViewModel: UserPickerViewModel
    @StateObject private var tutorPickerViewModel: UserPickerViewModel
    @State private var selectedUserIds: Set<String> = []
    @State private var isAddingMembers = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    init(conversation: Conversation, userService: UserService, chatService: ChatService, onMembersAdded: @escaping ([User]) -> Void) {
        self.conversation = conversation
        self.userService = userService
        self.chatService = chatService
        self.onMembersAdded = onMembersAdded
        
        // Initialize view model for regular users
        _userPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: nil, // We'll filter out current participants anyway
                tutorFilter: false,
                modelContainer: nil
            )
        )
        
        // Initialize view model for tutors
        _tutorPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: nil,
                tutorFilter: true,
                modelContainer: nil
            )
        )
    }
    
    private var currentViewModel: UserPickerViewModel {
        selectedTab == 0 ? userPickerViewModel : tutorPickerViewModel
    }
    
    private var selectedUsers: [User] {
        // Combine users from both view models
        let allUsers = userPickerViewModel.users + tutorPickerViewModel.users
        return allUsers.filter { selectedUserIds.contains($0.id) }
    }
    
    private var canAddMembers: Bool {
        !selectedUsers.isEmpty && !isAddingMembers
    }
    
    private var availableUsers: [User] {
        // Filter out users who are already in the conversation
        currentViewModel.filteredUsers.filter { user in
            !conversation.participantIds.contains(user.id)
        }
    }
    
    var body: some View {
        NavigationStack {
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
                .padding(.bottom, 8)
                .background(AppConstants.Colors.background)
                
                // Content
                ZStack {
                    AppConstants.Colors.background
                        .ignoresSafeArea()
                    
                    if currentViewModel.isLoading {
                        ProgressView("Loading \(selectedTab == 0 ? "users" : "tutors")...")
                            .tint(AppConstants.Colors.accent)
                    } else if availableUsers.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: selectedTab == 0 ? "person.3.fill" : "graduationcap.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppConstants.Colors.mutedIcon)
                            
                            Text("No Available \(selectedTab == 0 ? "Users" : "Tutors")")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Text("All \(selectedTab == 0 ? "users" : "tutors") are already members of this conversation.")
                                .font(.subheadline)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 0) {
                            // Selected users count
                            if !selectedUsers.isEmpty {
                                HStack {
                                    Text("\(selectedUsers.count) selected")
                                        .font(.subheadline)
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Button("Clear") {
                                        selectedUserIds.removeAll()
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(AppConstants.Colors.accent)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(AppConstants.Colors.surface)
                            }
                            
                            // TabView for switching between users and tutors
                            TabView(selection: $selectedTab) {
                                // Users List
                                AddMembersListView(
                                    users: availableUsers,
                                    selectedUserIds: $selectedUserIds,
                                    isAddingMembers: isAddingMembers,
                                    toggleSelection: toggleSelection
                                )
                                .tag(0)
                                
                                // Tutors List
                                AddMembersListView(
                                    users: availableUsers,
                                    selectedUserIds: $selectedUserIds,
                                    isAddingMembers: isAddingMembers,
                                    toggleSelection: toggleSelection
                                )
                                .tag(1)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            
                            // Add Members Button
                            VStack(spacing: 0) {
                                Divider()
                                    .background(AppConstants.Colors.border)
                                
                                Button {
                                    Task {
                                        await addSelectedMembers()
                                    }
                                } label: {
                                    HStack {
                                        if isAddingMembers {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(AppConstants.Colors.accent)
                                        } else {
                                            Image(systemName: "person.badge.plus")
                                                .font(.title2)
                                        }
                                        
                                        Text(isAddingMembers ? "Adding Members..." : "Add Members")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(AppConstants.Colors.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppConstants.Colors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(AppConstants.Colors.border, lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(!canAddMembers)
                                .opacity(canAddMembers ? 1.0 : 0.6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: Binding(
                get: { currentViewModel.searchText },
                set: { currentViewModel.searchText = $0 }
            ), prompt: "Search \(selectedTab == 0 ? "users" : "tutors")")
            .task {
                await userPickerViewModel.loadUsers()
                await tutorPickerViewModel.loadUsers()
            }
            .alert("Unable to Add Members", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { message in
                Text(message)
            }
        }
    }
    
    private func toggleSelection(for user: User) {
        if selectedUserIds.contains(user.id) {
            selectedUserIds.remove(user.id)
        } else {
            selectedUserIds.insert(user.id)
        }
    }
    
    @MainActor
    private func addSelectedMembers() async {
        guard !selectedUsers.isEmpty else { return }
        
        isAddingMembers = true
        errorMessage = nil
        
        do {
            // Create updated conversation with new members
            var updatedConversation = conversation
            var newParticipantIds = Set(conversation.participantIds)
            var newParticipantNames = conversation.participantNames
            
            // Add new members
            for user in selectedUsers {
                newParticipantIds.insert(user.id)
                newParticipantNames[user.id] = user.displayName
            }
            
            updatedConversation.participantIds = Array(newParticipantIds).sorted()
            updatedConversation.participantNames = newParticipantNames
            updatedConversation.updatedAt = Date()
            
            // Update the conversation in the database
            try await chatService.updateConversation(updatedConversation)
            
            // Call the callback to refresh the members list
            onMembersAdded(selectedUsers)
            
            // Dismiss the view
            dismiss()
            
        } catch {
            errorMessage = "Failed to add members: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isAddingMembers = false
    }
}

#Preview {
    let previewConversation = Conversation(
        participantIds: ["user1", "user2"],
        participantNames: [
            "user1": "Alice Johnson",
            "user2": "Bob Smith"
        ],
        isGroup: true,
        groupName: "Work Team"
    )
    
    AddMembersView(
        conversation: previewConversation,
        userService: PreviewUserService(),
        chatService: PreviewChatService(),
        onMembersAdded: { _ in }
    )
}

// Preview-only service
private final class PreviewUserService: UserService {
    func fetchAllUsers() async throws -> [User] {
        [
            User(
                id: "user1",
                email: "alice@example.com",
                displayName: "Alice Johnson",
                profileImageUrl: nil
            ),
            User(
                id: "user2",
                email: "bob@example.com",
                displayName: "Bob Smith",
                profileImageUrl: nil
            ),
            User(
                id: "user3",
                email: "charlie@example.com",
                displayName: "Charlie Davis",
                profileImageUrl: nil
            ),
            User(
                id: "user4",
                email: "diana@example.com",
                displayName: "Diana Wilson",
                profileImageUrl: nil
            )
        ]
    }
    
    func fetchUsers(isTutor: Bool?) async throws -> [User] {
        let allUsers = try await fetchAllUsers()
        guard let isTutor = isTutor else {
            return allUsers
        }
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

private final class PreviewChatService: ChatService {
    func createConversation(withUserIds userIds: [String], isGroup: Bool, groupName: String?, participantNames: [String: String]) async throws -> Conversation {
        return Conversation(
            participantIds: userIds,
            participantNames: participantNames,
            isGroup: isGroup,
            groupName: groupName
        )
    }
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        return []
    }
    
    func observeConversations(userId: String) -> AsyncStream<Conversation> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    func fetchOrCreateDirectConversation(userId: String, otherUserId: String, participantNames: [String: String]) async throws -> Conversation {
        return Conversation(
            participantIds: [userId, otherUserId],
            participantNames: participantNames,
            isGroup: false
        )
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        // Preview implementation - no-op
    }
}


// MARK: - AddMembersListView Component
struct AddMembersListView: View {
    let users: [User]
    @Binding var selectedUserIds: Set<String>
    let isAddingMembers: Bool
    let toggleSelection: (User) -> Void
    
    var body: some View {
        List {
            ForEach(users) { user in
                Button {
                    toggleSelection(user)
                } label: {
                    HStack(spacing: 12) {
                        UserProfileImageView(
                            user: user,
                            size: 44,
                            showOnlineStatus: false,
                            presenceService: nil
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedUserIds.contains(user.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppConstants.Colors.accent)
                                .font(.title2)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(AppConstants.Colors.textSecondary)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(isAddingMembers)
                .listRowBackground(AppConstants.Colors.surface)
                .listRowSeparatorTint(AppConstants.Colors.border)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
