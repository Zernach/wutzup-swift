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
    let modelContainer: ModelContainer
    @StateObject private var appState: AppState
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
        let container: ModelContainer
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
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Initialize properties
        self.modelContainer = container
        self._appState = StateObject(wrappedValue: AppState(modelContainer: container))
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
        
        // Check if launched from notification
        if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotificationPayload(notification)
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        
        // Pass token to notification service
        Task {
            do {
                try await appState?.notificationService.registerDeviceToken(deviceToken)
            } catch {
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
    }
    
    // Handle remote notification when app is running
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        
        handleNotificationPayload(userInfo)
        
        // Tell system we successfully fetched new data
        completionHandler(.newData)
    }
    
    private func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        // Extract conversation ID from notification
        if let conversationId = userInfo["conversationId"] as? String {
            
            // Navigate to conversation when app becomes active
            Task { @MainActor in
                appState?.handleNotificationTap(conversationId: conversationId)
            }
        }
    }
}
