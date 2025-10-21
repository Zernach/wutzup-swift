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
    
    // Shared view models
    let chatListViewModel: ChatListViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize services
        self.authService = FirebaseAuthService()
        self.messageService = FirebaseMessageService()
        self.chatService = FirebaseChatService()
        self.userService = FirebaseUserService()
        self.presenceService = FirebasePresenceService()
        self.notificationService = FirebaseNotificationService()
        self.chatListViewModel = ChatListViewModel(
            chatService: chatService,
            authService: authService
        )
        
        // Observe auth state
        observeAuthState()
    }
    
    private func observeAuthState() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                
                let previousUserId = self.currentUser?.id
                
                self.currentUser = user
                self.isAuthenticated = user != nil
                self.isLoading = false
                if user == nil {
                    self.chatListViewModel.conversations = []
                }

                // Update presence when auth state changes
                if let user = user {
                    Task {
                        try? await self.presenceService.setOnline(userId: user.id)
                    }
                } else if let previousUserId {
                    Task {
                        try? await self.presenceService.setOffline(userId: previousUserId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func makeAuthenticationViewModel() -> AuthenticationViewModel {
        AuthenticationViewModel(authService: authService)
    }
    
    func makeConversationViewModel(for conversation: Conversation) -> ConversationViewModel {
        ConversationViewModel(
            conversation: conversation,
            messageService: messageService,
            presenceService: presenceService,
            authService: authService
        )
    }
}
