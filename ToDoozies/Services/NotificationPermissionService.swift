//
//  NotificationPermissionService.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import Foundation
import UserNotifications
import SwiftUI
import UIKit
import Observation

@MainActor
@Observable
final class NotificationPermissionService {
    // MARK: - Properties
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isLoading: Bool = false
    private(set) var lastCheckDate: Date?

    init() {}

    // MARK: - Permission Management

    /// Checks the current notification authorization status
    func checkAuthorizationStatus() async {
        isLoading = true
        defer { isLoading = false }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        lastCheckDate = Date()
    }

    /// Requests notification permissions from the user
    func requestPermission() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )

            // Update status after request
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Opens the system settings for this app
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - Status Information

    var statusDisplayName: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Set"
        case .denied:
            return "Denied"
        case .authorized, .provisional:
            return "Allowed"
        case .ephemeral:
            return "Temporary"
        @unknown default:
            return "Unknown"
        }
    }

    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Tap to enable notifications for task reminders and habit tracking"
        case .denied:
            return "Notifications are disabled. Tap to open Settings and enable them"
        case .authorized:
            return "Notifications are enabled for task reminders and habit tracking"
        case .provisional:
            return "Notifications are enabled quietly"
        case .ephemeral:
            return "Temporary notification access"
        @unknown default:
            return "Unknown notification status"
        }
    }

    var statusSystemImage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "bell.badge"
        case .denied:
            return "bell.slash"
        case .authorized, .provisional:
            return "bell"
        case .ephemeral:
            return "bell.badge"
        @unknown default:
            return "bell.badge.questionmark"
        }
    }

    var statusColor: Color {
        switch authorizationStatus {
        case .notDetermined:
            return .orange
        case .denied:
            return .red
        case .authorized, .provisional:
            return .green
        case .ephemeral:
            return .blue
        @unknown default:
            return .gray
        }
    }

    var canRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }

    var needsSettingsAccess: Bool {
        authorizationStatus == .denied
    }

    // MARK: - Notification Settings Info

    func getDetailedSettings() async -> UNNotificationSettings {
        return await UNUserNotificationCenter.current().notificationSettings()
    }

    func getSettingsInfo() async -> NotificationSettingsInfo {
        let settings = await getDetailedSettings()

        return NotificationSettingsInfo(
            authorizationStatus: settings.authorizationStatus,
            alertSetting: settings.alertSetting,
            badgeSetting: settings.badgeSetting,
            soundSetting: settings.soundSetting,
            criticalAlertSetting: settings.criticalAlertSetting,
            timeSensitiveSetting: settings.timeSensitiveSetting,
            notificationCenterSetting: settings.notificationCenterSetting,
            lockScreenSetting: settings.lockScreenSetting,
            carPlaySetting: settings.carPlaySetting
        )
    }
}

// MARK: - NotificationSettingsInfo

struct NotificationSettingsInfo {
    let authorizationStatus: UNAuthorizationStatus
    let alertSetting: UNNotificationSetting
    let badgeSetting: UNNotificationSetting
    let soundSetting: UNNotificationSetting
    let criticalAlertSetting: UNNotificationSetting
    let timeSensitiveSetting: UNNotificationSetting
    let notificationCenterSetting: UNNotificationSetting
    let lockScreenSetting: UNNotificationSetting
    let carPlaySetting: UNNotificationSetting

    var summary: String {
        var components: [String] = []

        if alertSetting == .enabled { components.append("Alerts") }
        if badgeSetting == .enabled { components.append("Badges") }
        if soundSetting == .enabled { components.append("Sounds") }
        if lockScreenSetting == .enabled { components.append("Lock Screen") }
        if notificationCenterSetting == .enabled { components.append("Notification Center") }

        return components.isEmpty ? "None enabled" : components.joined(separator: ", ")
    }
}

