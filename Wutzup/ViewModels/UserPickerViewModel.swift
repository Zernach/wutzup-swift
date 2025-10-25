//
//  UserPickerViewModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import Combine
import SwiftData

@MainActor
class UserPickerViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private let userService: UserService
    private let currentUserId: String?
    private let tutorFilter: Bool?
    private let modelContainer: ModelContainer?
    
    init(userService: UserService, currentUserId: String?, tutorFilter: Bool? = nil, modelContainer: ModelContainer? = nil) {
        self.userService = userService
        self.currentUserId = currentUserId
        self.tutorFilter = tutorFilter
        self.modelContainer = modelContainer
    }
    
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedUsers = try await userService.fetchUsers(isTutor: tutorFilter)
            let filteredUsers = fetchedUsers.filter { $0.id != currentUserId }
            users = filteredUsers.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            
            // Cache users to local storage for tutor detection
            await cacheUsersToLocalStorage(filteredUsers)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Cache users to SwiftData local storage
    private func cacheUsersToLocalStorage(_ users: [User]) async {
        guard let modelContainer = modelContainer else {
            return
        }
        
        let context = ModelContext(modelContainer)
        
        for user in users {
            // Check if user already exists
            let descriptor = FetchDescriptor<UserModel>(
                predicate: #Predicate<UserModel> { $0.id == user.id }
            )
            
            do {
                let existingUsers = try context.fetch(descriptor)
                if existingUsers.isEmpty {
                    // User doesn't exist, create new one
                    let userModel = UserModel(from: user)
                    context.insert(userModel)
                } else {
                    // User exists, update if needed
                    if let existingUser = existingUsers.first {
                    // Update existing user with latest data
                    existingUser.email = user.email
                    existingUser.displayName = user.displayName
                    existingUser.profileImageUrl = user.profileImageUrl
                    existingUser.fcmToken = user.fcmToken
                    existingUser.isTutor = user.isTutor
                    existingUser.lastSeen = user.lastSeen
                    existingUser.personality = user.personality
                    }
                }
            } catch {
                // Error caching user
            }
        }
        
        // Save changes
        do {
            try context.save()
        } catch {
            // Error saving cached users
        }
    }
    
    var filteredUsers: [User] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return users
        }
        
        return users.filter { user in
            // Search in display name
            user.displayName.localizedCaseInsensitiveContains(trimmedQuery) ||
            // Search in email
            user.email.localizedCaseInsensitiveContains(trimmedQuery) ||
            // Search in personality (if available)
            (user.personality?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
        }
    }
}
