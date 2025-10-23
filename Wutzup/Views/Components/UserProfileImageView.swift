//
//  UserProfileImageView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

/// A reusable component that displays a user's profile image with an online status indicator
struct UserProfileImageView: View {
    let user: User?
    let size: CGFloat
    let showOnlineStatus: Bool
    let presenceService: PresenceService?
    
    @State private var isOnline: Bool = false
    @State private var presenceTask: Task<Void, Never>?
    
    private let offlineColor = Color.red
    
    /// Creates a user profile image view
    /// - Parameters:
    ///   - user: The user whose profile image to display
    ///   - size: The diameter of the circular profile image
    ///   - showOnlineStatus: Whether to show the online/offline status indicator (default: true)
    ///   - presenceService: The service to observe user presence (required if showOnlineStatus is true)
    init(
        user: User?,
        size: CGFloat = AppConstants.Sizes.profileImageSize,
        showOnlineStatus: Bool = true,
        presenceService: PresenceService? = nil
    ) {
        self.user = user
        self.size = size
        self.showOnlineStatus = showOnlineStatus
        self.presenceService = presenceService
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Profile Image or Placeholder
            Group {
                if let profileImageUrl = user?.profileImageUrl,
                   let url = URL(string: profileImageUrl) {
                    // Use cached async image for better performance
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        placeholderImage
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            
            // Online Status Indicator
            if showOnlineStatus {
                Circle()
                    .fill(isOnline ? AppConstants.Colors.brightGreen : offlineColor)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        Circle()
                            .stroke(AppConstants.Colors.background, lineWidth: size * 0.06)
                    )
                    .offset(x: size * 0.04, y: size * 0.04)
            }
        }
        .task(id: user?.id) {
            await observePresence()
        }
        .onDisappear {
            presenceTask?.cancel()
        }
    }
    
    @ViewBuilder
    private var placeholderImage: some View {
        ZStack {
            Circle()
                .fill(AppConstants.Colors.accent.opacity(0.2))
            
            if let displayName = user?.displayName {
                Text(initials(from: displayName))
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(AppConstants.Colors.accent)
            } else {
                Image(systemName: AppConstants.defaultProfileImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(AppConstants.Colors.mutedIcon)
            }
        }
    }
    
    private func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }
    
    private func observePresence() async {
        guard showOnlineStatus,
              let userId = user?.id,
              let presenceService = presenceService else {
            return
        }
        
        presenceTask?.cancel()
        
        presenceTask = Task {
            for await presence in presenceService.observePresence(userId: userId) {
                guard !Task.isCancelled else { break }
                
                await MainActor.run {
                    isOnline = (presence.status == .online)
                }
            }
        }
    }
}

#Preview("Online User") {
    VStack(spacing: 20) {
        UserProfileImageView(
            user: User(
                id: "1",
                email: "alice@test.com",
                displayName: "Alice Johnson",
                profileImageUrl: nil
            ),
            size: 60,
            showOnlineStatus: true,
            presenceService: PreviewPresenceService(isOnline: true)
        )
        
        Text("Alice Johnson (Online)")
            .foregroundColor(.white)
    }
    .padding()
    .background(AppConstants.Colors.background)
}

#Preview("Offline User") {
    VStack(spacing: 20) {
        UserProfileImageView(
            user: User(
                id: "2",
                email: "bob@test.com",
                displayName: "Bob Smith",
                profileImageUrl: nil
            ),
            size: 60,
            showOnlineStatus: true,
            presenceService: PreviewPresenceService(isOnline: false)
        )
        
        Text("Bob Smith (Offline)")
            .foregroundColor(.white)
    }
    .padding()
    .background(AppConstants.Colors.background)
}

#Preview("Various Sizes") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            UserProfileImageView(
                user: User(id: "1", email: "user@test.com", displayName: "Small User"),
                size: 30,
                showOnlineStatus: true,
                presenceService: PreviewPresenceService(isOnline: true)
            )
            Text("30pt")
                .foregroundColor(.white)
        }
        
        HStack(spacing: 20) {
            UserProfileImageView(
                user: User(id: "2", email: "user@test.com", displayName: "Medium User"),
                size: 50,
                showOnlineStatus: true,
                presenceService: PreviewPresenceService(isOnline: true)
            )
            Text("50pt (Default)")
                .foregroundColor(.white)
        }
        
        HStack(spacing: 20) {
            UserProfileImageView(
                user: User(id: "3", email: "user@test.com", displayName: "Large User"),
                size: 80,
                showOnlineStatus: true,
                presenceService: PreviewPresenceService(isOnline: false)
            )
            Text("80pt")
                .foregroundColor(.white)
        }
        
        HStack(spacing: 20) {
            UserProfileImageView(
                user: User(id: "4", email: "user@test.com", displayName: "XL User"),
                size: 120,
                showOnlineStatus: true,
                presenceService: PreviewPresenceService(isOnline: true)
            )
            Text("120pt")
                .foregroundColor(.white)
        }
    }
    .padding()
    .background(AppConstants.Colors.background)
}

#Preview("Without Status Indicator") {
    VStack(spacing: 20) {
        UserProfileImageView(
            user: User(
                id: "1",
                email: "alice@test.com",
                displayName: "Alice Johnson",
                profileImageUrl: nil
            ),
            size: 60,
            showOnlineStatus: false,
            presenceService: nil
        )
        
        Text("No Status Indicator")
            .foregroundColor(.white)
    }
    .padding()
    .background(AppConstants.Colors.background)
}

// MARK: - Preview Helpers

private class PreviewPresenceService: PresenceService {
    let isOnline: Bool
    
    init(isOnline: Bool) {
        self.isOnline = isOnline
    }
    
    func setOnline(userId: String) async throws { }
    func setOffline(userId: String) async throws { }
    func setAway(userId: String) async throws { }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
            let presence = Presence(
                userId: userId,
                status: isOnline ? .online : .offline,
                lastSeen: Date(),
                typing: [:]
            )
            continuation.yield(presence)
            continuation.finish()
        }
    }
    
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws { }
    func observeTyping(conversationId: String) -> AsyncStream<[String: Bool]> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

