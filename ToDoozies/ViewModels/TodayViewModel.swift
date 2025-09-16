//
//  TodayViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class TodayViewModel {
    let appState: AppState
    private let taskService: TaskServiceProtocol
    private let habitService: HabitServiceProtocol

    // MARK: - View State
    var isRefreshing: Bool = false
    var showingAddTask: Bool = false

    init(
        appState: AppState,
        taskService: TaskServiceProtocol,
        habitService: HabitServiceProtocol
    ) {
        self.appState = appState
        self.taskService = taskService
        self.habitService = habitService
    }

    // MARK: - Computed Properties

    /// Tasks scheduled for today
    var todayTasks: [Task] {
        appState.todayTasks.sorted { task1, task2 in
            // Sort by priority first, then by due time
            if task1.priority.sortOrder != task2.priority.sortOrder {
                return task1.priority.sortOrder > task2.priority.sortOrder
            }

            // If both have due times, sort by time
            switch (task1.dueDate, task2.dueDate) {
            case let (date1?, date2?):
                return date1 < date2
            case (nil, _?):
                return false // Tasks without time go after
            case (_?, nil):
                return true // Tasks with time go first
            case (nil, nil):
                return task1.title < task2.title // Alphabetical for tasks without time
            }
        }
    }

    /// Overdue tasks that need attention
    var overdueTasks: [Task] {
        appState.overdueTasks.sorted { $0.dueDate ?? Date.distantPast < $1.dueDate ?? Date.distantPast }
    }

    /// Preview of tomorrow's tasks (limited to 3)
    var tomorrowTasksPreview: [Task] {
        Array(appState.tomorrowTasks.prefix(3))
    }

    /// Today's recurring tasks (habits)
    var recurringTasks: [Task] {
        appState.todayRecurringTasks.sorted { task1, task2 in
            // Sort completed tasks to the bottom
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            return task1.title < task2.title
        }
    }

    /// Daily progress for recurring tasks
    var dailyProgress: Double {
        appState.dailyRecurringProgress
    }

    /// Progress text for display
    var progressText: String {
        let completed = recurringTasks.filter { $0.isCompleted }.count
        let total = recurringTasks.count
        return "\(completed)/\(total) completed"
    }

    /// Greeting text based on time of day
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    /// Daily summary text
    var dailySummaryText: String {
        let totalTasks = todayTasks.count + recurringTasks.count
        let completedTasks = todayTasks.filter { $0.isCompleted }.count +
                           recurringTasks.filter { $0.isCompleted }.count

        if totalTasks == 0 {
            return "No tasks for today"
        } else if completedTasks == totalTasks {
            return "All tasks completed! 🎉"
        } else {
            return "\(completedTasks) of \(totalTasks) tasks completed"
        }
    }

    /// Whether all tasks are completed
    var isAllCompleted: Bool {
        let allTasks = todayTasks + recurringTasks
        return !allTasks.isEmpty && allTasks.allSatisfy { $0.isCompleted }
    }

    // MARK: - Actions

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await taskService.refreshTasks()
            try await habitService.refreshHabits()
        } catch {
            appState.setError(.dataLoadingFailed(error.localizedDescription))
        }
    }

    func completeTask(_ task: Task) {
        task.markCompleted()

        // If this is a recurring task, also mark the habit as completed
        if task.isRecurring {
            if let habit = appState.habits.first(where: { $0.baseTask?.id == task.id }) {
                habit.markCompleted()
            }
        }

        _Concurrency.Task {
            do {
                try await taskService.updateTask(task)
            } catch {
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func uncompleteTask(_ task: Task) {
        task.markIncomplete()

        // If this is a recurring task, also mark the habit as incomplete
        if task.isRecurring {
            if let habit = appState.habits.first(where: { $0.baseTask?.id == task.id }) {
                habit.markIncomplete()
            }
        }

        _Concurrency.Task {
            do {
                try await taskService.updateTask(task)
            } catch {
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func rescheduleOverdueTask(_ task: Task, to newDate: Date) {
        task.dueDate = newDate
        task.updateModifiedDate()

        _Concurrency.Task {
            do {
                try await taskService.updateTask(task)
            } catch {
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func addQuickTask(title: String) {
        let newTask = Task(
            title: title,
            dueDate: Date(),
            priority: .medium
        )

        appState.addTask(newTask)

        _Concurrency.Task {
            do {
                try await taskService.createTask(newTask)
            } catch {
                appState.removeTask(newTask) // Rollback on error
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func deleteTask(_ task: Task) {
        appState.removeTask(task)

        _Concurrency.Task {
            do {
                try await taskService.deleteTask(task)
            } catch {
                appState.addTask(task) // Rollback on error
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Helper Methods

    func hasTasksDue() -> Bool {
        return !todayTasks.isEmpty || !overdueTasks.isEmpty
    }

    func hasRecurringTasks() -> Bool {
        return !recurringTasks.isEmpty
    }

    func shouldShowProgressSection() -> Bool {
        return hasRecurringTasks()
    }

    func shouldShowOverdueSection() -> Bool {
        return !overdueTasks.isEmpty
    }

    func shouldShowTomorrowPreview() -> Bool {
        return !tomorrowTasksPreview.isEmpty
    }
}