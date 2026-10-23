import Foundation
import UserNotifications

final class ArchlifeNotificationService: NSObject, NotificationService, UNUserNotificationCenterDelegate {
    var onNotificationTap: ((String) -> Void)?
    var onDeviceTokenReceived: ((String) -> Void)?
    var deviceToken: String? { UserDefaults.standard.string(forKey: "wutzup.apns.deviceToken") }
    override init() { super.init(); UNUserNotificationCenter.current().delegate = self }
    func requestPermission() async throws -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined { return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
        return settings.authorizationStatus == .authorized
    }
    func registerDeviceToken(_ token: Data) async throws {
        let value = token.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(value, forKey: "wutzup.apns.deviceToken")
        onDeviceTokenReceived?(value)
    }
    func updateDeviceToken(userId: String, token: String) async throws {
        try ArchlifeWutzupAPI.requireActor(userId)
        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif
        let _: WutzupOK = try await ArchlifeWutzupAPI.data("device_register", ["token": token, "environment": environment])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["conversationId"] as? String { DispatchQueue.main.async { self.onNotificationTap?(id) } }
        completionHandler()
    }
}
