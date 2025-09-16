//
//  HabitsViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class HabitsViewModel {
    private let appState: AppState
    private let habitService: HabitServiceProtocol
    private let taskService: TaskServiceProtocol

    // MARK: - View State
    var isRefreshing: Bool = false
    var showingAddHabit: Bool = false
    var selectedTimeRange: HabitTimeRange = .week
    var showingCalendarView: Bool = false

    init(
        appState: AppState,
        habitService: HabitServiceProtocol,
        taskService: TaskServiceProtocol
    ) {
        self.appState = appState
        self.habitService = habitService
        self.taskService = taskService
    }

    // MARK: - Computed Properties

    /// All habits sorted by current streak (descending)
    var displayedHabits: [Habit] {
        appState.habits.sorted { habit1, habit2 in
            // Sort by current streak first
            if habit1.currentStreak != habit2.currentStreak {
                return habit1.currentStreak > habit2.currentStreak
            }
            // Then by completion rate
            if habit1.completionRate != habit2.completionRate {
                return habit1.completionRate > habit2.completionRate
            }
            // Finally by title
            return habit1.baseTask?.title ?? "" < habit2.baseTask?.title ?? ""
        }
    }

    /// Habits that need attention today
    var habitsForToday: [Habit] {
        appState.habits.filter { habit in
            guard let baseTask = habit.baseTask else { return false }
            return baseTask.isRecurring && !habit.isCompletedToday
        }
    }

    /// Habits completed today
    var habitsCompletedToday: [Habit] {
        appState.habits.filter { $0.isCompletedToday }
    }

    /// Overall completion rate for today
    var todayCompletionRate: Double {
        let allHabits = appState.habits.filter { $0.baseTask?.isRecurring == true }
        guard !allHabits.isEmpty else { return 0.0 }

        let completedCount = allHabits.filter { $0.isCompletedToday }.count
        return Double(completedCount) / Double(allHabits.count)
    }

    /// Progress text for today
    var todayProgressText: String {
        let completed = habitsCompletedToday.count
        let total = appState.habits.filter { $0.baseTask?.isRecurring == true }.count
        return "\(completed)/\(total) habits completed today"
    }

    /// Top streak habit
    var topStreakHabit: Habit? {
        appState.habits.max { $0.currentStreak < $1.currentStreak }
    }

    /// Total active streaks
    var activeStreaksCount: Int {
        appState.habits.filter { $0.currentStreak > 0 }.count
    }

    /// Best performing habit (by completion rate)
    var bestPerformingHabit: Habit? {
        appState.habits.max { $0.completionRate < $1.completionRate }
    }

    /// Habits that need motivation (low completion rate or broken streaks)
    var habitsNeedingAttention: [Habit] {
        appState.habits.filter { habit in
            habit.completionRate < 0.5 || // Less than 50% completion rate
            (habit.bestStreak > 7 && habit.currentStreak == 0) // Had a good streak but broke it
        }
    }

    /// Achievement candidates (close to milestones)
    var achievementCandidates: [HabitAchievement] {
        var achievements: [HabitAchievement] = []

        for habit in appState.habits {
            // Check for streak milestones
            let streakMilestones = [7, 14, 30, 50, 100, 365]
            for milestone in streakMilestones {
                if habit.currentStreak >= milestone - 2 && habit.currentStreak < milestone {
                    let daysToGo = milestone - habit.currentStreak
                    achievements.append(
                        HabitAchievement(
                            habit: habit,
                            type: .streak(milestone),
                            daysToAchieve: daysToGo,
                            description: "\(daysToGo) more day\(daysToGo == 1 ? "" : "s") to reach \(milestone)-day streak"
                        )
                    )
                }
            }

            // Check for perfect week/month potential
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let weekCompletions = habit.completionDatesInRange(from: weekStart, to: Date()).count
            let daysInWeek = calendar.dateComponents([.day], from: weekStart, to: Date()).day ?? 0

            if weekCompletions == daysInWeek && daysInWeek < 7 {
                achievements.append(
                    HabitAchievement(
                        habit: habit,
                        type: .perfectWeek,
                        daysToAchieve: 7 - daysInWeek,
                        description: "Perfect week possible!"
                    )
                )
            }
        }

        return achievements.sorted { $0.daysToAchieve < $1.daysToAchieve }
    }

    // MARK: - Actions

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await habitService.refreshHabits()
            try await taskService.refreshTasks()
        } catch {
            appState.setError(.dataLoadingFailed(error.localizedDescription))
        }
    }

    func completeHabit(_ habit: Habit) {
        habit.markCompleted()
        habit.baseTask?.markCompleted()

        _Concurrency.Task {
            do {
                try await habitService.updateHabit(habit)
                if let baseTask = habit.baseTask {
                    try await taskService.updateTask(baseTask)
                }
            } catch {
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func uncompleteHabit(_ habit: Habit) {
        habit.markIncomplete()
        habit.baseTask?.markIncomplete()

        _Concurrency.Task {
            do {
                try await habitService.updateHabit(habit)
                if let baseTask = habit.baseTask {
                    try await taskService.updateTask(baseTask)
                }
            } catch {
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func useProtectionDay(for habit: Habit) -> Bool {
        let success = habit.useProtectionDay()
        if success {
            _Concurrency.Task {
                do {
                    try await habitService.updateHabit(habit)
                } catch {
                    appState.setError(.dataSavingFailed(error.localizedDescription))
                }
            }
        }
        return success
    }

    func deleteHabit(_ habit: Habit) {
        appState.removeHabit(habit)

        _Concurrency.Task {
            do {
                try await habitService.deleteHabit(habit)
            } catch {
                appState.addHabit(habit) // Rollback on error
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func setTimeRange(_ range: HabitTimeRange) {
        selectedTimeRange = range
    }

    func toggleCalendarView() {
        showingCalendarView.toggle()
    }

    // MARK: - Statistics Methods

    func getCompletionRate(for habit: Habit, in timeRange: HabitTimeRange) -> Double {
        let calendar = Calendar.current
        let now = Date()

        let (startDate, expectedCompletions) = getTimeRangeInfo(timeRange, from: now)

        let actualCompletions = habit.completionDatesInRange(from: startDate, to: now).count
        return expectedCompletions > 0 ? Double(actualCompletions) / Double(expectedCompletions) : 0.0
    }

    func getStreak(for habit: Habit, on date: Date) -> Int {
        return habit.streakOnDate(date)
    }

    func getCompletionDates(for habit: Habit, in timeRange: HabitTimeRange) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let (startDate, _) = getTimeRangeInfo(timeRange, from: now)

        return habit.completionDatesInRange(from: startDate, to: now)
    }

    // MARK: - Helper Methods

    private func getTimeRangeInfo(_ timeRange: HabitTimeRange, from date: Date) -> (startDate: Date, expectedCompletions: Int) {
        let calendar = Calendar.current

        switch timeRange {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let daysInRange = calendar.dateComponents([.day], from: startOfWeek, to: date).day ?? 0
            return (startOfWeek, min(daysInRange + 1, 7))

        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let daysInRange = calendar.dateComponents([.day], from: startOfMonth, to: date).day ?? 0
            let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
            return (startOfMonth, min(daysInRange + 1, daysInMonth))

        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: date)?.start ?? date
            let daysInRange = calendar.dateComponents([.day], from: startOfYear, to: date).day ?? 0
            let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
            return (startOfYear, min(daysInRange + 1, daysInYear))

        case .all:
            // Use creation date of the oldest habit or 1 year ago, whichever is more recent
            let oldestHabitDate = appState.habits.map { $0.createdDate }.min() ?? date
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: date) ?? date
            let startDate = max(oldestHabitDate, oneYearAgo)
            let daysInRange = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            return (startDate, daysInRange + 1)
        }
    }
}

// MARK: - Supporting Types

enum HabitTimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"
    case all = "all"

    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        case .all: return "All Time"
        }
    }
}

struct HabitAchievement {
    let habit: Habit
    let type: AchievementType
    let daysToAchieve: Int
    let description: String

    enum AchievementType {
        case streak(Int)
        case perfectWeek
        case perfectMonth

        var iconName: String {
            switch self {
            case .streak(_): return "flame.fill"
            case .perfectWeek: return "calendar.badge.checkmark"
            case .perfectMonth: return "calendar.badge.checkmark"
            }
        }
    }
}