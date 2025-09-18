//
//  HabitDetailView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/16/25.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.diContainer) private var diContainer
    @Environment(\.habitNavigation) private var habitNavigationModel
    @State private var viewModel: HabitDetailViewModel?

    let habit: Habit

    var body: some View {
        Group {
            if let viewModel = viewModel {
                HabitDetailContentView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil, let container = diContainer {
                viewModel = container.makeHabitDetailViewModel(habit: habit)
            }
        }
    }
}

struct HabitDetailContentView: View {
    @Bindable var viewModel: HabitDetailViewModel
    @Environment(\.habitNavigation) private var habitNavigationModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                habitHeaderSection

                // Streak Section
                streakSection

                // Statistics Section
                statisticsSection

                // Description Section
                if let description = viewModel.description, !description.isEmpty {
                    descriptionSection(description)
                }

                // Calendar Section
                calendarSection

                // Protection Days Section
                protectionDaysSection

                // Details Section
                detailsSection

                // Actions Section
                actionsSection

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(content: {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit") {
                    habitNavigationModel?.showEdit(viewModel.habit)
                }

                Menu {
                    Button("Delete", role: .destructive) {
                        viewModel.showDeleteAlert()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        })
        .refreshable {
            await viewModel.refreshHabit()
        }
        .alert("Delete Habit", isPresented: $viewModel.showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                _Concurrency.Task { await viewModel.deleteHabit() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(viewModel.title)'? This will also delete the associated task and all completion data. This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            }
        }
    }

    // MARK: - Header Section

    private var habitHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    _Concurrency.Task { await viewModel.toggleTodayCompletion() }
                }) {
                    Image(systemName: viewModel.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(viewModel.isCompletedToday ? .green : .gray)
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel(viewModel.completionStatusAccessibilityLabel)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .strikethrough(viewModel.isCompletedToday)
                        .foregroundColor(viewModel.isCompletedToday ? .secondary : .primary)

                    Label("Daily Habit", systemImage: "repeat.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                if viewModel.isCompletedToday {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .accessibilityLabel("Completed today")
                }
            }
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak")
                .font(.headline)
                .fontWeight(.medium)

            HStack(spacing: 16) {
                StreakBadge(streakCount: viewModel.currentStreak, type: .current)
                    .accessibilityLabel(viewModel.streakAccessibilityDescription)

                if viewModel.bestStreak > 0 {
                    StreakBadge(streakCount: viewModel.bestStreak, type: .best)
                }

                Spacer()
            }

            if viewModel.currentStreak > 0 {
                Text(viewModel.streakDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.medium)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statisticCard(
                    title: "Total Completions",
                    value: "\(viewModel.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                statisticCard(
                    title: "Completion Rate",
                    value: viewModel.formattedCompletionRate,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                statisticCard(
                    title: "Weekly Average",
                    value: viewModel.formattedWeeklyAverage,
                    icon: "calendar.badge.clock",
                    color: .purple
                )

                statisticCard(
                    title: "This Month",
                    value: viewModel.formattedMonthlyRate,
                    icon: "calendar.circle",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .fontWeight(.medium)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
                .fontWeight(.medium)

            // Simple calendar grid showing completion status
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    calendarDayView(date)
                }
            }

            HStack {
                Text("Tap a day to toggle completion")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(viewModel.completionDatesInCurrentMonth.count) days completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func calendarDayView(_ date: Date) -> some View {
        let isCompleted = viewModel.isDateCompleted(date)
        let isToday = Calendar.current.isDateInToday(date)
        let dayNumber = Calendar.current.component(.day, from: date)

        return Button(action: {
            _Concurrency.Task {
                await viewModel.toggleCompletionForDate(date)
            }
        }) {
            Text("\(dayNumber)")
                .font(.caption)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(isCompleted ? .white : (isToday ? Color.accentColor : .primary))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isCompleted ? .green : (isToday ? Color.accentColor.opacity(0.2) : .clear))
                )
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.accentColor : .clear, lineWidth: 2)
                )
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel("Day \(dayNumber)")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle completion")
    }

    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return []
        }

        var days: [Date] = []
        var currentDate = monthInterval.start

        while currentDate <= monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    // MARK: - Protection Days Section

    private var protectionDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protection Days")
                .font(.headline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.protectionDaysText)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Protection days help maintain your streak when you miss a day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                if viewModel.canUseProtectionDay {
                    Button("Use Protection Day") {
                        _Concurrency.Task {
                            await viewModel.useProtectionDay()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel(viewModel.protectionDayAccessibilityLabel)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .fontWeight(.medium)

            VStack(spacing: 12) {
                metadataRow(
                    icon: "calendar.badge.plus",
                    title: "Created",
                    value: viewModel.habit.createdDate.formatted(date: .abbreviated, time: .shortened)
                )

                if viewModel.habit.modifiedDate != viewModel.habit.createdDate {
                    metadataRow(
                        icon: "pencil",
                        title: "Modified",
                        value: viewModel.habit.modifiedDate.formatted(date: .abbreviated, time: .shortened)
                    )
                }

                metadataRow(
                    icon: "clock",
                    title: "Days Active",
                    value: "\(viewModel.daysSinceCreation) days"
                )

                if let lastProtectionDate = viewModel.habit.lastProtectionDate {
                    metadataRow(
                        icon: "shield",
                        title: "Last Protection Used",
                        value: lastProtectionDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metadataRow(icon: String, title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                _Concurrency.Task { await viewModel.toggleTodayCompletion() }
            }) {
                HStack {
                    Image(systemName: viewModel.isCompletedToday ? "xmark.circle" : "checkmark.circle.fill")
                    Text(viewModel.isCompletedToday ? "Mark Incomplete for Today" : "Mark Complete for Today")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            HStack(spacing: 12) {
                Button("Edit Habit") {
                    habitNavigationModel?.showEdit(viewModel.habit)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Delete Habit") {
                    viewModel.showDeleteAlert()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit.preview)
    }
    .inject(DIContainer(modelContext: ModelContext.preview))
}

// MARK: - Preview Support

extension Habit {
    static var preview: Habit {
        let task = Task(
            title: "Morning Meditation",
            description: "10 minutes of mindfulness meditation to start the day",
            priority: .medium
        )

        let habit = Habit(baseTask: task)

        // Add some sample completion dates
        let calendar = Calendar.current
        let today = Date()
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                habit.markCompleted(on: date)
            }
        }

        return habit
    }
}