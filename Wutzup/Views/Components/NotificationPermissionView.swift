//
//  NotificationPermissionView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Permission card
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppConstants.Colors.accent, AppConstants.Colors.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 8)
                
                VStack(spacing: 12) {
                    Text("Stay Connected")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Get notified when you receive new messages")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Benefits list
                VStack(alignment: .leading, spacing: 12) {
                    PermissionBenefitRow(
                        icon: "message.fill",
                        text: "Never miss important messages"
                    )
                    PermissionBenefitRow(
                        icon: "clock.fill",
                        text: "Respond faster to your friends"
                    )
                    PermissionBenefitRow(
                        icon: "shield.fill",
                        text: "You can change this anytime in Settings"
                    )
                }
                .padding(.horizontal, 24)
                
                // Buttons
                VStack(spacing: 12) {
                    // Allow button
                    Button {
                        Task {
                            await appState.requestNotificationPermission()
                        }
                    } label: {
                        Text("Allow Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppConstants.Colors.accent)
                            .cornerRadius(12)
                    }
                    
                    // Not now button
                    Button {
                        appState.showNotificationPermissionPrompt = false
                    } label: {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 350)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct PermissionBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.accent)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(AppState())
}

