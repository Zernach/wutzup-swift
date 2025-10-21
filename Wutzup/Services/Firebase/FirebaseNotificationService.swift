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

class FirebaseNotificationService: NSObject, NotificationService {
    private let db = Firestore.firestore()
    
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
        // Convert token to string
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token: \(tokenString)")
        
        // Firebase Messaging will handle this automatically
        Messaging.messaging().apnsToken = token
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
        guard let fcmToken = fcmToken else { return }
        
        print("FCM token: \(fcmToken)")
        
        // Update token in Firestore
        Task {
            if let userId = Auth.auth().currentUser?.uid {
                try? await updateFCMToken(userId: userId, token: fcmToken)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        // TODO: Navigate to conversation from notification data
        print("Notification tapped: \(userInfo)")
        
        completionHandler()
    }
}

// Import FirebaseAuth for the extension
import FirebaseAuth

