//
//  HabitDetailViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/16/25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class HabitDetailViewModel {

    // MARK: - Core Properties
    let habit: Habit

    // MARK: - UI State
    var isLoading: Bool = false
    var showingEditSheet: Bool = false
    var showingDeleteAlert: Bool = false
    var errorMessage: String?
    var selectedDate: Date = Date()
    var showingCalendarPicker: Bool = false

    // MARK: - Services
    private let appState: AppState
    private let habitService: HabitServiceProtocol
    private let navigationCoordinator: NavigationCoordinator

    // MARK: - Computed Properties

    var title: String {
        habit.baseTask?.title ?? "Untitled Habit"
    }

    var description: String? {
        habit.baseTask?.taskDescription
    }

    var currentStreak: Int {
        habit.currentStreak
    }

    var bestStreak: Int {
        habit.bestStreak
    }

    var totalCompletions: Int {
        habit.totalCompletions
    }

    var isCompletedToday: Bool {
        habit.isCompletedToday
    }

    var completionRate: Double {
        habit.completionRate
    }

    var availableProtectionDays: Int {
        habit.availableProtectionDays
    }

    var protectionDaysUsed: Int {
        habit.protectionDaysUsed
    }

    var formattedCompletionRate: String {
        let percentage = completionRate * 100
        return String(format: "%.1f%%", percentage)
    }

    var streakDescription: String {
        if currentStreak == 0 {
            return "No current streak"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }

    var bestStreakDescription: String {
        if bestStreak == 0 {
            return "No best streak yet"
        } else if bestStreak == 1 {
            return "Best: 1 day"
        } else {
            return "Best: \(bestStreak) days"
        }
    }

    var canUseProtectionDay: Bool {
        availableProtectionDays > 0 && !isCompletedToday
    }

    var protectionDaysText: String {
        let available = availableProtectionDays
        if available == 0 {
            return "No protection days remaining this month"
        } else if available == 1 {
            return "1 protection day remaining this month"
        } else {
            return "\(available) protection days remaining this month"
        }
    }

    var createdDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Created on \(formatter.string(from: habit.createdDate))"
    }

    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: habit.createdDate, to: Date()).day ?? 0
    }

    var averageCompletionsPerWeek: Double {
        let days = max(daysSinceCreation, 1)
        let weeks = Double(days) / 7.0
        return Double(totalCompletions) / weeks
    }

    var formattedWeeklyAverage: String {
        let average = averageCompletionsPerWeek
        return String(format: "%.1f times per week", average)
    }

    // MARK: - Calendar Data

    var completionDatesInCurrentMonth: [Date] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return []
        }

        return habit.completionDatesInRange(
            from: monthInterval.start,
            to: monthInterval.end
        )
    }

    var monthlyCompletionRate: Double {
        habit.monthlyCompletionRate(for: Date())
    }

    var formattedMonthlyRate: String {
        let percentage = monthlyCompletionRate * 100
        return String(format: "%.1f%% this month", percentage)
    }

    // MARK: - Initialization

    init(
        habit: Habit,
        appState: AppState,
        habitService: HabitServiceProtocol,
        navigationCoordinator: NavigationCoordinator
    ) {
        self.habit = habit
        self.appState = appState
        self.habitService = habitService
        self.navigationCoordinator = navigationCoordinator
    }

    // MARK: - Habit Actions

    func toggleTodayCompletion() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if isCompletedToday {
                try await habitService.markHabitIncomplete(habit, on: Date())
            } else {
                try await habitService.markHabitCompleted(habit, on: Date())
            }
        } catch {
            errorMessage = "Failed to update habit: \(error.localizedDescription)"
        }
    }

    func toggleCompletionForDate(_ date: Date) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let calendar = Calendar.current
            let isCompleted = habit.completionDates.contains { calendar.isDate($0, inSameDayAs: date) }

            if isCompleted {
                try await habitService.markHabitIncomplete(habit, on: date)
            } else {
                try await habitService.markHabitCompleted(habit, on: date)
            }
        } catch {
            errorMessage = "Failed to update habit for date: \(error.localizedDescription)"
        }
    }

    func useProtectionDay() async {
        guard canUseProtectionDay else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let success = try await habitService.useProtectionDay(for: habit, on: Date())
            if !success {
                errorMessage = "Unable to use protection day. No protection days remaining."
            }
        } catch {
            errorMessage = "Failed to use protection day: \(error.localizedDescription)"
        }
    }

    func editHabit() {
        // TODO: Navigate to EditHabitView when implemented
        navigationCoordinator.showEditHabit(habit)
    }

    func deleteHabit() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await habitService.deleteHabit(habit)
            navigationCoordinator.goBack()
        } catch {
            errorMessage = "Failed to delete habit: \(error.localizedDescription)"
        }
    }

    func refreshHabit() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await habitService.refreshHabits()
        } catch {
            errorMessage = "Failed to refresh habit: \(error.localizedDescription)"
        }
    }

    // MARK: - Date Helpers

    func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return habit.completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    func getStreakForDate(_ date: Date) -> Int {
        habit.streakOnDate(date)
    }

    // MARK: - UI Actions

    func showDeleteAlert() {
        showingDeleteAlert = true
    }

    func showCalendarPicker() {
        showingCalendarPicker = true
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        showingCalendarPicker = false
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Accessibility

    var completionStatusAccessibilityLabel: String {
        if isCompletedToday {
            return "Completed today"
        } else {
            return "Not completed today"
        }
    }

    var streakAccessibilityDescription: String {
        var description = streakDescription
        if currentStreak > 0 {
            description += ". " + bestStreakDescription
        }
        return description
    }

    var protectionDayAccessibilityLabel: String {
        if canUseProtectionDay {
            return "Use protection day. \(protectionDaysText)"
        } else {
            return protectionDaysText
        }
    }
}