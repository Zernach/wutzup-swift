//
//  WutzupApp.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct WutzupApp: App {
    @StateObject private var appState = AppState()
    
    let modelContainer: ModelContainer
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Firestore offline persistence
        FirebaseConfig.configureFirestore()
        
        // Configure Firebase emulators in debug mode
        #if DEBUG
        FirebaseConfig.configureEmulators()
        #endif
        
        // Initialize SwiftData container
        do {
            let schema = Schema([
                MessageModel.self,
                ConversationModel.self,
                UserModel.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .tint(AppConstants.Colors.accent)
        }
        .modelContainer(modelContainer)
    }
}
