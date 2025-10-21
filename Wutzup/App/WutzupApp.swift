//
//  WutzupApp.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData
import FirebaseCore
import UserNotifications

@main
struct WutzupApp: App {
    @StateObject private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
                .onAppear {
                    // Set the appState in the app delegate for notification handling
                    appDelegate.appState = appState
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - AppDelegate for Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    weak var appState: AppState?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register for remote notifications
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ APNs Device Token registered")
        
        // Pass token to notification service
        Task {
            do {
                try await appState?.notificationService.registerDeviceToken(deviceToken)
            } catch {
                print("❌ Error registering device token: \(error)")
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}
