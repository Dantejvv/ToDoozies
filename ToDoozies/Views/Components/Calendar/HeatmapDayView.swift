//
//  HeatmapDayView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct HeatmapDayView: View {
    let calendarDay: CalendarDay
    let habitData: HabitCalendarData
    let isSelected: Bool
    let onTap: (Date) -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var completionIntensity: Double {
        habitData.completionIntensity(for: calendarDay.date)
    }

    private var isCompleted: Bool {
        habitData.isCompleted(on: calendarDay.date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: calendarDay.date)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.3)
        } else if isCompleted {
            return Color.habitIntensityColor(for: completionIntensity)
        } else {
            return Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor
        } else if calendarDay.isToday {
            return Color.primary
        } else {
            return Color.clear
        }
    }

    private var textColor: Color {
        if !calendarDay.isInCurrentMonth {
            return Color(.systemGray3)
        } else if isCompleted && completionIntensity > 0.5 {
            return Color.white
        } else {
            return Color.primary
        }
    }

    var body: some View {
        Button(action: {
            onTap(calendarDay.date)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .stroke(borderColor, lineWidth: isSelected || calendarDay.isToday ? 2 : 0)
                    )

                VStack(spacing: .spacing1) {
                    Text(dayNumber)
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 12 : 14, weight: .medium))
                        .foregroundColor(textColor)

                    // Streak indicator for completed days
                    if isCompleted && completionIntensity > 0.7 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .frame(width: cellSize, height: cellSize)
        .disabled(!calendarDay.isInCurrentMonth)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Select date") {
            onTap(calendarDay.date)
        }
    }

    // MARK: - Computed Properties

    private var cellSize: CGFloat {
        // Adjust cell size based on Dynamic Type
        let baseSize: CGFloat = 40
        let sizeMultiplier = dynamicTypeSize.isAccessibilitySize ? 1.2 : 1.0
        return baseSize * sizeMultiplier
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

        if isCompleted {
            let streakCount = habitData.habit.streakOnDate(calendarDay.date)
            if streakCount > 1 {
                return "Completed. Part of \(streakCount) day streak"
            } else {
                return "Completed"
            }
        } else {
            return "Not completed"
        }
    }

    private var accessibilityHint: String {
        if !calendarDay.isInCurrentMonth {
            return ""
        }
        return "Double tap to view details for this date"
    }
}

// MARK: - Preview

#Preview {
    let previewHabit = Habit(
        baseTask: Task(title: "Morning Exercise", priority: .high),
        targetCompletionsPerPeriod: 1
    )

    // Add some completion dates for preview
    previewHabit.markCompleted(on: Date())
    previewHabit.markCompleted(on: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    previewHabit.markCompleted(on: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date())

    let habitData = HabitCalendarData(habit: previewHabit)
    let today = CalendarDay(date: Date(), currentMonth: Date())

    return VStack(spacing: .spacing4) {
        HStack(spacing: .spacing2) {
            HeatmapDayView(
                calendarDay: CalendarDay(
                    date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    currentMonth: Date()
                ),
                habitData: habitData,
                isSelected: false,
                onTap: { _ in }
            )

            HeatmapDayView(
                calendarDay: CalendarDay(
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    currentMonth: Date()
                ),
                habitData: habitData,
                isSelected: false,
                onTap: { _ in }
            )

            HeatmapDayView(
                calendarDay: today,
                habitData: habitData,
                isSelected: true,
                onTap: { _ in }
            )
        }

        Text("Preview: Past 3 days with completions")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .spacingPadding(.spacing4)
}