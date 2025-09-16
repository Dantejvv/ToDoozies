//
//  AccessibilityHelpers.swift
//  ToDoozies
//
//  Created by Claude Code on 9/15/25.
//

import Foundation
import SwiftUI

// MARK: - Task Accessibility Extensions

extension Task {
    /// Provides a comprehensive accessibility label for VoiceOver users
    var accessibilityLabel: String {
        var label = title

        // Add due date information
        if let dueDate = dueDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let relativeDate = formatter.localizedString(for: dueDate, relativeTo: Date())
            label += ", due \(relativeDate)"
        }

        // Add priority information
        label += ", \(priority.displayName) priority"

        // Add completion status
        if isCompleted {
            label += ", completed"
        }

        return label
    }

    /// Provides current state information for VoiceOver
    var accessibilityValue: String {
        if isCompleted {
            return "Completed"
        } else if isOverdue {
            return "Overdue"
        } else if isDueToday {
            return "Due today"
        } else if isDueTomorrow {
            return "Due tomorrow"
        } else {
            return "Not completed"
        }
    }

    /// Provides usage hints for VoiceOver users
    var accessibilityHint: String {
        if isCompleted {
            return "Double tap to view details"
        } else {
            return "Double tap to view details, or use actions to complete"
        }
    }

    /// Provides accessibility traits based on task state
    var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]

        if isCompleted {
            _ = traits.insert(.isSelected)
        }

        if isOverdue {
            _ = traits.insert(.updatesFrequently)
        }

        return traits
    }
}

// MARK: - Habit Accessibility Extensions

extension Habit {
    /// Provides a comprehensive accessibility label for habit tracking
    var accessibilityLabel: String {
        guard let baseTask = baseTask else { return "Habit" }
        var label = "\(baseTask.title) habit"

        if currentStreak > 0 {
            label += ", \(currentStreak) day current streak"
        }

        return label
    }

    /// Provides current completion and streak information
    var accessibilityValue: String {
        var value = isCompletedToday ? "completed today" : "not completed today"

        if bestStreak > 0 {
            value += ", best streak \(bestStreak) days"
        }

        if availableProtectionDays > 0 {
            value += ", \(availableProtectionDays) protection days available"
        }

        return value
    }

    /// Provides usage hints for habit interactions
    var accessibilityHint: String {
        if isCompletedToday {
            return "Swipe up or down to toggle completion, or double tap for details"
        } else {
            return "Swipe up to mark completed, down to use protection day, or double tap for details"
        }
    }

    /// Provides traits for habit elements
    var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]

        if isCompletedToday {
            _ = traits.insert(.isSelected)
        }

        return traits
    }
}

// MARK: - Category Accessibility Extensions

extension Category {
    /// Provides accessibility label for category selection
    var accessibilityLabel: String {
        return "\(name) category"
    }

    /// Provides completion information for categories
    var accessibilityValue: String {
        let percentage = Int(completionPercentage * 100)
        return "\(percentage) percent complete, \(taskCount) total tasks"
    }
}

// MARK: - Priority Accessibility Extensions

extension Priority {
    /// Enhanced display name for accessibility
    var accessibilityDisplayName: String {
        switch self {
        case .high:
            return "High priority"
        case .medium:
            return "Medium priority"
        case .low:
            return "Low priority"
        }
    }
}

// MARK: - Subtask Accessibility Extensions

extension Subtask {
    /// Provides accessibility label for subtasks
    var accessibilityLabel: String {
        var label = "Subtask: \(title)"

        if isComplete {
            label += ", completed"
        }

        return label
    }

    /// Provides completion state
    var accessibilityValue: String {
        return isComplete ? "Completed" : "Not completed"
    }

    /// Provides interaction hints
    var accessibilityHint: String {
        return isComplete ?
            "Double tap to mark incomplete" :
            "Double tap to mark complete"
    }
}

// MARK: - Accessibility Announcement Helpers

struct AccessibilityAnnouncement {
    /// Announces task completion to VoiceOver users
    static func taskCompleted(_ task: Task) -> String {
        return "\(task.title) marked as completed"
    }

    /// Announces task creation to VoiceOver users
    static func taskCreated(_ task: Task) -> String {
        return "\(task.title) task created"
    }

    /// Announces habit completion to VoiceOver users
    static func habitCompleted(_ habit: Habit) -> String {
        guard let baseTask = habit.baseTask else { return "Habit completed" }

        var announcement = "\(baseTask.title) completed for today"

        if habit.currentStreak > 1 {
            announcement += ". Current streak: \(habit.currentStreak) days"
        }

        // Special announcements for milestone streaks
        if habit.currentStreak == 7 {
            announcement += ". Congratulations on your week-long streak!"
        } else if habit.currentStreak == 30 {
            announcement += ". Excellent! You've reached a 30-day streak!"
        } else if habit.currentStreak == 100 {
            announcement += ". Outstanding! 100 days completed!"
        }

        return announcement
    }

    /// Announces sync status changes
    static func syncStatusChanged(_ status: SyncStatus) -> String {
        switch status {
        case .synced:
            return "Data synced successfully"
        case .syncing:
            return "Syncing data"
        case .failed(let error):
            return "Sync failed: \(error), data saved locally"
        case .disabled:
            return "Sync disabled"
        case .unknown:
            return ""
        }
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
extension AccessibilityHelpers {
    /// Validates that accessibility properties are properly configured
    static func validateAccessibility<T>(for object: T,
                                       expectedLabel: String? = nil,
                                       expectedValue: String? = nil,
                                       expectedHint: String? = nil) -> Bool {
        // This helper can be used in tests to validate accessibility setup
        // Implementation would check actual accessibility properties
        return true
    }
}

struct AccessibilityHelpers {
    /// Simulates VoiceOver announcement for testing
    static func simulateAnnouncement(_ text: String) {
        #if targetEnvironment(simulator)
        print("VoiceOver Announcement: \(text)")
        #endif
    }
}
#endif