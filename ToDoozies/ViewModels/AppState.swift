//
//  AppState.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - Core Data Collections
    var tasks: [Task] = []
    var habits: [Habit] = []
    var categories: [Category] = []

    // MARK: - UI State
    var selectedTab: AppTab = .today
    var isLoading: Bool = false
    var error: AppError?

    // MARK: - CloudKit Sync State
    var isSyncEnabled: Bool = false
    var lastSyncDate: Date?
    var syncStatus: SyncStatus = .unknown

    // MARK: - Offline State
    var offlineMode: OfflineMode = .online
    var showOfflineToast: Bool = false
    var pendingChangesCount: Int = 0

    // MARK: - Filters and Search
    var searchText: String = ""

    // MARK: - Accessibility State
    var isVoiceOverActive: Bool = false
    var currentDynamicTypeSize: DynamicTypeSize = .medium
    var shouldAnnounceCompletions: Bool = true
    var accessibilityAnnouncement: String = ""
    var preferredAccessibilityActions: [String] = []
    var selectedPriority: Priority?
    var selectedCategory: Category?
    var showOnlyIncomplete: Bool = false

    init() {}

    // MARK: - Computed Properties

    /// Tasks due today
    var todayTasks: [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate) && !task.isCompleted
        }
    }

    /// Overdue tasks
    var overdueTasks: [Task] {
        return tasks.filter { $0.isOverdue }
    }

    /// Tasks due tomorrow
    var tomorrowTasks: [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInTomorrow(dueDate) && !task.isCompleted
        }
    }

    /// All incomplete tasks
    var incompleteTasks: [Task] {
        return tasks.filter { !$0.isCompleted }
    }

    /// All completed tasks
    var completedTasks: [Task] {
        return tasks.filter { $0.isCompleted }
    }

    /// Active habits (those with recent activity)
    var activeHabits: [Habit] {
        return habits.filter { habit in
            // Consider a habit active if it has completions in the last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return habit.completionDates.contains { $0 >= thirtyDaysAgo }
        }
    }

    /// Today's recurring tasks (habits)
    var todayRecurringTasks: [Task] {
        return tasks.filter { task in
            task.isRecurring &&
            (task.isDueToday || task.recurrenceRule?.isValidOccurrence(date: Date()) == true)
        }
    }

    /// Progress for today's recurring tasks
    var dailyRecurringProgress: Double {
        let recurringTasks = todayRecurringTasks
        guard !recurringTasks.isEmpty else { return 0.0 }

        let completedCount = recurringTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(recurringTasks.count)
    }

    /// Filtered tasks based on current search and filter criteria
    var filteredTasks: [Task] {
        var filtered = tasks

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.taskDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply priority filter
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }

        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category?.id == category.id }
        }

        // Apply completion filter
        if showOnlyIncomplete {
            filtered = filtered.filter { !$0.isCompleted }
        }

        return filtered
    }

    // MARK: - Data Management

    func setTasks(_ tasks: [Task]) {
        self.tasks = tasks
    }

    func setHabits(_ habits: [Habit]) {
        self.habits = habits
    }

    func setCategories(_ categories: [Category]) {
        self.categories = categories
    }

    func addTask(_ task: Task) {
        tasks.append(task)
    }

    func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }

    func addHabit(_ habit: Habit) {
        habits.append(habit)
    }

    func removeHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }

    func addCategory(_ category: Category) {
        categories.append(category)
    }

    func removeCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
    }

    // MARK: - Error Handling

    func setError(_ error: AppError) {
        self.error = error
    }

    func clearError() {
        self.error = nil
    }

    // MARK: - Loading State

    func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }

    // MARK: - Accessibility Support

    /// Announces a message to VoiceOver users
    func announceToVoiceOver(_ message: String) {
        guard isVoiceOverActive && shouldAnnounceCompletions else { return }
        accessibilityAnnouncement = message
    }

    /// Checks if the current dynamic type size is considered large
    var isLargeDynamicType: Bool {
        return currentDynamicTypeSize >= .xLarge
    }

    /// Provides accessible description for current app state
    var accessibilityStatusDescription: String {
        var description = ""

        if incompleteTasks.count > 0 {
            description += "\(incompleteTasks.count) incomplete tasks. "
        }

        let incompleteHabits = activeHabits.filter { !$0.isCompletedToday }.count
        if incompleteHabits > 0 {
            description += "\(incompleteHabits) habits not completed today. "
        }

        if syncStatus == .syncing {
            description += "Syncing data. "
        } else if case .failed = syncStatus {
            description += "Sync failed, data saved locally. "
        }

        return description.isEmpty ? "All tasks and habits up to date" : description
    }

    /// Updates accessibility preferences based on user interaction patterns
    func updateAccessibilityPreferences() {
        // Update preferred actions based on usage patterns
        if isVoiceOverActive {
            preferredAccessibilityActions = ["Complete Task", "Edit Task", "View Details"]
        } else {
            preferredAccessibilityActions = []
        }
    }

    // MARK: - CloudKit Sync Management

    func setSyncStatus(_ status: SyncStatus) {
        self.syncStatus = status
        if status == .synced {
            self.lastSyncDate = Date()
        }
    }

    func setSyncEnabled(_ enabled: Bool) {
        self.isSyncEnabled = enabled
    }

    // MARK: - Offline Mode Management

    func setOfflineMode(_ mode: OfflineMode) {
        offlineMode = mode
        if mode == .offline && !showOfflineToast {
            showOfflineToast = true
        }
    }

    func incrementPendingChanges() {
        pendingChangesCount += 1
    }

    func clearPendingChanges() {
        pendingChangesCount = 0
    }

    func dismissOfflineToast() {
        showOfflineToast = false
    }

    var syncStatusMessage: String {
        switch syncStatus {
        case .unknown:
            return "Checking iCloud status..."
        case .syncing:
            return "Syncing with iCloud..."
        case .synced:
            if let lastSync = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            } else {
                return "Synced with iCloud"
            }
        case .failed(let error):
            return "Sync failed: \(error)"
        case .disabled:
            return "Local storage only - Sign in to iCloud to enable sync"
        }
    }
}

// MARK: - Supporting Types

enum AppTab: String, CaseIterable {
    case today = "today"
    case tasks = "tasks"
    case habits = "habits"
    case calendar = "calendar"
    case settings = "settings"

    var title: String {
        switch self {
        case .today: return "Today"
        case .tasks: return "Tasks"
        case .habits: return "Habits"
        case .calendar: return "Calendar"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .today: return "sun.max"
        case .tasks: return "list.bullet"
        case .habits: return "flame"
        case .calendar: return "calendar"
        case .settings: return "gear"
        }
    }
}

enum AppError: Error, LocalizedError {
    case dataLoadingFailed(String)
    case dataSavingFailed(String)
    case syncFailed(String)
    case networkError(String)
    case validationError(String)
    case cloudKitAccountError
    case cloudKitQuotaExceeded
    case cloudKitNetworkUnavailable
    case cloudKitUnknownError(String)

    var errorDescription: String? {
        switch self {
        case .dataLoadingFailed(let message):
            return "Failed to load data: \(message)"
        case .dataSavingFailed(let message):
            return "Failed to save data: \(message)"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .cloudKitAccountError:
            return "Please check your iCloud account settings and try again."
        case .cloudKitQuotaExceeded:
            return "Your iCloud storage is full. Please free up space and try again."
        case .cloudKitNetworkUnavailable:
            return "Network connection is unavailable. Data will sync when connection is restored."
        case .cloudKitUnknownError(let message):
            return "CloudKit error: \(message)"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .cloudKitNetworkUnavailable, .networkError:
            return true
        case .cloudKitAccountError, .cloudKitQuotaExceeded:
            return false
        default:
            return true
        }
    }
}

enum SyncStatus: Equatable {
    case unknown
    case syncing
    case synced
    case failed(String)
    case disabled
}

enum OfflineMode: Equatable {
    case online
    case offline
    case reconnecting

    var message: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline - Changes saved locally"
        case .reconnecting: return "Reconnecting..."
        }
    }

    var systemImage: String {
        switch self {
        case .online: return "wifi"
        case .offline: return "wifi.slash"
        case .reconnecting: return "wifi.exclamationmark"
        }
    }

    var color: Color {
        switch self {
        case .online: return .green
        case .offline: return .orange
        case .reconnecting: return .yellow
        }
    }
}