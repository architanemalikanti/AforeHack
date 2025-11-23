//
//  AppDelegate.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/20/25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Register for Remote Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ Device token received: \(tokenString)")

        // Send token to backend
        sendDeviceTokenToBackend(token: tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Send Device Token to Backend
    private func sendDeviceTokenToBackend(token: String) {
        guard let userID = UserDefaults.standard.string(forKey: "glow_user_id"),
              let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No user_id or access_token found - will retry when available")
            // Store token locally to send later when user logs in
            UserDefaults.standard.set(token, forKey: "pending_device_token")
            return
        }

        // Call NetworkManager to send token to backend
        NetworkManager.shared.registerDeviceToken(
            userID: userID,
            deviceToken: token,
            accessToken: accessToken
        ) { response in
            if let response = response, response.status == "success" {
                print("✅ Device token registered with backend")
                // Clear pending token
                UserDefaults.standard.removeObject(forKey: "pending_device_token")
            } else {
                print("❌ Failed to register device token with backend")
            }
        }
    }

    // MARK: - Handle Notifications When App is in Foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Handle Notification Tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification types
        if let notificationType = userInfo["type"] as? String {
            print("📬 Notification tapped: \(notificationType)")

            switch notificationType {
            case "follow_request":
                // Navigate to feed view
                if let requesterID = userInfo["requester_id"] as? String {
                    print("👤 Follow request from: \(requesterID)")
                    navigateToFeed()
                }
            case "new_era":
                // Navigate to feed view
                if let userID = userInfo["user_id"] as? String {
                    print("📝 New era from: \(userID)")
                    navigateToFeed()
                }
            default:
                print("⚠️ Unknown notification type: \(notificationType)")
                // Still navigate to feed for unknown types
                navigateToFeed()
            }
        } else {
            // No type specified, navigate to feed anyway
            navigateToFeed()
        }

        completionHandler()
    }

    // MARK: - Navigate to Feed
    private func navigateToFeed() {
        // Post notification to switch to feed tab
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToFeed"), object: nil)
        print("🚀 Navigating to Feed view")
    }
}
