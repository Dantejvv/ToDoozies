//
//  TaskDayCell.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct TaskDayCell: View {
    let calendarDay: CalendarDay
    let taskData: TaskCalendarData
    let isSelected: Bool
    let onTap: (Date) -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dayTasks: [Task] {
        taskData.tasks(for: calendarDay.date)
    }

    private var taskCount: Int {
        dayTasks.count
    }

    private var hasHighPriorityTasks: Bool {
        taskData.hasHighPriorityTasks(for: calendarDay.date)
    }

    private var hasOverdueTasks: Bool {
        taskData.hasOverdueTasks(for: calendarDay.date)
    }

    private var completedTaskCount: Int {
        taskData.completedTaskCount(for: calendarDay.date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: calendarDay.date)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.3)
        } else if calendarDay.isToday {
            return Color.accentColor.opacity(0.1)
        } else if !calendarDay.isInCurrentMonth {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor
        } else if calendarDay.isToday {
            return Color.accentColor
        } else {
            return Color(.systemGray4)
        }
    }

    private var textColor: Color {
        if !calendarDay.isInCurrentMonth {
            return Color(.systemGray3)
        } else {
            return Color.primary
        }
    }

    var body: some View {
        Button(action: {
            onTap(calendarDay.date)
        }) {
            VStack(spacing: .spacing1) {
                // Day number
                Text(dayNumber)
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 14 : 16, weight: .medium))
                    .foregroundColor(textColor)

                Spacer()

                // Task indicators
                if taskCount > 0 && calendarDay.isInCurrentMonth {
                    VStack(spacing: 2) {
                        // Priority indicator
                        if hasHighPriorityTasks || hasOverdueTasks {
                            Circle()
                                .fill(hasOverdueTasks ? Color.red : Color.orange)
                                .frame(width: 6, height: 6)
                        }

                        // Task count badge
                        if taskCount > 0 {
                            Text("\(taskCount)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle()
                                        .fill(completionColor)
                                )
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .frame(width: cellSize, height: cellSize)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(borderColor, lineWidth: isSelected || calendarDay.isToday ? 2 : 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.small)
        .disabled(!calendarDay.isInCurrentMonth)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "View tasks") {
            onTap(calendarDay.date)
        }
    }

    // MARK: - Computed Properties

    private var cellSize: CGFloat {
        // Adjust cell size based on Dynamic Type
        let baseSize: CGFloat = 44
        let sizeMultiplier = dynamicTypeSize.isAccessibilitySize ? 1.2 : 1.0
        return baseSize * sizeMultiplier
    }

    private var completionColor: Color {
        if taskCount == 0 {
            return Color(.systemGray4)
        }

        let completionRate = Double(completedTaskCount) / Double(taskCount)

        switch completionRate {
        case 1.0:
            return Color.green
        case 0.5..<1.0:
            return Color.orange
        default:
            return Color.blue
        }
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateString = formatter.string(from: calendarDay.date)

        if calendarDay.isToday {
            return "Today, \(dateString)"
        } else {
            return dateString
        }
    }

    private var accessibilityValue: String {
        if !calendarDay.isInCurrentMonth {
            return "Not in current month"
        }

        if taskCount == 0 {
            return "No tasks"
        }

        var components: [String] = []

        // Task count
        components.append("\(taskCount) task\(taskCount == 1 ? "" : "s")")

        // Completion status
        if completedTaskCount > 0 {
            components.append("\(completedTaskCount) completed")
        }

        // Priority indicators
        if hasOverdueTasks {
            components.append("Has overdue tasks")
        } else if hasHighPriorityTasks {
            components.append("Has high priority tasks")
        }

        return components.joined(separator: ", ")
    }

    private var accessibilityHint: String {
        if !calendarDay.isInCurrentMonth || taskCount == 0 {
            return ""
        }
        return "Double tap to view tasks for this date"
    }
}

// MARK: - Preview

#Preview {
    let previewTasks = [
        Task(title: "Morning Meeting", dueDate: Date(), priority: .high),
        Task(title: "Review Code", dueDate: Date(), priority: .medium),
        Task(title: "Update Documentation", dueDate: Date(), priority: .low)
    ]

    // Mark one task as completed
    previewTasks[2].markCompleted()

    let taskData = TaskCalendarData(tasks: previewTasks)
    let today = CalendarDay(date: Date(), currentMonth: Date())

    return VStack(spacing: .spacing4) {
        HStack(spacing: .spacing2) {
            // Empty day
            TaskDayCell(
                calendarDay: CalendarDay(
                    date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    currentMonth: Date()
                ),
                taskData: TaskCalendarData(tasks: []),
                isSelected: false,
                onTap: { _ in }
            )

            // Day with tasks
            TaskDayCell(
                calendarDay: CalendarDay(
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    currentMonth: Date()
                ),
                taskData: taskData,
                isSelected: false,
                onTap: { _ in }
            )

            // Today (selected)
            TaskDayCell(
                calendarDay: today,
                taskData: taskData,
                isSelected: true,
                onTap: { _ in }
            )
        }

        Text("Preview: Empty day, tasks day, today selected")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .spacingPadding(.spacing4)
}