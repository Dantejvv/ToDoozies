//
//  TaskService.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData

// MARK: - Task Service Protocol

protocol TaskServiceProtocol {
    func refreshTasks() async throws
    func createTask(_ task: Task) async throws
    func createHabit(_ habit: Habit) async throws
    func updateTask(_ task: Task) async throws
    func deleteTask(_ task: Task) async throws
    func searchTasks(query: String) async throws -> [Task]
    func getTasksForDate(_ date: Date) async throws -> [Task]
    func getOverdueTasks() async throws -> [Task]
    func bulkUpdateTasks(_ tasks: [Task]) async throws

    // TaskType filtering methods
    func getTasksByType(_ taskType: TaskType) async throws -> [Task]
    func getOneTimeTasks() async throws -> [Task]
    func getRecurringTasks() async throws -> [Task]
    func getHabitTasks() async throws -> [Task]
    func getTasksForTasksTab() async throws -> [Task]

    // Task completion methods
    func markTaskComplete(_ task: Task) async throws
    func markTaskIncomplete(_ task: Task) async throws

    // Subtask methods
    func addSubtask(_ subtask: Subtask, to task: Task) async throws
    func toggleSubtaskCompletion(_ subtask: Subtask) async throws
    func updateSubtask(_ subtask: Subtask, title: String) async throws
    func deleteSubtask(_ subtask: Subtask) async throws
    func reorderSubtasks(_ subtasks: [Subtask], from source: IndexSet, to destination: Int) async throws

    // Habit management for task conversion
    func removeHabitForTask(_ task: Task) async throws
}

// MARK: - Task Service Implementation

@MainActor
final class TaskService: TaskServiceProtocol {
    private let modelContext: ModelContext
    private let appState: AppState
    weak var diContainer: DIContainer?

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    // MARK: - CRUD Operations

    func refreshTasks() async throws {
        do {
            let descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            let tasks = try modelContext.fetch(descriptor)
            appState.setTasks(tasks)
        } catch {
            throw AppError.dataLoadingFailed("Failed to refresh tasks: \(error.localizedDescription)")
        }
    }

    func createTask(_ task: Task) async throws {
        do {
            modelContext.insert(task)
            try modelContext.save()

            // Update app state
            appState.addTask(task)

            // Track offline change
            trackOfflineChange()

            // Schedule notifications if needed
            await scheduleNotificationIfNeeded(for: task)

        } catch {
            throw AppError.dataSavingFailed("Failed to create task: \(error.localizedDescription)")
        }
    }

    func createHabit(_ habit: Habit) async throws {
        do {
            modelContext.insert(habit)
            try modelContext.save()

            // Update app state
            appState.addHabit(habit)

        } catch {
            throw AppError.dataSavingFailed("Failed to create habit: \(error.localizedDescription)")
        }
    }

    func updateTask(_ task: Task) async throws {
        do {
            task.updateModifiedDate()
            try modelContext.save()

            // Track offline change
            trackOfflineChange()

            // Update notifications
            await updateNotificationIfNeeded(for: task)

        } catch {
            throw AppError.dataSavingFailed("Failed to update task: \(error.localizedDescription)")
        }
    }

    func deleteTask(_ task: Task) async throws {
        do {
            modelContext.delete(task)
            try modelContext.save()

            // Remove from app state
            appState.removeTask(task)

            // Track offline change
            trackOfflineChange()

            // Cancel notifications
            await cancelNotificationIfNeeded(for: task)

        } catch {
            throw AppError.dataSavingFailed("Failed to delete task: \(error.localizedDescription)")
        }
    }

    // MARK: - Query Operations

    func searchTasks(query: String) async throws -> [Task] {
        guard !query.isEmpty else { return appState.tasks }

        let predicate = #Predicate<Task> { task in
            task.title.localizedStandardContains(query) ||
            (task.taskDescription?.localizedStandardContains(query) ?? false)
        }

        do {
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            throw AppError.dataLoadingFailed("Failed to search tasks: \(error.localizedDescription)")
        }
    }

    func getTasksForDate(_ date: Date) async throws -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let predicate = #Predicate<Task> { task in
            task.dueDate != nil && task.dueDate! >= startOfDay && task.dueDate! < endOfDay
        }

        do {
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\.dueDate)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            throw AppError.dataLoadingFailed("Failed to get tasks for date: \(error.localizedDescription)")
        }
    }

    func getOverdueTasks() async throws -> [Task] {
        let now = Date()

        // First get all tasks with due dates that are in the past
        let predicate = #Predicate<Task> { task in
            task.dueDate != nil && task.dueDate! < now
        }

        do {
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\.dueDate)]
            )
            let tasksWithDueDates = try modelContext.fetch(descriptor)

            // Filter out completed tasks in Swift code since predicate doesn't handle enum comparison well
            return tasksWithDueDates.filter { $0.status != .complete }
        } catch {
            throw AppError.dataLoadingFailed("Failed to get overdue tasks: \(error.localizedDescription)")
        }
    }

    // MARK: - TaskType Filtering

    func getTasksByType(_ taskType: TaskType) async throws -> [Task] {
        do {
            let descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(descriptor)

            // Filter in Swift code since SwiftData predicates have issues with enums
            return allTasks.filter { task in
                task.taskType == taskType
            }
        } catch {
            throw AppError.dataLoadingFailed("Failed to get tasks by type: \(error.localizedDescription)")
        }
    }

    func getOneTimeTasks() async throws -> [Task] {
        return try await getTasksByType(.oneTime)
    }

    func getRecurringTasks() async throws -> [Task] {
        return try await getTasksByType(.recurring)
    }

    func getHabitTasks() async throws -> [Task] {
        return try await getTasksByType(.habit)
    }

    func getTasksForTasksTab() async throws -> [Task] {
        // Tasks tab should show one-time tasks and recurring task instances
        do {
            let descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\.dueDate), SortDescriptor(\.modifiedDate, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(descriptor)

            // Filter in Swift code since SwiftData predicates have issues with enums
            return allTasks.filter { task in
                task.taskType == .oneTime || task.taskType == .recurring
            }
        } catch {
            throw AppError.dataLoadingFailed("Failed to get tasks for Tasks tab: \(error.localizedDescription)")
        }
    }

    func bulkUpdateTasks(_ tasks: [Task]) async throws {
        do {
            for task in tasks {
                task.updateModifiedDate()
            }
            try modelContext.save()
        } catch {
            throw AppError.dataSavingFailed("Failed to bulk update tasks: \(error.localizedDescription)")
        }
    }

    // MARK: - Business Logic Helpers

    func rescheduleTask(_ task: Task, to newDate: Date) async throws {
        task.dueDate = newDate
        try await updateTask(task)
    }

    func changeTaskPriority(_ task: Task, to priority: Priority) async throws {
        task.priority = priority
        try await updateTask(task)
    }

    func assignTaskToCategory(_ task: Task, category: Category?) async throws {
        task.category = category
        try await updateTask(task)
    }


    func markTaskComplete(_ task: Task) async throws {
        task.markCompleted()
        try await updateTask(task)
    }

    func markTaskIncomplete(_ task: Task) async throws {
        task.markIncomplete()
        try await updateTask(task)
    }

    // MARK: - Subtask Management

    func addSubtask(_ subtask: Subtask, to task: Task) async throws {
        if task.subtasks == nil {
            task.subtasks = []
        }
        task.subtasks?.append(subtask)
        subtask.parentTask = task
        task.updateModifiedDate()
        try await updateTask(task)
    }

    func toggleSubtaskCompletion(_ subtask: Subtask) async throws {
        subtask.isComplete.toggle()
        subtask.updateModifiedDate()
        if let parentTask = subtask.parentTask {
            try await updateTask(parentTask)
        }
    }

    func updateSubtask(_ subtask: Subtask, title: String) async throws {
        subtask.title = title
        subtask.updateModifiedDate()
        if let parentTask = subtask.parentTask {
            try await updateTask(parentTask)
        }
    }

    func deleteSubtask(_ subtask: Subtask) async throws {
        guard let parentTask = subtask.parentTask else { return }
        parentTask.removeSubtask(subtask)
        try await updateTask(parentTask)
    }

    func reorderSubtasks(_ subtasks: [Subtask], from source: IndexSet, to destination: Int) async throws {
        var reorderedSubtasks = subtasks
        reorderedSubtasks.move(fromOffsets: source, toOffset: destination)

        // Update order values
        for (index, subtask) in reorderedSubtasks.enumerated() {
            subtask.order = index + 1
            subtask.updateModifiedDate()
        }

        if let parentTask = subtasks.first?.parentTask {
            try await updateTask(parentTask)
        }
    }

    // MARK: - Habit Management

    func removeHabitForTask(_ task: Task) async throws {
        // Find and remove the habit associated with this task
        let taskId = task.id
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.baseTask?.id == taskId
            }
        )

        do {
            let habits = try modelContext.fetch(habitDescriptor)
            for habit in habits {
                modelContext.delete(habit)
            }
            try modelContext.save()

            // Update app state if needed
            try await refreshTasks()
        } catch {
            throw AppError.dataSavingFailed("Failed to remove habit for task: \(error.localizedDescription)")
        }
    }

    // MARK: - Recurring Task Support

    func generateRecurringTaskInstance(_ baseTask: Task, for date: Date) async throws -> Task? {
        guard baseTask.taskType == .recurring,
              let recurrenceRule = baseTask.recurrenceRule,
              recurrenceRule.isValidOccurrence(date: date) else {
            return nil
        }

        // Check if instance already exists for this date
        let existingTasks = try await getTasksForDate(date)
        if existingTasks.contains(where: { $0.title == baseTask.title && $0.taskType == .recurring }) {
            return nil
        }

        // Create new instance
        let instanceTask = Task(
            title: baseTask.title,
            description: baseTask.taskDescription,
            dueDate: date,
            priority: baseTask.priority,
            status: .notStarted
        )

        instanceTask.taskType = .recurring
        instanceTask.category = baseTask.category

        try await createTask(instanceTask)
        return instanceTask
    }

    // MARK: - Statistics

    func getTaskStatistics() async throws -> TaskStatistics {
        do {
            let allTasks = try modelContext.fetch(FetchDescriptor<Task>())

            let totalTasks = allTasks.count
            let completedTasks = allTasks.filter { $0.isCompleted }.count
            let overdueTasks = allTasks.filter { $0.isOverdue }.count
            let todayTasks = allTasks.filter { $0.isDueToday }.count

            let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0

            return TaskStatistics(
                totalTasks: totalTasks,
                completedTasks: completedTasks,
                overdueTasks: overdueTasks,
                todayTasks: todayTasks,
                completionRate: completionRate
            )
        } catch {
            throw AppError.dataLoadingFailed("Failed to get task statistics: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helper Methods

    private func scheduleNotificationIfNeeded(for task: Task) async {
        // TODO: Implement notification scheduling
        // This would integrate with a NotificationService
    }

    private func updateNotificationIfNeeded(for task: Task) async {
        // TODO: Implement notification updating
        // This would integrate with a NotificationService
    }

    private func cancelNotificationIfNeeded(for task: Task) async {
        // TODO: Implement notification cancellation
        // This would integrate with a NotificationService
    }

    // MARK: - Offline Change Tracking

    private func trackOfflineChange() {
        diContainer?.trackOfflineChange()
    }
}

// MARK: - Supporting Types

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let todayTasks: Int
    let completionRate: Double
}
