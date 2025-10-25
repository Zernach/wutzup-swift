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
import SwiftData

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
    let aiService: FirebaseAIService
    let tutorChatService: FirebaseTutorChatService
    
    // Network and offline management
    let networkMonitor = NetworkMonitor.shared
    let offlineQueue = OfflineMessageQueue.shared
    
    // Lifecycle management
    let lifecycleManager = AppLifecycleManager.shared
    
    // Shared view models
    let chatListViewModel: ChatListViewModel
    
    // SwiftData container
    let modelContainer: ModelContainer
    
    private var cancellables = Set<AnyCancellable>()
    private var hasRequestedNotificationPermission = false
    private var networkObserver: Any?
    
    // 🔥 FIX: Store pending FCM token to handle race condition
    private var pendingFCMToken: String?
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // Initialize services
        self.authService = FirebaseAuthService()
        self.messageService = FirebaseMessageService()
        self.chatService = FirebaseChatService()
        self.userService = FirebaseUserService()
        self.presenceService = FirebasePresenceService()
        self.notificationService = FirebaseNotificationService()
        self.aiService = FirebaseAIService()
        self.tutorChatService = FirebaseTutorChatService()
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
        
        // Setup network monitoring and reconnection
        setupNetworkMonitoring()
        
        // Setup lifecycle management
        setupLifecycleManagement()
        
        // Observe auth state and loading state
        observeAuthState()
        observeAuthLoadingState()
    }
    
    deinit {
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Start network monitoring
        networkMonitor.startMonitoring()
        
        // Setup reconnection observer
        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkDidReconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            Task { @MainActor in
                let downtime = notification.userInfo?["downtime"] as? TimeInterval ?? 0
                
                
                // Sync pending offline messages
                await self.offlineQueue.syncPendingMessages(messageService: self.messageService)
                
                // If we were offline for more than 30 seconds, refresh conversations
                if downtime > 30 {
                    await self.chatListViewModel.fetchConversations()
                }
            }
        }
        
    }
    
    // MARK: - Lifecycle Management
    
    private func setupLifecycleManagement() {
        
        // Handle foreground events
        lifecycleManager.onForeground = { [weak self] backgroundDuration in
            guard let self = self else { return }
            
            Task { @MainActor in
                
                // Set presence to online if authenticated
                if let userId = self.currentUser?.id {
                    try? await self.presenceService.setOnline(userId: userId)
                }
                
                // Sync offline queue
                await self.offlineQueue.syncPendingMessages(messageService: self.messageService)
                
                // If we were in background for more than 30 seconds, refresh conversations
                if let duration = backgroundDuration, duration > 30 {
                    await self.chatListViewModel.fetchConversations()
                }
                
                // Schedule next background refresh
                self.lifecycleManager.scheduleBackgroundRefresh()
            }
        }
        
        // Handle background events
        lifecycleManager.onBackground = { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                
                // Set presence to away if authenticated
                if let userId = self.currentUser?.id {
                    try? await self.presenceService.setAway(userId: userId)
                }
            }
        }
        
        // Handle listener pause
        lifecycleManager.onPauseListeners = { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.chatListViewModel.pauseListeners()
            }
        }
        
        // Handle listener resume
        lifecycleManager.onResumeListeners = { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.chatListViewModel.resumeListeners()
            }
        }
        
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
                    
                    // Clear image cache on logout for privacy and memory management
                    Task {
                        await ImageCache.shared.clearAll()
                    }
                } else if let user = user {
                    // 🔥 FIX: Delay async operations to next run loop to avoid multiple updates per frame
                    // This prevents "NavigationRequestObserver tried to update multiple times per frame" error
                    Task { @MainActor in
                        // Yield to next run loop before making state changes
                        await Task.yield()
                        
                        try? await self.presenceService.setOnline(userId: user.id)
                        
                        // 🔥 FIX: Load conversations immediately on auth success
                        // This prevents the race condition where ChatListView appears
                        // before conversations are loaded
                        await self.chatListViewModel.fetchConversations()
                        self.chatListViewModel.startObserving()
                        
                        // 🔥 FIX: Save any pending FCM token now that auth is ready
                        if let pendingToken = self.pendingFCMToken {
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
                break
                
            case .authorized, .provisional, .ephemeral:
                break
                
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
                
                // Register for remote notifications to get APNs token
                #if os(iOS)
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                #endif
            } else {
            }
            
            showNotificationPermissionPrompt = false
        } catch {
            showNotificationPermissionPrompt = false
        }
    }
    
    /// Handle notification tap to open specific conversation
    func handleNotificationTap(conversationId: String) {
        selectedConversationFromNotification = conversationId
    }
    
    /// 🔥 FIX: Handle FCM token updates with proper auth coordination
    private func handleFCMToken(_ token: String) async {
        
        // Check if we have an authenticated user
        guard let userId = currentUser?.id else {
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
        } catch {
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
            authService: authService,
            modelContainer: modelContainer,
            tutorChatService: tutorChatService,
            userService: userService
        )
    }
}
