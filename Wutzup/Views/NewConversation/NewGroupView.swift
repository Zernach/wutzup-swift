//
//  NewGroupView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct NewGroupView: View {
    @StateObject private var userPickerViewModel: UserPickerViewModel
    
    let createGroupConversation: ([String], String) async -> Conversation?
    let onGroupCreated: (Conversation) -> Void
    
    @State private var selectedUserIds: Set<String> = []
    @State private var groupName: String = ""
    @State private var isCreatingGroup = false
    @State private var creationErrorMessage: String?
    @State private var showErrorAlert = false
    
    init(userService: UserService,
         currentUserId: String?,
         createGroupConversation: @escaping ([String], String) async -> Conversation?,
         onGroupCreated: @escaping (Conversation) -> Void) {
        _userPickerViewModel = StateObject(
            wrappedValue: UserPickerViewModel(
                userService: userService,
                currentUserId: currentUserId
            )
        )
        self.createGroupConversation = createGroupConversation
        self.onGroupCreated = onGroupCreated
    }
    
    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canCreateGroup: Bool {
        !trimmedGroupName.isEmpty && selectedUserIds.count >= 2 && !isCreatingGroup
    }
    
    var body: some View {
        Form {
            Section("Group Name") {
                TextField("Name your group", text: $groupName)
                    .textInputAutocapitalization(.words)
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
                                    Text(user.email)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedUserIds.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .disabled(isCreatingGroup)
                    }
                }
            }
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
                } else {
                    Button("Create") {
                        handleCreateGroup()
                    }
                    .disabled(!canCreateGroup)
                }
            }
        }
        .alert("Unable to Create Group", isPresented: $showErrorAlert, presenting: creationErrorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if userPickerViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
        } else if userPickerViewModel.searchText.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.3")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No teammates yet")
                    .font(.headline)
                Text("Invite people to your workspace to start a group chat.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 32)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No matches")
                    .font(.headline)
                Text("Try searching by a different name or email.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
        guard canCreateGroup else { return }
        
        isCreatingGroup = true
        creationErrorMessage = nil
        
        let participantIds = Array(selectedUserIds)
        let name = trimmedGroupName
        
        Task {
            let conversation = await createGroupConversation(participantIds, name)
            await MainActor.run {
                isCreatingGroup = false
                
                if let conversation = conversation {
                    onGroupCreated(conversation)
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
        NewGroupView(
            userService: PreviewUserService(),
            currentUserId: "current",
            createGroupConversation: { userIds, name in
                Conversation(
                    participantIds: ["current"] + userIds,
                    participantNames: ["current": "Me"],
                    isGroup: true,
                    groupName: name
                )
            },
            onGroupCreated: { _ in }
        )
    }
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
