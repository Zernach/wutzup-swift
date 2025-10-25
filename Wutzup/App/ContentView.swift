//
//  ContentView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            Group {
                if appState.isLoading {
                    LoadingView()
                } else if appState.isAuthenticated {
                    ChatListView(viewModel: appState.chatListViewModel)
                } else {
                    LoginView(viewModel: appState.makeAuthenticationViewModel())
                }
            }
            
            // Notification permission prompt overlay
            if appState.showNotificationPermissionPrompt {
                NotificationPermissionView()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.showNotificationPermissionPrompt)
            }
        }
    }
}

#Preview {
    // Create a minimal ModelContainer for preview
    let container = try! ModelContainer(for: UserModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let previewState = AppState(modelContainer: container)
    return ContentView()
        .environmentObject(previewState)
}
