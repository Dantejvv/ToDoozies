//
//  TaskCalendarView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct TaskCalendarView: View {
    let tasks: [Task]
    @State private var selectedMonth: Date = Date()
    @State private var selectedDate: Date?

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current

    private var taskData: TaskCalendarData {
        TaskCalendarData(tasks: tasks)
    }

    private var monthlyTasks: [Task] {
        let monthRange = calendar.dateRange(for: .month, from: selectedMonth)
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return monthRange.contains(dueDate)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var monthStats: (total: Int, completed: Int, overdue: Int, highPriority: Int) {
        let total = monthlyTasks.count
        let completed = monthlyTasks.filter { $0.isCompleted }.count
        let overdue = monthlyTasks.filter { $0.isOverdue }.count
        let highPriority = monthlyTasks.filter { $0.priority == .high }.count

        return (total: total, completed: completed, overdue: overdue, highPriority: highPriority)
    }

    var body: some View {
        VStack(spacing: .spacing4) {
            // Header with navigation and stats
            headerView

            // Calendar grid
            monthCalendarView

            // Selected day task list
            if let selectedDate = selectedDate {
                selectedDateTasksView(for: selectedDate)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: .spacing3) {
            // Navigation and title
            HStack {
                Button(action: navigatePreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Previous month")

                Spacer()

                Text(monthTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: navigateNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Next month")
            }

            // Monthly statistics
            let stats = monthStats
            if stats.total > 0 {
                HStack(spacing: .spacing6) {
                    StatBadge(
                        title: "Total",
                        value: "\(stats.total)",
                        color: .blue
                    )

                    StatBadge(
                        title: "Completed",
                        value: "\(stats.completed)",
                        color: .green
                    )

                    if stats.overdue > 0 {
                        StatBadge(
                            title: "Overdue",
                            value: "\(stats.overdue)",
                            color: .red
                        )
                    }

                    if stats.highPriority > 0 {
                        StatBadge(
                            title: "High Priority",
                            value: "\(stats.highPriority)",
                            color: .orange
                        )
                    }

                    Spacer()
                }
            }
        }
        .horizontalSpacingPadding(.spacing4)
    }

    // MARK: - Month Calendar View

    private var monthCalendarView: some View {
        VStack(spacing: .spacing3) {
            // Weekday headers
            weekdayHeadersView

            // Calendar grid
            let monthGrid = calendar.monthGrid(for: selectedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: .spacing2) {
                ForEach(0..<min(monthGrid.count * 7, 42), id: \.self) { index in
                    let weekIndex = index / 7
                    let dayIndex = index % 7

                    if weekIndex < monthGrid.count && dayIndex < monthGrid[weekIndex].count {
                        let calendarDay = monthGrid[weekIndex][dayIndex]
                        TaskDayCell(
                            calendarDay: calendarDay,
                            taskData: taskData,
                            isSelected: selectedDate != nil && calendar.isDate(calendarDay.date, inSameDayAs: selectedDate!),
                            onTap: selectDate
                        )
                        .opacity(calendarDay.isInCurrentMonth ? 1.0 : 0.3)
                        .scaleEffect(
                            calendarDay.isInCurrentMonth ? 1.0 : 0.8,
                            anchor: .center
                        )
                        .animation(
                            reduceMotion ? .none : .easeInOut(duration: 0.1),
                            value: calendarDay.isInCurrentMonth
                        )
                    } else {
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .cardStyle()
        .spacingPadding(.spacing4)
        .horizontalSpacingPadding(.spacing4)
    }

    private var weekdayHeadersView: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                Text(weekday.uppercased())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Selected Date Tasks View

    private func selectedDateTasksView(for date: Date) -> some View {
        let dayTasks = taskData.tasks(for: date)
        let formatter = DateFormatter()
        formatter.dateStyle = .full

        return VStack(alignment: .leading, spacing: .spacing3) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: .spacing1) {
                    Text(formatter.string(from: date))
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(dayTasks.count) task\(dayTasks.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Close") {
                    selectedDate = nil
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }

            // Task list
            if dayTasks.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.secondary)
                        .font(.title2)

                    Text("No tasks for this day")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    Spacer()
                }
                .spacingPadding(.spacing4)
            } else {
                LazyVStack(spacing: .spacing2) {
                    ForEach(dayTasks, id: \.id) { task in
                        CalendarTaskRowView(task: task)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .cardStyle()
        .spacingPadding(.spacing4)
        .horizontalSpacingPadding(.spacing4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tasks for selected date")
    }

    // MARK: - Actions

    private func selectDate(_ date: Date) {
        selectedDate = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!) ? nil : date
    }

    private func navigatePreviousMonth() {
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        }
    }

    private func navigateNextMonth() {
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        }
    }
}

// MARK: - Supporting Views

private struct StatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: .spacing1) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .smallCardStyle()
        .spacingPadding(.spacing3)
    }
}

private struct CalendarTaskRowView: View {
    let task: Task

    private var priorityColor: Color {
        Color.taskPriorityColor(for: task.priority)
    }

    private var dueTimeString: String? {
        guard let dueDate = task.dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }

    var body: some View {
        HStack(spacing: .spacing3) {
            // Completion checkbox
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .secondary)
                .font(.title3)

            // Task details
            VStack(alignment: .leading, spacing: .spacing1) {
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .strikethrough(task.isCompleted)

                    Spacer()

                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                }

                if let timeString = dueTimeString {
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Overdue indicator
            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .spacingPadding(.spacing3)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()

    let previewTasks = [
        Task(title: "Team Meeting", dueDate: today, priority: .high),
        Task(title: "Code Review", dueDate: today, priority: .medium),
        Task(title: "Update Documentation", dueDate: calendar.date(byAdding: .day, value: 1, to: today), priority: .low),
        Task(title: "Plan Sprint", dueDate: calendar.date(byAdding: .day, value: 3, to: today), priority: .high),
        Task(title: "Client Call", dueDate: calendar.date(byAdding: .day, value: -2, to: today), priority: .medium),
    ]

    // Mark some tasks as completed
    previewTasks[1].markCompleted()
    previewTasks[2].markCompleted()

    return NavigationStack {
        TaskCalendarView(tasks: previewTasks)
            .navigationTitle("Task Calendar")
            .navigationBarTitleDisplayMode(.inline)
    }
}