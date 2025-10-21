//
//  AccountView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import UserNotifications

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isDeleting = false
    @State private var fcmToken: String?
    @State private var isLoadingToken = true
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    @State private var showingTokenCopied = false
    
    var presenceService: PresenceService? = nil
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // User Info Section
                    VStack(spacing: 16) {
                        // Profile Avatar with online status
                        UserProfileImageView(
                            user: appState.currentUser,
                            size: 100,
                            showOnlineStatus: true,
                            presenceService: presenceService
                        )
                        
                        // Display Name
                        Text(appState.currentUser?.displayName ?? "User")
                            .font(.title2.bold())
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        // Email
                        Text(appState.currentUser?.email ?? "")
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    Divider()
                        .background(AppConstants.Colors.border)
                    
                    // Push Notifications Section
                    VStack(spacing: 0) {
                        // Section Header
                        HStack {
                            Text("Push Notifications")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                        
                        // Notification Status
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: notificationStatusIcon)
                                    .foregroundColor(notificationStatusColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notification Status")
                                        .font(.body)
                                        .foregroundColor(AppConstants.Colors.textPrimary)
                                    
                                    Text(notificationStatusText)
                                        .font(.caption)
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppConstants.Colors.surface)
                            
                            // FCM Token Section
                            if isLoadingToken {
                                HStack {
                                    ProgressView()
                                        .tint(AppConstants.Colors.textSecondary)
                                    Text("Loading token...")
                                        .font(.caption)
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppConstants.Colors.surface)
                            } else if let token = fcmToken {
                                // Token exists - show it
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .foregroundColor(.green)
                                        
                                        Text("FCM Token")
                                            .font(.body)
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            copyTokenToClipboard(token)
                                        }) {
                                            Image(systemName: showingTokenCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                                .foregroundColor(showingTokenCopied ? .green : AppConstants.Colors.accent)
                                        }
                                    }
                                    
                                    Text(token)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                        .lineLimit(3)
                                        .truncationMode(.middle)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppConstants.Colors.surface)
                            } else if notificationStatus == .authorized {
                                // No token but authorized - offer to register
                                Button(action: {
                                    registerForNotifications()
                                }) {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                            .foregroundColor(AppConstants.Colors.accent)
                                        
                                        Text("Register for Push Notifications")
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        if isRequestingPermission {
                                            ProgressView()
                                                .tint(AppConstants.Colors.accent)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppConstants.Colors.textSecondary)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(AppConstants.Colors.surface)
                                }
                                .disabled(isRequestingPermission)
                            } else {
                                // Not authorized - prompt for permission
                                Button(action: {
                                    requestNotificationPermission()
                                }) {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                            .foregroundColor(AppConstants.Colors.accent)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Enable Push Notifications")
                                                .foregroundColor(AppConstants.Colors.textPrimary)
                                            
                                            Text("Get notified about new messages")
                                                .font(.caption)
                                                .foregroundColor(AppConstants.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if isRequestingPermission {
                                            ProgressView()
                                                .tint(AppConstants.Colors.accent)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppConstants.Colors.textSecondary)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(AppConstants.Colors.surface)
                                }
                                .disabled(isRequestingPermission)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    Divider()
                        .background(AppConstants.Colors.border)
                    
                    // Account Actions Section
                    VStack(spacing: 0) {
                        // Delete Account Button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                
                                Text("Delete Account")
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                if isDeleting {
                                    ProgressView()
                                        .tint(.red)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppConstants.Colors.surface)
                        }
                        .disabled(isDeleting)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFCMToken()
            await checkNotificationStatus()
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .toolbarBackground(AppConstants.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Computed Properties
    
    private var notificationStatusIcon: String {
        switch notificationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined, .provisional, .ephemeral:
            return "bell.slash"
        @unknown default:
            return "bell.slash"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined, .provisional, .ephemeral:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied - Enable in Settings"
        case .notDetermined:
            return "Not configured"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Functions
    
    private func loadFCMToken() async {
        guard let userId = appState.currentUser?.id else {
            isLoadingToken = false
            return
        }
        
        do {
            // Fetch fresh user data from Firestore
            let user = try await appState.userService.fetchUser(userId: userId)
            await MainActor.run {
                self.fcmToken = user.fcmToken
                self.isLoadingToken = false
            }
        } catch {
            print("❌ Error loading FCM token: \(error)")
            await MainActor.run {
                self.isLoadingToken = false
            }
        }
    }
    
    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.notificationStatus = settings.authorizationStatus
        }
    }
    
    private func requestNotificationPermission() {
        isRequestingPermission = true
        
        Task { @MainActor in
            await appState.requestNotificationPermission()
            await checkNotificationStatus()
            
            // Wait a moment for the token to be registered
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await loadFCMToken()
            
            isRequestingPermission = false
        }
    }
    
    private func registerForNotifications() {
        isRequestingPermission = true
        
        Task { @MainActor in
            // Request APNS registration which will trigger FCM token generation
            #if os(iOS)
            UIApplication.shared.registerForRemoteNotifications()
            #endif
            
            // Wait a moment for the token to be registered
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await loadFCMToken()
            
            isRequestingPermission = false
        }
    }
    
    private func copyTokenToClipboard(_ token: String) {
        #if os(iOS)
        UIPasteboard.general.string = token
        showingTokenCopied = true
        
        // Reset the checkmark after 2 seconds
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showingTokenCopied = false
        }
        #endif
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        Task { @MainActor in
            do {
                try await appState.authService.deleteAccount()
                // User will be automatically logged out via auth state listener
                dismiss()
            } catch {
                isDeleting = false
                deleteErrorMessage = error.localizedDescription
                showingDeleteError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .environmentObject(AppState())
    }
}

