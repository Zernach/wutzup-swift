//
//  AccountView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import UserNotifications
import PhotosUI

/// Supported languages for translation features
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case arabic = "ar"
    case russian = "ru"
    case hindi = "hi"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .arabic: return "Arabic"
        case .russian: return "Russian"
        case .hindi: return "Hindi"
        }
    }
}

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
    @State private var personalityText: String = ""
    @State private var isSavingPersonality = false
    @State private var showingPersonalitySaved = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @State private var showingUploadError = false
    @State private var primaryLanguageCode: String = ""
    @State private var learningLanguageCode: String = ""
    @State private var isSavingLanguages = false
    
    var presenceService: PresenceService? = nil
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // User Info Section
                    VStack(spacing: 16) {
                        // Profile Avatar with online status - tap to change
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            UserProfileImageView(
                                user: appState.currentUser,
                                size: 100,
                                showOnlineStatus: true,
                                presenceService: presenceService
                            )
                            .overlay(
                                Group {
                                    if isUploadingImage {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                            
                                            ProgressView()
                                                .tint(.white)
                                        }
                                    }
                                }
                            )
                        }
                        .disabled(isUploadingImage)
                        
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
                    
                    // Language Preferences Section
                    VStack(spacing: 0) {
                        // Section Header
                        HStack {
                            Text("Languages")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        VStack(spacing: 12) {
                            // Primary Language Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Primary Language", selection: $primaryLanguageCode) {
                                    ForEach(SupportedLanguage.allCases, id: \.rawValue) { lang in
                                        Text(lang.displayName).tag(lang.rawValue)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .tint(AppConstants.Colors.textPrimary)
                                .onChange(of: primaryLanguageCode) { _, _ in
                                    saveLanguages()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppConstants.Colors.surface)

                            // Learning Language Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Learning Language", selection: $learningLanguageCode) {
                                    ForEach(SupportedLanguage.allCases, id: \.rawValue) { lang in
                                        Text(lang.displayName).tag(lang.rawValue)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .tint(AppConstants.Colors.textPrimary)
                                .onChange(of: learningLanguageCode) { _, _ in
                                    saveLanguages()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppConstants.Colors.surface)

                            if isSavingLanguages {
                                HStack {
                                    ProgressView()
                                        .tint(AppConstants.Colors.textSecondary)
                                    Text("Saving languages...")
                                        .font(.caption)
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.bottom, 20)
                    }

                    Divider()
                        .background(AppConstants.Colors.border)

                    // Personality Section
                    VStack(spacing: 0) {
                        // Section Header
                        HStack {
                            Text("Personality")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Describe your personality")
                                    .font(.body)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                                
                                Text("This helps the AI generate responses that match your communication style")
                                    .font(.caption)
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                
                                TextEditor(text: $personalityText)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(AppConstants.Colors.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppConstants.Colors.border, lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                                
                                HStack {
                                    Spacer()
                                    
                                    if showingPersonalitySaved {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Saved")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    Button(action: {
                                        savePersonality()
                                    }) {
                                        if isSavingPersonality {
                                            ProgressView()
                                                .tint(AppConstants.Colors.textPrimary)
                                        } else {
                                            Text("Save")
                                                .font(.body.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                                .background(AppConstants.Colors.accent)
                                                .cornerRadius(8)
                                        }
                                    }
                                    .disabled(isSavingPersonality)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppConstants.Colors.surface)
                        }
                        .padding(.bottom, 20)
                    }
                    
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
            loadPersonality()
            initializeLanguages()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await handlePhotoSelection(newItem)
            }
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
        .alert("Upload Error", isPresented: $showingUploadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uploadError ?? "Failed to upload image")
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
    
    private func loadPersonality() {
        personalityText = appState.currentUser?.personality ?? ""
    }
    
    private func savePersonality() {
        guard let userId = appState.currentUser?.id else { return }
        
        isSavingPersonality = true
        
        Task { @MainActor in
            do {
                let trimmedPersonality = personalityText.trimmingCharacters(in: .whitespacesAndNewlines)
                let personalityToSave = trimmedPersonality.isEmpty ? nil : trimmedPersonality
                
                try await appState.userService.updatePersonality(
                    userId: userId,
                    personality: personalityToSave
                )
                
                // Update current user in app state
                if var updatedUser = appState.currentUser {
                    updatedUser.personality = personalityToSave
                    appState.currentUser = updatedUser
                }
                
                isSavingPersonality = false
                showingPersonalitySaved = true
                
                // Hide the "Saved" message after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showingPersonalitySaved = false
                
            } catch {
                isSavingPersonality = false
            }
        }
    }
    
    private func initializeLanguages() {
        // Default primary to device language if not set on user
        if let userPrimary = appState.currentUser?.primaryLanguageCode, !userPrimary.isEmpty {
            primaryLanguageCode = userPrimary
        } else {
            if let deviceCode = Locale.current.language.languageCode?.identifier {
                primaryLanguageCode = deviceCode
            } else {
                primaryLanguageCode = SupportedLanguage.english.rawValue
            }
        }
        // Default learning language to Spanish if not set
        if let userLearning = appState.currentUser?.learningLanguageCode, !userLearning.isEmpty {
            learningLanguageCode = userLearning
        } else {
            learningLanguageCode = SupportedLanguage.spanish.rawValue
        }
    }
    
    private func saveLanguages() {
        guard let userId = appState.currentUser?.id else { return }
        isSavingLanguages = true
        Task { @MainActor in
            do {
                try await appState.userService.updateLanguages(
                    userId: userId,
                    primaryLanguageCode: primaryLanguageCode,
                    learningLanguageCode: learningLanguageCode
                )
                if var updatedUser = appState.currentUser {
                    updatedUser.primaryLanguageCode = primaryLanguageCode
                    updatedUser.learningLanguageCode = learningLanguageCode
                    appState.currentUser = updatedUser
                }
                isSavingLanguages = false
            } catch {
                isSavingLanguages = false
            }
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        guard let userId = appState.currentUser?.id else { return }
        
        await MainActor.run {
            isUploadingImage = true
        }
        
        do {
            // Load image data from PhotosPicker
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(
                    domain: "AccountView",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"]
                )
            }
            
            // Convert to UIImage
            guard let uiImage = UIImage(data: imageData) else {
                throw NSError(
                    domain: "AccountView",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid image format"]
                )
            }
            
            // Upload to Firebase Storage
            guard let userService = appState.userService as? FirebaseUserService else {
                throw NSError(
                    domain: "AccountView",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "User service not available"]
                )
            }
            
            let imageUrl = try await userService.uploadProfileImage(userId: userId, image: uiImage)
            
            // Update Firestore with new image URL
            try await appState.userService.updateProfileImageUrl(userId: userId, imageUrl: imageUrl)
            
            // Update current user in app state
            await MainActor.run {
                if var updatedUser = appState.currentUser {
                    updatedUser.profileImageUrl = imageUrl
                    appState.currentUser = updatedUser
                }
                
                isUploadingImage = false
                selectedPhotoItem = nil
            }
            
        } catch {
            await MainActor.run {
                uploadError = error.localizedDescription
                showingUploadError = true
                isUploadingImage = false
                selectedPhotoItem = nil
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

