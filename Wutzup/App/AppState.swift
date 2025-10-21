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
    
    // 🔥 FIX: Store pending FCM token to handle race condition
    private var pendingFCMToken: String?
    
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
        
        // Setup notification handlers
        notificationService.onNotificationTap = { [weak self] conversationId in
            self?.handleNotificationTap(conversationId: conversationId)
        }
        
        // 🔥 FIX: Handle FCM token updates through AppState to avoid race condition
        notificationService.onFCMTokenReceived = { [weak self] token in
            Task { @MainActor in
                await self?.handleFCMToken(token)
            }
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
                    // User logged out - clear data and stop observing
                    self.chatListViewModel.stopObserving()
                    self.chatListViewModel.conversations = []
                    self.hasRequestedNotificationPermission = false
                }

                // Update presence when auth state changes
                if let user = user {
                    Task { @MainActor in
                        try? await self.presenceService.setOnline(userId: user.id)
                        
                        // 🔥 FIX: Load conversations immediately on auth success
                        // This prevents the race condition where ChatListView appears
                        // before conversations are loaded
                        print("🔥 [AppState] User authenticated, loading conversations...")
                        await self.chatListViewModel.fetchConversations()
                        self.chatListViewModel.startObserving()
                        
                        // 🔥 FIX: Save any pending FCM token now that auth is ready
                        if let pendingToken = self.pendingFCMToken {
                            print("🔥 [AppState] Auth ready, saving pending FCM token...")
                            await self.saveFCMToken(pendingToken, for: user.id)
                            self.pendingFCMToken = nil
                        }
                        
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
                
                // Register for remote notifications to get APNs token
                #if os(iOS)
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("📱 Registering for remote notifications...")
                #endif
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
    
    /// 🔥 FIX: Handle FCM token updates with proper auth coordination
    private func handleFCMToken(_ token: String) async {
        print("🔑 [AppState] FCM token received: \(token.prefix(20))...")
        
        // Check if we have an authenticated user
        guard let userId = currentUser?.id else {
            print("⏳ [AppState] No authenticated user yet, storing token as pending")
            pendingFCMToken = token
            return
        }
        
        // User is authenticated, save immediately
        await saveFCMToken(token, for: userId)
    }
    
    /// Save FCM token to Firestore
    private func saveFCMToken(_ token: String, for userId: String) async {
        do {
            try await notificationService.updateFCMToken(userId: userId, token: token)
            print("✅ [AppState] FCM token saved successfully for user: \(userId)")
        } catch {
            print("❌ [AppState] Failed to save FCM token: \(error)")
            // Keep as pending to retry later
            pendingFCMToken = token
        }
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
