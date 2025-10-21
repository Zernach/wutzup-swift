//
//  AppState.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true  // True while Firebase is checking auth
    @Published var showNotificationPermissionPrompt = false
    @Published var selectedConversationFromNotification: String?
    
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
    private var hasRequestedNotificationPermission = false
    
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
            authService: authService,
            userService: userService,
            presenceService: presenceService
        )
        
        // Setup notification handler
        notificationService.onNotificationTap = { [weak self] conversationId in
            self?.handleNotificationTap(conversationId: conversationId)
        }
        
        // Observe auth state and loading state
        observeAuthState()
        observeAuthLoadingState()
    }
    
    /// Observe Firebase auth checking state
    private func observeAuthLoadingState() {
        authService.isAuthCheckingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isChecking in
                guard let self else { return }
                self.isLoading = isChecking
            }
            .store(in: &cancellables)
    }
    
    private func observeAuthState() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                
                let previousUserId = self.currentUser?.id
                let wasAuthenticated = self.currentUser != nil
                
                self.currentUser = user
                self.isAuthenticated = user != nil
                
                if user == nil {
                    self.chatListViewModel.conversations = []
                    self.hasRequestedNotificationPermission = false
                }

                // Update presence when auth state changes
                if let user = user {
                    Task {
                        try? await self.presenceService.setOnline(userId: user.id)
                        
                        // Request notification permission after successful login
                        // Only show prompt once per session
                        if !wasAuthenticated && !self.hasRequestedNotificationPermission {
                            self.hasRequestedNotificationPermission = true
                            
                            // Delay slightly to let the UI settle
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            
                            await self.requestNotificationPermissionIfNeeded()
                        }
                    }
                } else if let previousUserId {
                    Task {
                        try? await self.presenceService.setOffline(userId: previousUserId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Request notification permission if not already granted
    func requestNotificationPermissionIfNeeded() async {
        do {
            // Check current permission status
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            switch settings.authorizationStatus {
            case .notDetermined:
                // Show custom prompt first
                showNotificationPermissionPrompt = true
                
            case .denied:
                print("ℹ️ Notification permissions previously denied")
                
            case .authorized, .provisional, .ephemeral:
                print("✅ Notification permissions already granted")
                
            @unknown default:
                break
            }
        }
    }
    
    /// Actually request permission from the system
    func requestNotificationPermission() async {
        do {
            let granted = try await notificationService.requestPermission()
            
            if granted {
                print("✅ Notification permission granted!")
            } else {
                print("❌ Notification permission denied")
            }
            
            showNotificationPermissionPrompt = false
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            showNotificationPermissionPrompt = false
        }
    }
    
    /// Handle notification tap to open specific conversation
    func handleNotificationTap(conversationId: String) {
        selectedConversationFromNotification = conversationId
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
