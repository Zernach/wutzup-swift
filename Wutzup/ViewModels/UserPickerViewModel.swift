//
//  UserPickerViewModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import Combine

@MainActor
class UserPickerViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private let userService: UserService
    private let currentUserId: String?
    private let tutorFilter: Bool?
    
    init(userService: UserService, currentUserId: String?, tutorFilter: Bool? = nil) {
        self.userService = userService
        self.currentUserId = currentUserId
        self.tutorFilter = tutorFilter
    }
    
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedUsers = try await userService.fetchUsers(isTutor: tutorFilter)
            let filteredUsers = fetchedUsers.filter { $0.id != currentUserId }
            users = filteredUsers.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    var filteredUsers: [User] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return users
        }
        
        return users.filter { user in
            user.displayName.localizedCaseInsensitiveContains(trimmedQuery) ||
            user.email.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}
