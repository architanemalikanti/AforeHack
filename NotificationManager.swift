//
//  NotificationManager.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/20/25.
//

import UIKit
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Request Notification Permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        // Check if already authorized
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                print("✅ Already authorized for notifications")
                completion(true)
                return
            } else if settings.authorizationStatus == .denied {
                print("❌ User previously denied notifications")
                completion(false)
                return
            }

            // Request permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("❌ Error requesting notification permission: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if granted {
                    print("✅ User granted notification permission")
                    // Register for remote notifications on main thread
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    completion(true)
                } else {
                    print("❌ User denied notification permission")
                    completion(false)
                }
            }
        }
    }

    // MARK: - Check if Should Request Permission
    func shouldRequestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Only request if not determined yet
            let shouldRequest = settings.authorizationStatus == .notDetermined
            completion(shouldRequest)
        }
    }
}
