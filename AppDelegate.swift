//
//  AppDelegate.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/20/25.
//

import UIKit
import UserNotifications
import FirebaseCore

extension Notification.Name {
    static let didReceiveAPNSToken = Notification.Name("didReceiveAPNSToken")
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    static var shared: AppDelegate!

    override init() {
        super.init()
        AppDelegate.shared = self
        print("🏗️ AppDelegate initialized")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🔥🔥🔥 APPDELEGATE IS RUNNING - YOU SHOULD SEE THIS 🔥🔥🔥")

        // Configure Firebase
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")

        // CRITICAL: Set notification delegate - this makes AppDelegate receive callbacks
        UNUserNotificationCenter.current().delegate = self
        print("✅ Set UNUserNotificationCenter.current().delegate = self")

        // Don't request permission here - let profile page do it after login
        // This keeps AppDelegate as the iOS callback handler

        print("🔥🔥🔥 FINISHED APPDELEGATE SETUP 🔥🔥🔥")
        return true
    }

    // MARK: - Ask permission + register (single source of truth)
    private func requestNotificationAuthorizationAndRegister() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                print("🔔 Notifications status: notDetermined → requesting authorization")
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("❌ Error requesting notification permission: \(error.localizedDescription)")
                    }
                    print(granted ? "✅ User granted notification permission" : "❌ User denied notification permission")

                    // Register for remote notifications on main thread if granted
                    if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                            print("🚀 Called registerForRemoteNotifications from AppDelegate (fresh grant)")
                        }
                    }
                }

            case .authorized, .provisional:
                print("🔔 Notifications status: authorized/provisional → registering for remote notifications")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("🚀 Called registerForRemoteNotifications from AppDelegate (already authorized)")
                }

            case .denied:
                print("❌ Notifications status: denied (user can enable in Settings)")

            case .ephemeral:
                // App Clips / temporary authorization
                print("🔔 Notifications status: ephemeral → registering")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("🚀 Called registerForRemoteNotifications from AppDelegate (ephemeral)")
                }

            @unknown default:
                print("❓ Unknown notification authorization status")
            }
        }
    }

    // MARK: - Extra safety: try again when app becomes active (harmless if already registered)
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("✨✨✨ APPDELEGATE METHOD CALLED: applicationDidBecomeActive ✨✨✨")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let canRegister = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral

            if canRegister && !UIApplication.shared.isRegisteredForRemoteNotifications {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("🚀 Re-called registerForRemoteNotifications from AppDelegate (became active)")
                }
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("✨✨✨ APPDELEGATE METHOD CALLED: applicationWillResignActive ✨✨✨")
    }

    // MARK: - Register for Remote Notifications (APNS callbacks)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("🎉🎉🎉 SUCCESS! DEVICE TOKEN CALLBACK WAS CALLED! 🎉🎉🎉")

        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ Device token received from iOS: \(tokenString)")
        print("🔑 Token length: \(tokenString.count) characters")

        // Broadcast to NotificationManager and rest of app
        NotificationCenter.default.post(
            name: .didReceiveAPNSToken,
            object: tokenString
        )
        print("📢 Broadcasted token via NotificationCenter")

        // Also send directly from here as backup
        sendDeviceTokenToBackend(token: tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("💥💥💥 FAILURE! ERROR CALLBACK WAS CALLED! 💥💥💥")
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        print("❌ Full error: \(error)")

        // Print more specific error info
        let nsError = error as NSError
        print("❌ Error domain: \(nsError.domain)")
        print("❌ Error code: \(nsError.code)")
        print("❌ Error userInfo: \(nsError.userInfo)")

        // Check specific error codes
        if nsError.code == 3010 {
            print("❌ ERROR 3010: No valid 'aps-environment' entitlement - provisioning profile issue!")
        }

        // Post notification so SwiftUI can handle it
        NotificationCenter.default.post(
            name: NSNotification.Name("DeviceTokenFailed"),
            object: nil,
            userInfo: ["error": error]
        )
        print("📢 Posted DeviceTokenFailed notification to NotificationCenter")
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
        print("📬📬📬 APPDELEGATE METHOD CALLED: willPresent notification 📬📬📬")
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
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
