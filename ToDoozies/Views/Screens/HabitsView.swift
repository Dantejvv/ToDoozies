//
//  HabitsView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.diContainer) private var container
    @Environment(\.habitNavigation) private var habitNavigation
    @Environment(\.appNavigation) private var appNavigation
    @State private var showingAddHabit = false

    private var viewModel: HabitsViewModel {
        container?.habitsViewModel ?? HabitsViewModel(
            appState: AppState(),
            habitService: HabitService(modelContext: ModelContext.preview, appState: AppState()),
            taskService: TaskService(modelContext: ModelContext.preview, appState: AppState())
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: .spacing5) {
                    // Header with today's progress
                    todayProgressSection


                    // Habits grid/list
                    if viewModel.displayedHabits.isEmpty {
                        emptyStateView
                    } else {
                        habitsSection
                    }

                    // Statistics overview
                    if !viewModel.displayedHabits.isEmpty {
                        statisticsSection
                    }
                }
                .spacingPadding(.spacing4)
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { viewModel.toggleCalendarView() }) {
                        Image(systemName: viewModel.showingCalendarView ? "list.bullet" : "calendar")
                    }

                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .habitNavigation(habitNavigation ?? HabitNavigationModel())
            .appNavigation(container?.appNavigation ?? AppNavigationModel())
        }
    }

    // MARK: - Today Progress Section

    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(viewModel.todayProgressText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CircularProgressView(
                    progress: viewModel.todayCompletionRate,
                    size: 60,
                    lineWidth: 6
                )
            }

            if !viewModel.habitsForToday.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.habitsForToday) { habit in
                            TodayHabitCard(habit: habit) {
                                viewModel.completeHabit(habit)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .spacingPadding(.spacing4)
        .cardStyle()
    }


    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            HStack {
                Text("Your Habits")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                timeRangePicker
            }

            if viewModel.showingCalendarView {
                habitsCalendarView
            } else {
                habitsListView
            }
        }
        .spacingPadding(.spacing4)
        .cardStyle()
    }

    // MARK: - Habits List View

    private var habitsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.displayedHabits) { habit in
                HabitRowView(habit: habit, viewModel: viewModel) {
                    if habit.isCompletedToday {
                        viewModel.uncompleteHabit(habit)
                    } else {
                        viewModel.completeHabit(habit)
                    }
                } onTap: {
                    habitNavigation?.showDetail(habit)
                }
                .contextMenu {
                    habitContextMenu(for: habit)
                }
            }
        }
    }

    // MARK: - Habits Calendar View

    private var habitsCalendarView: some View {
        VStack(spacing: .spacing4) {
            if viewModel.displayedHabits.isEmpty {
                emptyCalendarState
            } else {
                habitsCalendarContent
            }
        }
    }

    private var emptyCalendarState: some View {
        VStack(spacing: .spacing4) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: .spacing2) {
                Text("No Habits to Display")
                    .font(.headline)
                    .fontWeight(.medium)

                Text("Create habits to see their completion patterns in calendar view")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Add Your First Habit") {
                viewModel.showAddHabit()
            }
            .buttonStyle(.borderedProminent)
        }
        .spacingPadding(.spacing6)
    }

    private var habitsCalendarContent: some View {
        LazyVStack(spacing: .spacing5) {
            ForEach(viewModel.displayedHabits.prefix(3)) { habit in
                VStack(spacing: .spacing3) {
                    // Habit header
                    HStack {
                        VStack(alignment: .leading, spacing: .spacing1) {
                            Text(habit.baseTask?.title ?? "Habit")
                                .font(.headline)
                                .fontWeight(.semibold)

                            HStack(spacing: .spacing4) {
                                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)

                                Label("\(habit.totalCompletions) total", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()

                        Button("View Details") {
                            habitNavigation?.showDetail(habit)
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }

                    // Mini heatmap (last 30 days)
                    miniHeatmapView(for: habit)
                        .onTapGesture {
                            // Navigate to full calendar view
                            appNavigation?.selectTab(.calendar)
                        }
                }
                .spacingPadding(.spacing4)
                .cardStyle()
            }

            // Show more button if there are more habits
            if viewModel.displayedHabits.count > 3 {
                Button("View All in Calendar") {
                    appNavigation?.selectTab(.calendar)
                }
                .foregroundColor(.accentColor)
                .font(.subheadline)
            }
        }
    }

    private func miniHeatmapView(for habit: Habit) -> some View {
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        let habitData = HabitCalendarData(habit: habit)

        return VStack(spacing: .spacing2) {
            HStack {
                Text("Last 30 Days")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                let completedDays = (0..<30).count { i in
                    guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return false }
                    return habitData.isCompleted(on: date)
                }

                Text("\(completedDays)/30 days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            LazyHGrid(rows: Array(repeating: GridItem(.flexible(), spacing: 2), count: 6), spacing: 2) {
                ForEach(0..<30, id: \.self) { dayOffset in
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
                    let isCompleted = habitData.isCompleted(on: date)
                    let intensity = isCompleted ? habitData.completionIntensity(for: date) : 0.0

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.habitIntensityColor(for: intensity))
                        .frame(width: 12, height: 12)
                        .accessibilityLabel("\(dayOffset == 0 ? "Today" : "\(dayOffset) days ago"): \(isCompleted ? "Completed" : "Not completed")")
                }
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Active Streaks",
                    value: "\(viewModel.activeStreaksCount)",
                    systemImage: "flame.fill",
                    color: .orange
                )

                if let topHabit = viewModel.topStreakHabit {
                    StatCard(
                        title: "Longest Streak",
                        value: "\(topHabit.currentStreak) days",
                        systemImage: "crown.fill",
                        color: .yellow
                    )
                }

                if let bestHabit = viewModel.bestPerformingHabit {
                    StatCard(
                        title: "Best Habit",
                        value: "\(Int(bestHabit.completionRate * 100))%",
                        systemImage: "star.fill",
                        color: .green
                    )
                }

                StatCard(
                    title: "Total Habits",
                    value: "\(viewModel.displayedHabits.count)",
                    systemImage: "list.bullet",
                    color: .blue
                )
            }
        }
        .spacingPadding(.spacing4)
        .cardStyle()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            VStack(spacing: .spacing2) {
                Text("Start Building Habits")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first habit to begin tracking your daily progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Add Habit") {
                showingAddHabit = true
            }
            .buttonStyle(.borderedProminent)
        }
        .spacingPadding(.spacing4)
        .cardStyle()
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Menu {
            ForEach(HabitTimeRange.allCases, id: \.self) { range in
                Button {
                    viewModel.setTimeRange(range)
                } label: {
                    HStack {
                        Text(range.displayName)
                        if viewModel.selectedTimeRange == range {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedTimeRange.displayName)
                Image(systemName: "chevron.down")
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Context Menu

    private func habitContextMenu(for habit: Habit) -> some View {
        Group {
            Button("View Details") {
                habitNavigation?.showDetail(habit)
            }

            Button("Edit") {
                habitNavigation?.showEdit(habit)
            }

            if !habit.isCompletedToday {
                Button("Mark Complete") {
                    viewModel.completeHabit(habit)
                }
            } else {
                Button("Mark Incomplete") {
                    viewModel.uncompleteHabit(habit)
                }
            }

            if habit.availableProtectionDays > 0 {
                Button("Use Protection Day") {
                    _ = viewModel.useProtectionDay(for: habit)
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                viewModel.deleteHabit(habit)
            }
        }
    }
}

// MARK: - Today Habit Card

struct TodayHabitCard: View {
    let habit: Habit
    let onComplete: () -> Void

    var body: some View {
        Button(action: onComplete) {
            VStack(spacing: .spacing2) {
                CompletionButton(
                    isCompleted: habit.isCompletedToday,
                    style: .habit,
                    accessibilityLabel: habit.isCompletedToday ? "Mark incomplete" : "Mark complete"
                ) {
                    onComplete()
                }
                .scaleEffect(1.2)

                VStack(spacing: 2) {
                    Text(habit.baseTask?.title ?? "Habit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    if habit.currentStreak > 0 {
                        Text("\(habit.currentStreak) 🔥")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(width: 80)
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Habit Row View

struct HabitRowView: View {
    let habit: Habit
    let viewModel: HabitsViewModel
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion button
                CompletionButton(
                    isCompleted: habit.isCompletedToday,
                    style: .habit,
                    accessibilityLabel: habit.isCompletedToday ? "Mark incomplete" : "Mark complete"
                ) {
                    onToggleComplete()
                }

                // Habit info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.baseTask?.title ?? "Habit")
                        .font(.body)
                        .fontWeight(.medium)

                    HStack(spacing: 16) {
                        // Current streak
                        if habit.currentStreak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                Text("\(habit.currentStreak)")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }

                        // Completion rate
                        HStack(spacing: 2) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("\(Int(viewModel.getCompletionRate(for: habit, in: viewModel.selectedTimeRange) * 100))%")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Spacer()
                    }
                }

                Spacer()

                // Streak visualization
                StreakVisualization(
                    currentStreak: habit.currentStreak,
                    bestStreak: habit.bestStreak
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak Visualization

struct StreakVisualization: View {
    let currentStreak: Int
    let bestStreak: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                ForEach(0..<min(currentStreak, 7), id: \.self) { _ in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 4)
                }

                ForEach(0..<(7 - min(currentStreak, 7)), id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }

            if bestStreak > currentStreak {
                Text("Best: \(bestStreak)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}


// MARK: - Preview

#Preview {
    HabitsView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}
