//
//  HabitService.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData

// MARK: - Supporting Types

struct HabitStatistics {
    let habitId: UUID
    let totalCompletions: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageCompletionsPerWeek: Double
    let completionRate: Double
    let lastCompletionDate: Date?
    let weeklyCompletionRate: Double
    let monthlyCompletionRate: Double
    let yearlyCompletionRate: Double
    let allTimeCompletionRate: Double
    let averageStreak: Double
    let protectionDaysUsed: Int
    let protectionDaysAvailable: Int

    var overallGrade: HabitGrade {
        let rate = allTimeCompletionRate
        switch rate {
        case 0.9...:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.6..<0.8:
            return .fair
        case 0.4..<0.6:
            return .needsWork
        default:
            return .struggling
        }
    }
}

enum HabitGrade: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case needsWork = "needsWork"
    case struggling = "struggling"

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .needsWork: return "Needs Work"
        case .struggling: return "Struggling"
        }
    }

    var color: String {
        switch self {
        case .excellent: return "#4CAF50"
        case .good: return "#8BC34A"
        case .fair: return "#FFC107"
        case .needsWork: return "#FF9800"
        case .struggling: return "#F44336"
        }
    }
}

struct Achievement {
    let type: AchievementType
    let title: String
    let description: String
    let habitId: UUID
    let unlockedDate: Date
}

enum AchievementType {
    case streak(Int)
    case perfectWeek
    case perfectMonth
    case totalCompletions(Int)
    case comeback

    var iconName: String {
        switch self {
        case .streak(_): return "flame.fill"
        case .perfectWeek: return "calendar.badge.checkmark"
        case .perfectMonth: return "calendar.badge.checkmark"
        case .totalCompletions(_): return "star.fill"
        case .comeback: return "arrow.clockwise"
        }
    }
}

// MARK: - Habit Service Protocol

protocol HabitServiceProtocol {
    func refreshHabits() async throws
    func createHabit(_ habit: Habit) async throws
    func updateHabit(_ habit: Habit) async throws
    func deleteHabit(_ habit: Habit) async throws
    func getHabitStatistics(for habit: Habit) async throws -> HabitStatistics
    func getAllHabitStatistics() async throws -> [HabitStatistics]
    func checkForAchievements(_ habit: Habit) async throws -> [Achievement]
}

// MARK: - Habit Service Implementation

@MainActor
final class HabitService: HabitServiceProtocol {
    private let modelContext: ModelContext
    private let appState: AppState

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    // MARK: - CRUD Operations

    func refreshHabits() async throws {
        do {
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            let habits = try modelContext.fetch(descriptor)
            appState.setHabits(habits)
        } catch {
            throw AppError.dataLoadingFailed("Failed to refresh habits: \(error.localizedDescription)")
        }
    }

    func createHabit(_ habit: Habit) async throws {
        do {
            modelContext.insert(habit)

            // Also insert the base task if it's not already persisted
            if let baseTask = habit.baseTask {
                // Check if the task is already in the context, if not insert it
                let existingTask: Task? = modelContext.registeredModel(for: baseTask.persistentModelID)
                if existingTask == nil {
                    modelContext.insert(baseTask)
                }
            }

            try modelContext.save()

            // Update app state
            appState.addHabit(habit)

        } catch {
            throw AppError.dataSavingFailed("Failed to create habit: \(error.localizedDescription)")
        }
    }

    func updateHabit(_ habit: Habit) async throws {
        do {
            habit.updateModifiedDate()
            try modelContext.save()
        } catch {
            throw AppError.dataSavingFailed("Failed to update habit: \(error.localizedDescription)")
        }
    }

    func deleteHabit(_ habit: Habit) async throws {
        do {
            modelContext.delete(habit)
            try modelContext.save()

            // Remove from app state
            appState.removeHabit(habit)

        } catch {
            throw AppError.dataSavingFailed("Failed to delete habit: \(error.localizedDescription)")
        }
    }

    // MARK: - Habit Completion Management

    func markHabitCompleted(_ habit: Habit, on date: Date = Date()) async throws {
        habit.markCompleted(on: date)

        // Also mark the base task as completed if it exists
        habit.baseTask?.markCompleted()

        try await updateHabit(habit)

        // Check for achievements
        let achievements = try await checkForAchievements(habit)
        if !achievements.isEmpty {
            // TODO: Trigger achievement notifications
            await notifyAchievements(achievements, for: habit)
        }
    }

    func markHabitIncomplete(_ habit: Habit, on date: Date = Date()) async throws {
        habit.markIncomplete(on: date)
        habit.baseTask?.markIncomplete()
        try await updateHabit(habit)
    }

    func useProtectionDay(for habit: Habit, on date: Date = Date()) async throws -> Bool {
        let success = habit.useProtectionDay(on: date)
        if success {
            try await updateHabit(habit)
        }
        return success
    }

    // MARK: - Statistics and Analytics

    func getHabitStatistics(for habit: Habit) async throws -> HabitStatistics {
        let calendar = Calendar.current
        let now = Date()

        // Calculate various time periods
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now

        // Weekly stats
        let weekCompletions = habit.completionDatesInRange(from: weekStart, to: now)
        let weeklyRate = calculateCompletionRate(
            completions: weekCompletions.count,
            totalDays: calendar.dateComponents([.day], from: weekStart, to: now).day ?? 0 + 1
        )

        // Monthly stats
        let monthCompletions = habit.completionDatesInRange(from: monthStart, to: now)
        let monthlyRate = calculateCompletionRate(
            completions: monthCompletions.count,
            totalDays: calendar.dateComponents([.day], from: monthStart, to: now).day ?? 0 + 1
        )

        // Yearly stats
        let yearCompletions = habit.completionDatesInRange(from: yearStart, to: now)
        let yearlyRate = calculateCompletionRate(
            completions: yearCompletions.count,
            totalDays: calendar.dateComponents([.day], from: yearStart, to: now).day ?? 0 + 1
        )

        // All-time stats
        let allTimeRate = habit.completionRate

        // Streak analysis
        let longestStreak = habit.bestStreak
        let currentStreak = habit.currentStreak
        let averageStreak = calculateAverageStreak(habit)

        return HabitStatistics(
            habitId: habit.id,
            totalCompletions: habit.totalCompletions,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageCompletionsPerWeek: weeklyRate * 7, // Convert rate to completions per week
            completionRate: allTimeRate,
            lastCompletionDate: habit.completionDates.max(),
            weeklyCompletionRate: weeklyRate,
            monthlyCompletionRate: monthlyRate,
            yearlyCompletionRate: yearlyRate,
            allTimeCompletionRate: allTimeRate,
            averageStreak: averageStreak,
            protectionDaysUsed: habit.protectionDaysUsed,
            protectionDaysAvailable: habit.availableProtectionDays
        )
    }

    func getAllHabitStatistics() async throws -> [HabitStatistics] {
        var statistics: [HabitStatistics] = []

        for habit in appState.habits {
            let stats = try await getHabitStatistics(for: habit)
            statistics.append(stats)
        }

        return statistics.sorted { $0.currentStreak > $1.currentStreak }
    }

    // MARK: - Achievement System

    func checkForAchievements(_ habit: Habit) async throws -> [Achievement] {
        var achievements: [Achievement] = []

        // Streak milestones
        let streakMilestones = [3, 7, 14, 30, 50, 100, 365, 1000]
        for milestone in streakMilestones {
            if habit.currentStreak == milestone {
                achievements.append(Achievement(
                    type: .streak(milestone),
                    title: "\(milestone)-Day Streak!",
                    description: "You've completed \(habit.baseTask?.title ?? "this habit") for \(milestone) consecutive days!",
                    habitId: habit.id,
                    unlockedDate: Date()
                ))
            }
        }

        // Perfect week achievement
        if isCurrentWeekPerfect(habit) {
            achievements.append(Achievement(
                type: .perfectWeek,
                title: "Perfect Week!",
                description: "You completed \(habit.baseTask?.title ?? "this habit") every day this week!",
                habitId: habit.id,
                unlockedDate: Date()
            ))
        }

        // Perfect month achievement
        if isCurrentMonthPerfect(habit) {
            achievements.append(Achievement(
                type: .perfectMonth,
                title: "Perfect Month!",
                description: "You completed \(habit.baseTask?.title ?? "this habit") every day this month!",
                habitId: habit.id,
                unlockedDate: Date()
            ))
        }

        // Total completion milestones
        let completionMilestones = [10, 25, 50, 100, 250, 500, 1000]
        for milestone in completionMilestones {
            if habit.totalCompletions == milestone {
                achievements.append(Achievement(
                    type: .totalCompletions(milestone),
                    title: "\(milestone) Completions!",
                    description: "You've completed \(habit.baseTask?.title ?? "this habit") \(milestone) times!",
                    habitId: habit.id,
                    unlockedDate: Date()
                ))
            }
        }

        // Comeback achievement (returning after a break)
        if habit.currentStreak == 1 && habit.bestStreak >= 7 {
            let daysSinceLastCompletion = calculateDaysSinceLastCompletion(habit)
            if daysSinceLastCompletion >= 7 {
                achievements.append(Achievement(
                    type: .comeback,
                    title: "Welcome Back!",
                    description: "Great to see you getting back into \(habit.baseTask?.title ?? "this habit")!",
                    habitId: habit.id,
                    unlockedDate: Date()
                ))
            }
        }

        return achievements
    }

    // MARK: - Helper Methods

    private func calculateCompletionRate(completions: Int, totalDays: Int) -> Double {
        guard totalDays > 0 else { return 0.0 }
        return Double(completions) / Double(totalDays)
    }

    private func calculateAverageStreak(_ habit: Habit) -> Double {
        let completionDates = habit.completionDates.sorted()
        guard completionDates.count > 1 else { return Double(habit.currentStreak) }

        var streaks: [Int] = []
        var currentStreakLength = 1
        let calendar = Calendar.current

        for i in 1..<completionDates.count {
            let previousDate = completionDates[i - 1]
            let currentDate = completionDates[i]

            if calendar.dateComponents([.day], from: previousDate, to: currentDate).day == 1 {
                // Consecutive days
                currentStreakLength += 1
            } else {
                // Streak broken
                streaks.append(currentStreakLength)
                currentStreakLength = 1
            }
        }

        // Add the last streak
        streaks.append(currentStreakLength)

        let totalStreak = streaks.reduce(0, +)
        return Double(totalStreak) / Double(streaks.count)
    }

    private func isCurrentWeekPerfect(_ habit: Habit) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }

        let weekStart = weekInterval.start
        let daysInWeek = calendar.dateComponents([.day], from: weekStart, to: now).day ?? 0

        let completionsThisWeek = habit.completionDatesInRange(from: weekStart, to: now)
        return completionsThisWeek.count == daysInWeek + 1 // +1 because we include today
    }

    private func isCurrentMonthPerfect(_ habit: Habit) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return false }

        let monthStart = monthInterval.start
        let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: now).day ?? 0

        let completionsThisMonth = habit.completionDatesInRange(from: monthStart, to: now)
        return completionsThisMonth.count == daysInMonth + 1 // +1 because we include today
    }

    private func calculateDaysSinceLastCompletion(_ habit: Habit) -> Int {
        guard let lastCompletion = habit.completionDates.max() else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastCompletion, to: Date()).day ?? 0
    }

    private func notifyAchievements(_ achievements: [Achievement], for habit: Habit) async {
        // TODO: Implement achievement notifications
        // This would integrate with a NotificationService to show celebratory notifications
    }
}

