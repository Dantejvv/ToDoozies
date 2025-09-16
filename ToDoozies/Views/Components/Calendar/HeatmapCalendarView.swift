//
//  HeatmapCalendarView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct HeatmapCalendarView: View {
    let habit: Habit
    let displayRange: CalendarRange
    @State private var selectedDate: Date?
    @State private var currentMonth: Date = Date()

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current

    private var habitData: HabitCalendarData {
        HabitCalendarData(habit: habit)
    }

    private var monthsToDisplay: [Date] {
        let baseDate = currentMonth
        let numberOfMonths = displayRange.numberOfMonths

        var months: [Date] = []
        for i in 0..<numberOfMonths {
            if let month = calendar.date(byAdding: .month, value: i, to: baseDate) {
                months.append(month)
            }
        }
        return months
    }

    private var dateRange: ClosedRange<Date> {
        calendar.dateRange(for: displayRange, from: currentMonth)
    }

    private var completionRate: Double {
        habitData.completionRate(for: dateRange)
    }

    var body: some View {
        VStack(spacing: .spacing4) {
            // Header with navigation and stats
            headerView

            // Calendar grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: .spacing6) {
                    ForEach(monthsToDisplay, id: \.self) { month in
                        monthView(for: month)
                    }
                }
                .spacingPadding(.spacing4)
            }

            // Legend
            legendView
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: displayRange) { _, _ in
            selectedDate = nil
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: .spacing3) {
            // Navigation and title
            HStack {
                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Previous \(displayRange.displayName.lowercased())")

                Spacer()

                VStack {
                    Text(habit.baseTask?.title ?? "Habit")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(monthRangeTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: navigateNext) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Next \(displayRange.displayName.lowercased())")
            }

            // Statistics row
            HStack(spacing: .spacing6) {
                StatBadge(
                    title: "Current Streak",
                    value: "\(habit.currentStreak)",
                    color: .orange
                )

                StatBadge(
                    title: "Best Streak",
                    value: "\(habit.bestStreak)",
                    color: .blue
                )

                StatBadge(
                    title: "Completion Rate",
                    value: "\(Int(completionRate * 100))%",
                    color: .green
                )
            }
        }
        .horizontalSpacingPadding(.spacing4)
    }

    private var monthRangeTitle: String {
        let formatter = DateFormatter()

        switch displayRange {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: currentMonth)

        case .quarter:
            formatter.dateFormat = "MMMM"
            let startMonth = formatter.string(from: dateRange.lowerBound)
            let endMonth = formatter.string(from: dateRange.upperBound)
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: currentMonth)
            return "\(startMonth) - \(endMonth) \(year)"

        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: currentMonth)
        }
    }

    // MARK: - Month View

    private func monthView(for month: Date) -> some View {
        VStack(spacing: .spacing3) {
            // Month header
            HStack {
                Text(monthTitle(for: month))
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                // Month completion rate
                let monthRange = calendar.dateRange(for: .month, from: month)
                let monthRate = habitData.completionRate(for: monthRange)
                Text("\(Int(monthRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .horizontalSpacingPadding(.spacing2)

            // Weekday headers
            weekdayHeadersView

            // Calendar grid
            let monthGrid = calendar.monthGrid(for: month)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: .spacing2) {
                ForEach(0..<min(monthGrid.count * 7, 42), id: \.self) { index in
                    let weekIndex = index / 7
                    let dayIndex = index % 7

                    if weekIndex < monthGrid.count && dayIndex < monthGrid[weekIndex].count {
                        let calendarDay = monthGrid[weekIndex][dayIndex]
                        HeatmapDayView(
                            calendarDay: calendarDay,
                            habitData: habitData,
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
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .cardStyle()
        .spacingPadding(.spacing4)
    }

    private func monthTitle(for month: Date) -> String {
        let formatter = DateFormatter()
        if displayRange == .month {
            return "" // Already shown in header
        } else {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: month)
        }
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
        .horizontalSpacingPadding(.spacing2)
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: .spacing4) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: .spacing1) {
                ForEach([0.0, 0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.habitIntensityColor(for: intensity))
                        .frame(width: 12, height: 12)
                }
            }

            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            if let selectedDate = selectedDate {
                selectedDateInfo(for: selectedDate)
            }
        }
        .horizontalSpacingPadding(.spacing4)
        .verticalSpacingPadding(.spacing3)
        .background(Color(.systemGray6))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .horizontalSpacingPadding(.spacing4)
    }

    private func selectedDateInfo(for date: Date) -> some View {
        let isCompleted = habitData.isCompleted(on: date)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)

        return HStack(spacing: .spacing2) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .secondary)

            Text(dateString)
                .font(.caption)
                .foregroundColor(.primary)

            if isCompleted {
                let streak = habit.streakOnDate(date)
                Text("• \(streak) day streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func selectDate(_ date: Date) {
        selectedDate = selectedDate == date ? nil : date
    }

    private func navigatePrevious() {
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
            switch displayRange {
            case .month:
                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            case .quarter:
                currentMonth = calendar.date(byAdding: .month, value: -3, to: currentMonth) ?? currentMonth
            case .year:
                currentMonth = calendar.date(byAdding: .year, value: -1, to: currentMonth) ?? currentMonth
            }
        }
    }

    private func navigateNext() {
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
            switch displayRange {
            case .month:
                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            case .quarter:
                currentMonth = calendar.date(byAdding: .month, value: 3, to: currentMonth) ?? currentMonth
            case .year:
                currentMonth = calendar.date(byAdding: .year, value: 1, to: currentMonth) ?? currentMonth
            }
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .smallCardStyle()
        .spacingPadding(.spacing3)
    }
}

// MARK: - Preview

#Preview {
    let previewTask = Task(
        title: "Daily Exercise",
        description: "30 minutes of exercise every day",
        priority: .high
    )

    let previewHabit = Habit(
        baseTask: previewTask,
        targetCompletionsPerPeriod: 1
    )

    // Add some sample completion dates
    let calendar = Calendar.current
    let today = Date()

    for i in 0..<20 {
        if let date = calendar.date(byAdding: .day, value: -i, to: today) {
            // Simulate 70% completion rate with some streaks
            if i % 3 != 0 || i < 5 {
                previewHabit.markCompleted(on: date)
            }
        }
    }

    return NavigationStack {
        HeatmapCalendarView(
            habit: previewHabit,
            displayRange: .month
        )
        .navigationTitle("Habit Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}