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
        Group {
            if appState.isLoading {
                ProgressView("Loading...")
            } else if appState.isAuthenticated {
                ChatListView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

