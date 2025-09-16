//
//  AppDelegate.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import UIKit
import CloudKit
import UserNotifications
import SwiftData

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Register for remote notifications
        registerForRemoteNotifications(application)

        // Configure UNUserNotificationCenter
        configureNotifications()

        return true
    }

    // MARK: - Remote Notifications

    private func registerForRemoteNotifications(_ application: UIApplication) {
        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for remote notifications")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // Handle CloudKit remote notifications when app is active
        guard UIApplication.shared.applicationState == .active else {
            return
        }

        // Check if this is a CloudKit notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            handleCloudKitNotification(notification)
        }
    }

    private func handleCloudKitNotification(_ notification: CKNotification) {
        switch notification.notificationType {
        case .database:
            if let databaseNotification = notification as? CKDatabaseNotification {
                handleDatabaseNotification(databaseNotification)
            }

        case .query:
            if let queryNotification = notification as? CKQueryNotification {
                handleQueryNotification(queryNotification)
            }

        case .recordZone:
            if let recordZoneNotification = notification as? CKRecordZoneNotification {
                handleRecordZoneNotification(recordZoneNotification)
            }

        case .readNotification:
            print("Received read notification")

        @unknown default:
            print("Unknown CloudKit notification type")
        }
    }

    private func handleDatabaseNotification(_ notification: CKDatabaseNotification) {
        print("Received database notification - data changed in CloudKit")
        // CloudKit data changed - SwiftData will handle sync automatically when app is active
    }

    private func handleQueryNotification(_ notification: CKQueryNotification) {
        print("Received query notification")
        // Specific record type changes - SwiftData will handle sync automatically when app is active
    }

    private func handleRecordZoneNotification(_ notification: CKRecordZoneNotification) {
        print("Received record zone notification")
        // Zone-specific changes - SwiftData will handle sync automatically when app is active
    }


    // MARK: - Local Notifications

    private func configureNotifications() {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification types
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "task_reminder":
                handleTaskReminderNotification(userInfo)
            case "habit_reminder":
                handleHabitReminderNotification(userInfo)
            case "sync_update":
                handleSyncUpdateNotification(userInfo)
            default:
                break
            }
        }

        completionHandler()
    }

    private func handleTaskReminderNotification(_ userInfo: [AnyHashable: Any]) {
        // Navigate to specific task
        if let taskId = userInfo["taskId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToTask,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
    }

    private func handleHabitReminderNotification(_ userInfo: [AnyHashable: Any]) {
        // Navigate to specific habit
        if let habitId = userInfo["habitId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToHabit,
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
    }

    private func handleSyncUpdateNotification(_ userInfo: [AnyHashable: Any]) {
        // Show sync status or trigger manual sync
        NotificationCenter.default.post(name: .showSyncStatus, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToTask = Notification.Name("navigateToTask")
    static let navigateToHabit = Notification.Name("navigateToHabit")
    static let showSyncStatus = Notification.Name("showSyncStatus")
}