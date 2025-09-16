//
//  CalendarTabView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI
import SwiftData

struct CalendarTabView: View {
    @Environment(\.diContainer) private var container
    @State private var selectedViewMode: CalendarViewMode = .heatmap
    @State private var selectedRange: CalendarRange = .month
    @State private var selectedHabit: Habit?
    @State private var showingExportOptions = false

    private var appState: AppState {
        container?.appState ?? AppState()
    }

    private var availableHabits: [Habit] {
        appState.habits.filter { !$0.completionDates.isEmpty }
    }

    private var allTasks: [Task] {
        appState.tasks
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Controls section
                controlsSection

                // Main calendar content
                ScrollView {
                    VStack(spacing: .spacing5) {
                        switch selectedViewMode {
                        case .heatmap:
                            habitHeatmapSection

                        case .streakChain:
                            habitStreakChainSection

                        case .taskOverview:
                            taskCalendarSection
                        }
                    }
                    .spacingPadding(.spacing4)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export calendar")
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(tasks: allTasks, habits: availableHabits)
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: .spacing3) {
            // View mode selector
            viewModeSelector

            // Range selector (for heatmap view)
            if selectedViewMode == .heatmap {
                rangeSelector
            }

            // Habit selector (for habit-specific views)
            if selectedViewMode != .taskOverview {
                habitSelector
            }
        }
        .spacingPadding(.spacing4)
        .background(Color(.systemGray6))
    }

    private var viewModeSelector: some View {
        VStack(alignment: .leading, spacing: .spacing2) {
            Text("View Mode")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("View Mode", selection: $selectedViewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var rangeSelector: some View {
        VStack(alignment: .leading, spacing: .spacing2) {
            Text("Time Range")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Range", selection: $selectedRange) {
                ForEach(CalendarRange.allCases, id: \.self) { range in
                    Text(range.displayName)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var habitSelector: some View {
        VStack(alignment: .leading, spacing: .spacing2) {
            Text("Select Habit")
                .font(.caption)
                .foregroundColor(.secondary)

            if availableHabits.isEmpty {
                Text("No habits with completion data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Menu {
                    ForEach(availableHabits) { habit in
                        Button(habit.baseTask?.title ?? "Untitled Habit") {
                            selectedHabit = habit
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedHabit?.baseTask?.title ?? "Select a habit")
                            .foregroundColor(selectedHabit != nil ? .primary : .secondary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .spacingPadding(.spacing3)
                    .background(Color(.systemBackground))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .onAppear {
                    if selectedHabit == nil && !availableHabits.isEmpty {
                        selectedHabit = availableHabits.first
                    }
                }
            }
        }
    }

    // MARK: - Calendar Content Sections

    private var habitHeatmapSection: some View {
        Group {
            if let habit = selectedHabit {
                VStack(spacing: .spacing4) {
                    sectionHeader(
                        title: "Habit Heatmap",
                        subtitle: habit.baseTask?.title ?? "Habit",
                        icon: "flame.fill"
                    )

                    HeatmapCalendarView(
                        habit: habit,
                        displayRange: selectedRange
                    )
                }
            } else {
                emptyHabitState(
                    title: "No Habit Selected",
                    message: "Select a habit to view its completion heatmap"
                )
            }
        }
    }

    private var habitStreakChainSection: some View {
        Group {
            if let habit = selectedHabit {
                VStack(spacing: .spacing4) {
                    sectionHeader(
                        title: "Streak Chain",
                        subtitle: habit.baseTask?.title ?? "Habit",
                        icon: "link"
                    )

                    StreakChainView(
                        habit: habit,
                        timeRange: timeRangeForStreakChain
                    )
                    .cardStyle()
                }
            } else {
                emptyHabitState(
                    title: "No Habit Selected",
                    message: "Select a habit to view its streak chain"
                )
            }
        }
    }

    private var taskCalendarSection: some View {
        VStack(spacing: .spacing4) {
            sectionHeader(
                title: "Task Calendar",
                subtitle: "Tasks by date",
                icon: "calendar"
            )

            TaskCalendarView(tasks: allTasks)
                .cardStyle()
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, subtitle: String, icon: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing1) {
                HStack(spacing: .spacing2) {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .font(.title3)

                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .horizontalSpacingPadding(.spacing4)
    }

    private func emptyHabitState(title: String, message: String) -> some View {
        VStack(spacing: .spacing4) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: .spacing2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if availableHabits.isEmpty {
                Button("Create Your First Habit") {
                    container?.navigationCoordinator.selectTab(.habits)
                    container?.navigationCoordinator.showAddHabit()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .spacingPadding(.spacing8)
        .cardStyle()
    }

    // MARK: - Computed Properties

    private var timeRangeForStreakChain: Int {
        switch selectedRange {
        case .month:
            return 30
        case .quarter:
            return 90
        case .year:
            return 365
        }
    }
}

// MARK: - Preview

#Preview {
    let previewTask1 = Task(
        title: "Daily Exercise",
        description: "30 minutes of exercise",
        dueDate: Date(),
        priority: .high
    )

    let previewTask2 = Task(
        title: "Read 30 Minutes",
        description: "Read for personal development",
        dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
        priority: .medium
    )

    let previewHabit1 = Habit(
        baseTask: previewTask1,
        targetCompletionsPerPeriod: 1
    )

    let previewHabit2 = Habit(
        baseTask: previewTask2,
        targetCompletionsPerPeriod: 1
    )

    // Add some sample completion data
    let calendar = Calendar.current
    let today = Date()

    for i in 0..<20 {
        if let date = calendar.date(byAdding: .day, value: -i, to: today) {
            if i % 3 != 0 {
                previewHabit1.markCompleted(on: date)
            }
            if i % 4 != 0 {
                previewHabit2.markCompleted(on: date)
            }
        }
    }

    let previewContainer = DIContainer(modelContext: ModelContext.preview)
    previewContainer.appState.setTasks([previewTask1, previewTask2])
    previewContainer.appState.setHabits([previewHabit1, previewHabit2])

    return CalendarTabView()
        .inject(previewContainer)
}