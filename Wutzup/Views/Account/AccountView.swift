//
//  AccountView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // User Info Section
                VStack(spacing: 16) {
                    // Profile Avatar
                    Circle()
                        .fill(AppConstants.Colors.accent.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(AppConstants.Colors.accent)
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
                
                Spacer()
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private var initials: String {
        guard let displayName = appState.currentUser?.displayName else {
            return "U"
        }
        
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        
        return "U"
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

