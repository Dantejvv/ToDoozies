//
//  Habit.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Habit: @unchecked Sendable {
    var id: UUID = UUID()
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var totalCompletions: Int = 0
    var completionDates: [Date] = []
    var protectionDaysUsed: Int = 0
    var lastProtectionDate: Date?
    var targetCompletionsPerPeriod: Int?
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()

    @Relationship
    var baseTask: Task?

    init(
        baseTask: Task,
        targetCompletionsPerPeriod: Int? = nil
    ) {
        self.id = UUID()
        self.currentStreak = 0
        self.bestStreak = 0
        self.totalCompletions = 0
        self.completionDates = []
        self.protectionDaysUsed = 0
        self.lastProtectionDate = nil
        self.targetCompletionsPerPeriod = targetCompletionsPerPeriod
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.baseTask = baseTask

        baseTask.taskType = .habit
    }

    func markCompleted(on date: Date = Date()) {
        let calendar = Calendar.current
        let completionDate = calendar.startOfDay(for: date)

        guard !completionDates.contains(where: { calendar.isDate($0, inSameDayAs: completionDate) }) else {
            return
        }

        completionDates.append(completionDate)
        totalCompletions += 1
        updateStreak()
        baseTask?.markCompleted()
        modifiedDate = Date()
    }

    func markIncomplete(on date: Date = Date()) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        completionDates.removeAll { calendar.isDate($0, inSameDayAs: targetDate) }
        if totalCompletions > 0 {
            totalCompletions -= 1
        }
        updateStreak()
        baseTask?.markIncomplete()
        modifiedDate = Date()
    }

    func useProtectionDay(on date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: date)
        let lastProtectionMonth = lastProtectionDate.map { calendar.component(.month, from: $0) }

        let maxProtectionDays = 2
        let resetProtectionCount = lastProtectionMonth != currentMonth

        if resetProtectionCount {
            protectionDaysUsed = 0
        }

        guard protectionDaysUsed < maxProtectionDays else {
            return false
        }

        protectionDaysUsed += 1
        lastProtectionDate = date
        modifiedDate = Date()
        return true
    }

    private func updateStreak() {
        guard !completionDates.isEmpty else {
            currentStreak = 0
            return
        }

        let calendar = Calendar.current
        let sortedDates = completionDates.sorted(by: >)
        let today = calendar.startOfDay(for: Date())

        currentStreak = 0

        for (index, date) in sortedDates.enumerated() {
            let expectedDate = calendar.date(byAdding: .day, value: -index, to: today)!

            if calendar.isDate(date, inSameDayAs: expectedDate) {
                currentStreak += 1
            } else {
                break
            }
        }

        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
    }

    var isCompletedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completionDates.contains { calendar.isDate($0, inSameDayAs: today) }
    }

    var completionRate: Double {
        let calendar = Calendar.current
        let daysSinceCreation = calendar.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
        guard daysSinceCreation > 0 else { return 0.0 }
        return Double(totalCompletions) / Double(daysSinceCreation + 1)
    }

    var availableProtectionDays: Int {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let lastProtectionMonth = lastProtectionDate.map { calendar.component(.month, from: $0) }

        if lastProtectionMonth != currentMonth {
            return 2
        }
        return max(0, 2 - protectionDaysUsed)
    }

    func updateModifiedDate() {
        modifiedDate = Date()
    }
}

// MARK: - Habit Analytics
extension Habit {
    func completionDatesInRange(from startDate: Date, to endDate: Date) -> [Date] {
        return completionDates.filter { date in
            date >= startDate && date <= endDate
        }
    }

    func streakOnDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let sortedDates = completionDates.filter { $0 <= targetDate }.sorted(by: >)

        var streak = 0
        for (index, completionDate) in sortedDates.enumerated() {
            let expectedDate = calendar.date(byAdding: .day, value: -index, to: targetDate)!
            if calendar.isDate(completionDate, inSameDayAs: expectedDate) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    func monthlyCompletionRate(for date: Date) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date

        let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: endOfMonth).day ?? 30
        let completionsInMonth = completionDatesInRange(from: startOfMonth, to: endOfMonth).count

        return Double(completionsInMonth) / Double(daysInMonth)
    }
}