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


// MARK: - Habit Service Protocol

protocol HabitServiceProtocol {
    func refreshHabits() async throws
    func createHabit(_ habit: Habit) async throws
    func updateHabit(_ habit: Habit) async throws
    func deleteHabit(_ habit: Habit) async throws
    func getHabitStatistics(for habit: Habit) async throws -> HabitStatistics
    func getAllHabitStatistics() async throws -> [HabitStatistics]
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

}

