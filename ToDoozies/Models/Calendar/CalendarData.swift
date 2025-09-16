//
//  CalendarData.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import Foundation
import SwiftUI

// MARK: - Calendar Display Types

enum CalendarRange: String, CaseIterable {
    case month = "month"
    case quarter = "quarter"
    case year = "year"

    var displayName: String {
        switch self {
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }

    var numberOfMonths: Int {
        switch self {
        case .month: return 1
        case .quarter: return 3
        case .year: return 12
        }
    }
}

enum CalendarViewMode: String, CaseIterable {
    case heatmap = "heatmap"
    case taskOverview = "taskOverview"
    case streakChain = "streakChain"

    var displayName: String {
        switch self {
        case .heatmap: return "Heatmap"
        case .taskOverview: return "Tasks"
        case .streakChain: return "Streak Chain"
        }
    }

    var iconName: String {
        switch self {
        case .heatmap: return "calendar.badge.clock"
        case .taskOverview: return "calendar"
        case .streakChain: return "link"
        }
    }
}

// MARK: - Calendar Day Data

struct CalendarDay {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool

    init(date: Date, currentMonth: Date, selectedDate: Date? = nil) {
        self.date = date
        self.isInCurrentMonth = Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
        self.isToday = Calendar.current.isDateInToday(date)
        self.isSelected = selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
    }
}

// MARK: - Habit Calendar Data

struct HabitCalendarData {
    let habit: Habit
    let completionDates: Set<Date>
    let currentStreak: Int
    let bestStreak: Int

    init(habit: Habit) {
        self.habit = habit
        self.completionDates = Set(habit.completionDates.map { Calendar.current.startOfDay(for: $0) })
        self.currentStreak = habit.currentStreak
        self.bestStreak = habit.bestStreak
    }

    func isCompleted(on date: Date) -> Bool {
        let dayStart = Calendar.current.startOfDay(for: date)
        return completionDates.contains(dayStart)
    }

    func completionIntensity(for date: Date) -> Double {
        if !isCompleted(on: date) { return 0.0 }

        // Calculate streak at this date to determine intensity
        let streakOnDate = habit.streakOnDate(date)

        // Normalize streak to 0.0-1.0 range with some caps for visual clarity
        let maxIntensity = min(Double(streakOnDate), 30.0) // Cap at 30 days for color intensity
        return maxIntensity / 30.0
    }

    func completionRate(for dateRange: ClosedRange<Date>) -> Double {
        let calendar = Calendar.current
        var totalDays = 0
        var completedDays = 0

        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            totalDays += 1
            if isCompleted(on: currentDate) {
                completedDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? dateRange.upperBound
        }

        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
    }
}

// MARK: - Task Calendar Data

struct TaskCalendarData {
    let tasksForDate: [Date: [Task]]

    init(tasks: [Task]) {
        var groupedTasks: [Date: [Task]] = [:]

        for task in tasks {
            guard let dueDate = task.dueDate else { continue }
            let dayStart = Calendar.current.startOfDay(for: dueDate)

            if groupedTasks[dayStart] == nil {
                groupedTasks[dayStart] = []
            }
            groupedTasks[dayStart]?.append(task)
        }

        self.tasksForDate = groupedTasks
    }

    func tasks(for date: Date) -> [Task] {
        let dayStart = Calendar.current.startOfDay(for: date)
        return tasksForDate[dayStart] ?? []
    }

    func taskCount(for date: Date) -> Int {
        return tasks(for: date).count
    }

    func hasHighPriorityTasks(for date: Date) -> Bool {
        return tasks(for: date).contains { $0.priority == .high }
    }

    func hasOverdueTasks(for date: Date) -> Bool {
        return tasks(for: date).contains { $0.isOverdue }
    }

    func completedTaskCount(for date: Date) -> Int {
        return tasks(for: date).filter { $0.isCompleted }.count
    }
}

// MARK: - Calendar Utilities

extension Calendar {
    func dateRange(for range: CalendarRange, from date: Date = Date()) -> ClosedRange<Date> {
        switch range {
        case .month:
            let startOfMonth = self.dateInterval(of: .month, for: date)?.start ?? date
            let endOfMonth = self.dateInterval(of: .month, for: date)?.end ?? date
            return startOfMonth...endOfMonth

        case .quarter:
            let month = self.component(.month, from: date)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1

            var startComponents = self.dateComponents([.year], from: date)
            startComponents.month = quarterStartMonth
            startComponents.day = 1
            let quarterStart = self.date(from: startComponents) ?? date

            let quarterEnd = self.date(byAdding: DateComponents(month: 3, day: -1), to: quarterStart) ?? date
            return quarterStart...quarterEnd

        case .year:
            let startOfYear = self.dateInterval(of: .year, for: date)?.start ?? date
            let endOfYear = self.dateInterval(of: .year, for: date)?.end ?? date
            return startOfYear...endOfYear
        }
    }

    func monthGrid(for month: Date) -> [[CalendarDay]] {
        guard let monthInterval = dateInterval(of: .month, for: month) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start

        // Find the first day of the week containing the first day of month
        let firstWeekday = component(.weekday, from: firstDayOfMonth)
        let daysFromStartOfWeek = firstWeekday - 1 // Sunday is 1, so subtract 1 to get days from start of week
        let gridStart = date(byAdding: .day, value: -daysFromStartOfWeek, to: firstDayOfMonth) ?? firstDayOfMonth

        var weeks: [[CalendarDay]] = []
        var currentWeek: [CalendarDay] = []
        var currentDate = gridStart

        // Generate 6 weeks to ensure we have a complete calendar grid
        for _ in 0..<42 {
            let calendarDay = CalendarDay(date: currentDate, currentMonth: month)
            currentWeek.append(calendarDay)

            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }

            currentDate = date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Add any remaining days
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        return weeks
    }
}

// MARK: - Color Extensions for Calendar

extension Color {
    static func habitIntensityColor(for intensity: Double) -> Color {
        // GitHub-style green intensity scale
        switch intensity {
        case 0: return Color(.systemGray6)
        case 0.01..<0.25: return Color(.systemGreen).opacity(0.3)
        case 0.25..<0.5: return Color(.systemGreen).opacity(0.5)
        case 0.5..<0.75: return Color(.systemGreen).opacity(0.7)
        default: return Color(.systemGreen)
        }
    }

    static func taskPriorityColor(for priority: Priority) -> Color {
        switch priority {
        case .high: return Color(.systemRed)
        case .medium: return Color(.systemOrange)
        case .low: return Color(.systemBlue)
        }
    }
}