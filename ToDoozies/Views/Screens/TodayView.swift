//
//  TodayView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.diContainer) private var container
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private var viewModel: TodayViewModel {
        container?.todayViewModel ?? TodayViewModel(
            appState: AppState(),
            taskService: TaskService(modelContext: ModelContext.preview, appState: AppState()),
            habitService: HabitService(modelContext: ModelContext.preview, appState: AppState())
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Section
                    headerSection
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Today's overview")

                    // Overdue Tasks (if any)
                    if viewModel.shouldShowOverdueSection() {
                        overdueSection
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Overdue tasks")
                            .accessibilityHint("Tasks that are past their due date")
                    }

                    // Recurring Tasks Progress
                    if viewModel.shouldShowProgressSection() {
                        recurringTasksSection
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Daily habit progress")
                            .accessibilityValue(habitProgressDescription)
                            .accessibilityHint("Shows completion status of recurring habits")
                    }

                    // Today's Tasks
                    todayTasksSection
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Today's tasks")
                        .accessibilityValue(todayTasksDescription)
                        .accessibilityHint("Tasks scheduled for today")

                    // Tomorrow Preview (if any)
                    if viewModel.shouldShowTomorrowPreview() {
                        tomorrowPreviewSection
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Tomorrow's preview")
                            .accessibilityHint("Upcoming tasks for tomorrow")
                    }
                }
                .padding()
            }
            .accessibilityLabel("Today's tasks and habits")
            .accessibilityHint("Swipe to navigate through your daily tasks and habits")
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        container?.navigationCoordinator.showAddTask()
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new task")
                    .accessibilityHint("Create a new task or habit")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greetingText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(todayDateText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Spacer()

                if viewModel.isAllCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }

            Text(viewModel.dailySummaryText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Overdue",
                systemImage: "exclamationmark.triangle.fill",
                color: .red
            )

            ForEach(viewModel.overdueTasks) { task in
                TaskRowView(task: task) {
                    viewModel.completeTask(task)
                } onEdit: {
                    container?.navigationCoordinator.showEditTask(task)
                }
                .contextMenu {
                    taskContextMenu(for: task)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Recurring Tasks Section

    private var recurringTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Daily Habits",
                systemImage: "flame.fill",
                color: .orange
            )

            // Progress bar
            HStack {
                Text(viewModel.progressText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(viewModel.dailyProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            ProgressView(value: viewModel.dailyProgress)
                .tint(.orange)

            // Recurring tasks
            ForEach(viewModel.recurringTasks) { task in
                HabitTaskRowView(task: task) {
                    viewModel.completeTask(task)
                } onEdit: {
                    container?.navigationCoordinator.showEditTask(task)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Today Tasks Section

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Today's Tasks",
                systemImage: "calendar",
                color: .blue
            )

            if viewModel.todayTasks.isEmpty {
                emptyStateView(
                    title: "No tasks for today",
                    subtitle: "Add a task to get started",
                    systemImage: "checkmark.circle"
                )
            } else {
                ForEach(viewModel.todayTasks) { task in
                    TaskRowView(task: task) {
                        viewModel.completeTask(task)
                    } onEdit: {
                        container?.navigationCoordinator.showEditTask(task)
                    }
                    .contextMenu {
                        taskContextMenu(for: task)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Tomorrow Preview Section

    private var tomorrowPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(
                    title: "Tomorrow",
                    systemImage: "sun.max",
                    color: .yellow
                )

                Spacer()

                Button("View All") {
                    container?.navigationCoordinator.selectTab(.tasks)
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }

            ForEach(viewModel.tomorrowTasksPreview) { task in
                TaskRowView(task: task, isPreview: true) {
                    // Preview tasks can't be completed
                } onEdit: {
                    container?.navigationCoordinator.showEditTask(task)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, systemImage: String, color: Color) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    private func emptyStateView(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }

    private func taskContextMenu(for task: Task) -> some View {
        Group {
            Button("Edit") {
                container?.navigationCoordinator.showEditTask(task)
            }

            Button("Duplicate") {
                // TODO: Implement task duplication
            }

            if task.isOverdue {
                Button("Reschedule to Tomorrow") {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    viewModel.rescheduleOverdueTask(task, to: tomorrow)
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                viewModel.deleteTask(task)
            }
        }
    }

    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Accessibility Descriptions

    private var habitProgressDescription: String {
        let completedHabits = viewModel.appState.activeHabits.filter { $0.isCompletedToday }.count
        let totalHabits = viewModel.appState.activeHabits.count

        if totalHabits == 0 {
            return "No habits configured"
        }

        return "\(completedHabits) of \(totalHabits) habits completed today"
    }

    private var todayTasksDescription: String {
        let todayTasks = viewModel.todayTasks
        let completedCount = todayTasks.filter { $0.isCompleted }.count
        let totalCount = todayTasks.count

        if totalCount == 0 {
            return "No tasks for today"
        }

        return "\(completedCount) of \(totalCount) tasks completed"
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: Task
    var isPreview: Bool = false
    let onComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button(action: onComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .disabled(isPreview)
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            .accessibilityHint(task.isCompleted ? "Double tap to mark task as incomplete" : "Double tap to complete this task")

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }

                    if task.priority != .medium {
                        priorityBadge(task.priority)
                    }

                    Spacer()

                    if let subtasks = task.subtasks, !subtasks.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                            Text("\(subtasks.filter { $0.isComplete }.count)/\(subtasks.count)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Task options")
            .accessibilityHint("Double tap to view task options and details")
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(task.accessibilityLabel)
        .accessibilityValue(task.accessibilityValue)
        .accessibilityHint(task.accessibilityHint)
        .accessibilityAction(named: "Complete Task") {
            onComplete()
        }
        .accessibilityAction(named: "Edit Task") {
            onEdit()
        }
    }

    private func priorityBadge(_ priority: Priority) -> some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor(priority).opacity(0.2))
            .foregroundColor(priorityColor(priority))
            .clipShape(Capsule())
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Habit Task Row View

struct HabitTaskRowView: View {
    let task: Task
    let onComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion button with flame icon for habits
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 28, height: 28)

                    Image(systemName: task.isCompleted ? "flame.fill" : "flame")
                        .font(.caption)
                        .foregroundColor(task.isCompleted ? .white : .gray)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                // Show streak info if available
                // TODO: Get streak from habit
                Text("🔥 5 day streak")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    TodayView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}