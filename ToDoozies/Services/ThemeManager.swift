//
//  ThemeManager.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI
import Observation

@Observable
final class ThemeManager {
    // MARK: - Theme Selection
    private(set) var selectedTheme: AppTheme = .system
    private(set) var effectiveColorScheme: ColorScheme?

    init() {
        loadThemePreference()
    }

    // MARK: - Theme Management

    func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
        saveThemePreference()
        updateEffectiveColorScheme()
    }

    private func updateEffectiveColorScheme() {
        switch selectedTheme {
        case .system:
            effectiveColorScheme = nil
        case .light:
            effectiveColorScheme = .light
        case .dark:
            effectiveColorScheme = .dark
        }
    }

    // MARK: - Persistence

    private func loadThemePreference() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedColorScheme") ?? "system"
        selectedTheme = AppTheme(rawValue: savedTheme) ?? .system
        updateEffectiveColorScheme()
    }

    private func saveThemePreference() {
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedColorScheme")
    }

    // MARK: - Theme Info

    var currentThemeDisplayName: String {
        selectedTheme.displayName
    }

    func themeDescription(for environment: EnvironmentValues) -> String {
        switch selectedTheme {
        case .system:
            let systemScheme = environment.colorScheme
            return "System (\(systemScheme == .dark ? "Dark" : "Light"))"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

// MARK: - AppTheme Enum

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "gearshape"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    var description: String {
        switch self {
        case .system: return "Follow system setting"
        case .light: return "Always use light appearance"
        case .dark: return "Always use dark appearance"
        }
    }
}