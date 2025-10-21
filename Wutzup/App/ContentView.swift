//
//  ContentView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            Group {
                if appState.isLoading {
                    ProgressView("Loading...")
                        .tint(AppConstants.Colors.accent)
                } else if appState.isAuthenticated {
                    ChatListView(viewModel: appState.chatListViewModel)
                } else {
                    LoginView(viewModel: appState.makeAuthenticationViewModel())
                }
            }
        }
    }
}

#Preview {
    let previewState = AppState()
    return ContentView()
        .environmentObject(previewState)
}
