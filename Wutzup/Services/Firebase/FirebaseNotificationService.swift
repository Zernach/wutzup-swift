//
//  FirebaseNotificationService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth

class FirebaseNotificationService: NSObject, NotificationService {
    private let db = Firestore.firestore()
    
    // Closures set by AppState
    var onNotificationTap: ((String) -> Void)?
    // 🔥 FIX: Callback for FCM token updates (handled by AppState to avoid race condition)
    var onFCMTokenReceived: ((String) -> Void)?
    
    override init() {
        super.init()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() async throws -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        }
        
        return settings.authorizationStatus == .authorized
    }
    
    func registerDeviceToken(_ token: Data) async throws {
        // Firebase Messaging will handle this automatically
        Messaging.messaging().apnsToken = token
        
        // Log the token for debugging
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    func updateFCMToken(userId: String, token: String) async throws {
        try await db.collection("users")
            .document(userId)
            .updateData(["fcmToken": token])
    }
}

// MARK: - MessagingDelegate
extension FirebaseNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            return
        }
        
        
        // 🔥 FIX: Route token through AppState to handle auth race condition
        // AppState will save the token when auth is ready
        onFCMTokenReceived?(fcmToken)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        // Extract conversation ID from notification data
        let userInfo = response.notification.request.content.userInfo
        
        if let conversationId = userInfo["conversationId"] as? String {
            
            // Notify AppState to navigate to conversation
            DispatchQueue.main.async {
                self.onNotificationTap?(conversationId)
            }
        } else {
        }
        
        completionHandler()
    }
}

