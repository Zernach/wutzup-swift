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
    
    // Closure to handle notification taps (set by AppState)
    var onNotificationTap: ((String) -> Void)?
    
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
        print("📱 APNs Token: \(tokenString)")
    }
    
    func updateFCMToken(userId: String, token: String) async throws {
        print("💾 Saving FCM token for user: \(userId)")
        try await db.collection("users")
            .document(userId)
            .updateData(["fcmToken": token])
        print("✅ FCM token saved successfully")
    }
}

// MARK: - MessagingDelegate
extension FirebaseNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("⚠️ No FCM token received")
            return
        }
        
        print("🔑 FCM Token received: \(fcmToken.prefix(20))...")
        
        // Update token in Firestore
        Task {
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    try await updateFCMToken(userId: userId, token: fcmToken)
                } catch {
                    print("❌ Failed to save FCM token: \(error)")
                }
            } else {
                print("⚠️ No authenticated user to save FCM token")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 Notification received in foreground")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 User tapped notification")
        
        // Extract conversation ID from notification data
        let userInfo = response.notification.request.content.userInfo
        
        if let conversationId = userInfo["conversationId"] as? String {
            print("📱 Opening conversation: \(conversationId)")
            
            // Notify AppState to navigate to conversation
            DispatchQueue.main.async {
                self.onNotificationTap?(conversationId)
            }
        } else {
            print("⚠️ No conversationId in notification payload")
        }
        
        completionHandler()
    }
}

