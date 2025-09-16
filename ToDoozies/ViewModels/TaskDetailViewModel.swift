//
//  TaskDetailViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class TaskDetailViewModel {

    // MARK: - Core Properties
    let task: Task

    // MARK: - UI State
    var isLoading: Bool = false
    var showingEditSheet: Bool = false
    var showingDeleteAlert: Bool = false
    var showingAddSubtaskSheet: Bool = false
    var showingAttachmentPicker: Bool = false
    var errorMessage: String?

    // MARK: - Subtask Management
    var newSubtaskTitle: String = ""
    var editingSubtask: Subtask?
    var editingSubtaskTitle: String = ""

    // MARK: - Services
    private let appState: AppState
    private let taskService: TaskServiceProtocol
    private let navigationCoordinator: NavigationCoordinator

    // MARK: - Computed Properties

    var completedSubtasks: [Subtask] {
        task.subtasks?.filter { $0.isComplete } ?? []
    }

    var incompleteSubtasks: [Subtask] {
        task.subtasks?.filter { !$0.isComplete } ?? []
    }

    var subtaskProgress: Double {
        guard let subtasks = task.subtasks, !subtasks.isEmpty else { return 0.0 }
        let completed = subtasks.filter { $0.isComplete }.count
        return Double(completed) / Double(subtasks.count)
    }

    var formattedProgress: String {
        guard let subtasks = task.subtasks, !subtasks.isEmpty else { return "No subtasks" }
        let completed = subtasks.filter { $0.isComplete }.count
        return "\(completed) of \(subtasks.count) completed"
    }

    var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date() && !task.isCompleted
    }

    var isDueToday: Bool {
        guard let dueDate = task.dueDate else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: Date())
    }

    var isDueSoon: Bool {
        guard let dueDate = task.dueDate else { return false }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return dueDate <= tomorrow && !task.isCompleted
    }

    var canMarkComplete: Bool {
        !task.isCompleted
    }

    var canMarkIncomplete: Bool {
        task.isCompleted
    }

    var formattedDueDate: String? {
        guard let dueDate = task.dueDate else { return nil }

        if isDueToday {
            return "Today at \(dueDate.formatted(date: .omitted, time: .shortened))"
        } else if isOverdue {
            return "Overdue - \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            return dueDate.formatted(date: .abbreviated, time: .omitted)
        }
    }

    // MARK: - Initialization

    init(
        task: Task,
        appState: AppState,
        taskService: TaskServiceProtocol,
        navigationCoordinator: NavigationCoordinator
    ) {
        self.task = task
        self.appState = appState
        self.taskService = taskService
        self.navigationCoordinator = navigationCoordinator
    }

    // MARK: - Task Actions

    func toggleTaskCompletion() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if task.isCompleted {
                try await taskService.markTaskIncomplete(task)
            } else {
                try await taskService.markTaskComplete(task)
            }
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }

    func editTask() {
        navigationCoordinator.showEditTask(task)
    }


    func deleteTask() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await taskService.deleteTask(task)
            navigationCoordinator.goBack()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    func refreshTask() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await taskService.refreshTasks()
        } catch {
            errorMessage = "Failed to refresh task: \(error.localizedDescription)"
        }
    }

    // MARK: - Subtask Management

    func addSubtask() async {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isLoading = true
        defer {
            isLoading = false
            newSubtaskTitle = ""
            showingAddSubtaskSheet = false
        }

        do {
            let order = (task.subtasks?.count ?? 0) + 1
            let subtask = Subtask(
                title: trimmedTitle,
                order: order,
                parentTask: task
            )

            try await taskService.addSubtask(subtask, to: task)
        } catch {
            errorMessage = "Failed to add subtask: \(error.localizedDescription)"
        }
    }

    func toggleSubtaskCompletion(_ subtask: Subtask) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await taskService.toggleSubtaskCompletion(subtask)
        } catch {
            errorMessage = "Failed to update subtask: \(error.localizedDescription)"
        }
    }

    func startEditingSubtask(_ subtask: Subtask) {
        editingSubtask = subtask
        editingSubtaskTitle = subtask.title
    }

    func saveSubtaskEdit() async {
        guard let subtask = editingSubtask else { return }

        let trimmedTitle = editingSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isLoading = true
        defer {
            isLoading = false
            editingSubtask = nil
            editingSubtaskTitle = ""
        }

        do {
            try await taskService.updateSubtask(subtask, title: trimmedTitle)
        } catch {
            errorMessage = "Failed to update subtask: \(error.localizedDescription)"
        }
    }

    func cancelSubtaskEdit() {
        editingSubtask = nil
        editingSubtaskTitle = ""
    }

    func deleteSubtask(_ subtask: Subtask) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await taskService.deleteSubtask(subtask)
        } catch {
            errorMessage = "Failed to delete subtask: \(error.localizedDescription)"
        }
    }

    func moveSubtask(from source: IndexSet, to destination: Int) async {
        guard let subtasks = task.subtasks else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await taskService.reorderSubtasks(Array(subtasks), from: source, to: destination)
        } catch {
            errorMessage = "Failed to reorder subtasks: \(error.localizedDescription)"
        }
    }

    // MARK: - Validation

    var canAddSubtask: Bool {
        !newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSaveSubtaskEdit: Bool {
        !editingSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }

    // MARK: - UI Actions

    func showDeleteAlert() {
        showingDeleteAlert = true
    }

    func showAddSubtaskSheet() {
        showingAddSubtaskSheet = true
    }

    func showAttachmentPicker() {
        showingAttachmentPicker = true
    }
}

