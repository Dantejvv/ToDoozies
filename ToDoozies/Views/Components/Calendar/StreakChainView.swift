//
//  StreakChainView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct StreakChainView: View {
    let habit: Habit
    let timeRange: Int // Number of days to show
    @State private var selectedDate: Date?
    @State private var scrollOffset: CGFloat = 0

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current
    private let itemSpacing: CGFloat = 2

    private var habitData: HabitCalendarData {
        HabitCalendarData(habit: habit)
    }

    private var chainDays: [ChainDay] {
        let today = calendar.startOfDay(for: Date())
        var days: [ChainDay] = []

        for i in (0..<timeRange).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }

            let isCompleted = habitData.isCompleted(on: date)
            let streakCount = isCompleted ? habit.streakOnDate(date) : 0
            let isToday = calendar.isDateInToday(date)
            let isProtectionDay = false // TODO: Add protection day logic if needed

            days.append(ChainDay(
                date: date,
                isCompleted: isCompleted,
                isToday: isToday,
                isProtectionDay: isProtectionDay,
                streakCount: streakCount
            ))
        }

        return days
    }

    private var currentStreakRange: ClosedRange<Int>? {
        let completedDays = chainDays.enumerated().compactMap { index, day in
            day.isCompleted ? index : nil
        }

        guard !completedDays.isEmpty else { return nil }

        // Find the current streak (consecutive completed days ending today or recently)
        var streakStart = completedDays.last!
        let streakEnd = completedDays.last!

        for i in (0..<completedDays.count - 1).reversed() {
            let currentIndex = completedDays[i]
            let nextIndex = completedDays[i + 1]

            if nextIndex - currentIndex == 1 {
                streakStart = currentIndex
            } else {
                break
            }
        }

        return streakStart...streakEnd
    }

    var body: some View {
        VStack(spacing: .spacing4) {
            // Header with stats
            headerView

            // Main chain visualization
            chainScrollView

            // Selected day info
            if let selectedDate = selectedDate {
                selectedDayInfo(for: selectedDate)
            }

            // Legend
            legendView
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: .spacing3) {
            HStack {
                VStack(alignment: .leading) {
                    Text(habit.baseTask?.title ?? "Habit")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Last \(timeRange) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Current streak indicator
                HStack(spacing: .spacing2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)

                    VStack(alignment: .trailing) {
                        Text("\(habit.currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("current")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .smallCardStyle()
                .spacingPadding(.spacing3)
            }

            // Progress summary
            let completedDays = chainDays.filter { $0.isCompleted }.count
            let completionRate = Double(completedDays) / Double(timeRange)

            ProgressView(value: completionRate)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.green)
                .overlay(
                    HStack {
                        Text("\(completedDays)/\(timeRange) days")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(completionRate * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .offset(y: 12)
                )
        }
        .horizontalSpacingPadding(.spacing4)
    }

    // MARK: - Chain Scroll View

    private var chainScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: itemSpacing) {
                    ForEach(Array(chainDays.enumerated()), id: \.offset) { index, chainDay in
                        ChainDayView(
                            chainDay: chainDay,
                            isInCurrentStreak: currentStreakRange?.contains(index) ?? false,
                            isSelected: selectedDate != nil && calendar.isDate(chainDay.date, inSameDayAs: selectedDate!),
                            onTap: selectDate
                        )
                        .id(index)
                    }
                }
                .spacingPadding(.spacing4)
            }
            .onAppear {
                // Scroll to today (last item) on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.5)) {
                        proxy.scrollTo(chainDays.count - 1, anchor: .trailing)
                    }
                }
            }
        }
        .frame(height: 120)
    }

    // MARK: - Selected Day Info

    private func selectedDayInfo(for date: Date) -> some View {
        let chainDay = chainDays.first { calendar.isDate($0.date, inSameDayAs: date) }
        let formatter = DateFormatter()
        formatter.dateStyle = .full

        return VStack(spacing: .spacing2) {
            HStack {
                Image(systemName: chainDay?.isCompleted == true ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chainDay?.isCompleted == true ? .green : .secondary)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(formatter.string(from: date))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if chainDay?.isCompleted == true, let streakCount = chainDay?.streakCount, streakCount > 0 {
                        Text("Day \(streakCount) of streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Close") {
                    selectedDate = nil
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .cardStyle()
        .spacingPadding(.spacing4)
        .horizontalSpacingPadding(.spacing4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Selected day details")
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: .spacing4) {
            LegendItem(
                color: .green,
                symbol: "checkmark.circle.fill",
                text: "Completed"
            )

            LegendItem(
                color: .orange,
                symbol: "flame.fill",
                text: "Streak"
            )

            LegendItem(
                color: .secondary,
                symbol: "circle",
                text: "Missed"
            )

            Spacer()
        }
        .horizontalSpacingPadding(.spacing4)
    }

    // MARK: - Actions

    private func selectDate(_ date: Date) {
        selectedDate = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!) ? nil : date
    }
}

// MARK: - Supporting Types

private struct ChainDay {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    let isProtectionDay: Bool
    let streakCount: Int
}

// MARK: - Chain Day View

private struct ChainDayView: View {
    let chainDay: ChainDay
    let isInCurrentStreak: Bool
    let isSelected: Bool
    let onTap: (Date) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var backgroundColor: Color {
        if isSelected {
            return .accentColor.opacity(0.3)
        } else if chainDay.isCompleted {
            return isInCurrentStreak ? .green : .green.opacity(0.7)
        } else {
            return Color(.systemGray5)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else if chainDay.isToday {
            return .primary
        } else {
            return .clear
        }
    }

    private var dayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: chainDay.date)
    }

    var body: some View {
        Button(action: {
            onTap(chainDay.date)
        }) {
            VStack(spacing: .spacing1) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: isSelected || chainDay.isToday ? 2 : 0)
                        )

                    if chainDay.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text(dayText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // Streak indicator
                if chainDay.isCompleted && isInCurrentStreak {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                } else {
                    Spacer()
                        .frame(height: 12)
                }

                // Day of week
                Text(dayOfWeekText)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var dayOfWeekText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: chainDay.date)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: chainDay.date)

        if chainDay.isToday {
            return "Today, \(dateString)"
        } else {
            return dateString
        }
    }

    private var accessibilityValue: String {
        if chainDay.isCompleted {
            if chainDay.streakCount > 1 {
                return "Completed. Day \(chainDay.streakCount) of streak"
            } else {
                return "Completed"
            }
        } else {
            return "Not completed"
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: .spacing1) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundColor(color)

            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let previewTask = Task(
        title: "Morning Meditation",
        description: "10 minutes of meditation",
        priority: .medium
    )

    let previewHabit = Habit(
        baseTask: previewTask,
        targetCompletionsPerPeriod: 1
    )

    // Create a realistic streak pattern
    let calendar = Calendar.current
    let today = Date()

    // Add completions with some gaps to show variety
    let completionPattern = [
        true, true, false, true, true, true, false, false, true, true,
        true, true, true, false, true, false, true, true, true, true,
        true, false, true, true, true, true, true, true, false, true
    ]

    for (i, shouldComplete) in completionPattern.enumerated() {
        if let date = calendar.date(byAdding: .day, value: -i, to: today), shouldComplete {
            previewHabit.markCompleted(on: date)
        }
    }

    return StreakChainView(habit: previewHabit, timeRange: 30)
        .spacingPadding(.spacing4)
}