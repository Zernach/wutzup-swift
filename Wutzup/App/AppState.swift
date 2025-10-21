//
//  AppState.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    
    // Services
    let authService: FirebaseAuthService
    let messageService: FirebaseMessageService
    let chatService: FirebaseChatService
    let userService: FirebaseUserService
    let presenceService: FirebasePresenceService
    let notificationService: FirebaseNotificationService
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize services
        self.authService = FirebaseAuthService()
        self.messageService = FirebaseMessageService()
        self.chatService = FirebaseChatService()
        self.userService = FirebaseUserService()
        self.presenceService = FirebasePresenceService()
        self.notificationService = FirebaseNotificationService()
        
        // Observe auth state
        observeAuthState()
    }
    
    private func observeAuthState() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isLoading = false
                
                // Update presence when auth state changes
                if let user = user {
                    Task {
                        try? await self?.presenceService.setOnline(userId: user.id)
                    }
                } else {
                    Task {
                        if let userId = self?.currentUser?.id {
                            try? await self?.presenceService.setOffline(userId: userId)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}
