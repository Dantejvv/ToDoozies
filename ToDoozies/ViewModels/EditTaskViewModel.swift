//
//  EditTaskViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import Foundation
import Observation

@Observable
final class EditTaskViewModel {

    // MARK: - Original Task
    let originalTask: Task

    // MARK: - Form Fields
    var title: String
    var taskDescription: String
    var dueDateText: String
    var parsedDueDate: Date?
    var priority: Priority
    var selectedCategory: Category?
    var taskType: TaskType
    var recurrenceRule: RecurrenceRule?

    // MARK: - Validation State
    var validationErrors: [ValidationError] = []
    var isFormValid: Bool {
        validationErrors.isEmpty && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - UI State
    var isLoading: Bool = false
    var showingRecurrenceSheet: Bool = false
    var showingAttachmentPicker: Bool = false
    var showingCategoryPicker: Bool = false
    var showingDiscardAlert: Bool = false
    var errorMessage: String?
    var dismissAction: (() -> Void)?

    // MARK: - Services
    private let appState: AppState
    private let taskService: TaskServiceProtocol
    private let categoryService: CategoryServiceProtocol

    // MARK: - Computed Properties

    var hasUnsavedChanges: Bool {
        title != originalTask.title ||
        taskDescription != (originalTask.taskDescription ?? "") ||
        priority != originalTask.priority ||
        selectedCategory?.id != originalTask.category?.id ||
        taskType != originalTask.taskType ||
        parsedDueDate != originalTask.dueDate ||
        recurrenceRule?.id != originalTask.recurrenceRule?.id
    }

    var canConvertToRecurring: Bool {
        originalTask.taskType == .oneTime && (taskType == .recurring || taskType == .habit)
    }

    var canConvertToRegular: Bool {
        (originalTask.taskType == .recurring || originalTask.taskType == .habit) && taskType == .oneTime
    }

    var isTypeChanging: Bool {
        originalTask.taskType != taskType
    }

    // MARK: - Initialization

    init(
        task: Task,
        appState: AppState,
        taskService: TaskServiceProtocol,
        categoryService: CategoryServiceProtocol
    ) {
        self.originalTask = task
        self.appState = appState
        self.taskService = taskService
        self.categoryService = categoryService

        // Initialize form fields with current task values
        self.title = task.title
        self.taskDescription = task.taskDescription ?? ""
        self.priority = task.priority
        self.selectedCategory = task.category
        self.taskType = task.taskType
        self.recurrenceRule = task.recurrenceRule
        self.parsedDueDate = task.dueDate

        // Initialize date text from current due date
        if let dueDate = task.dueDate {
            self.dueDateText = Self.formatDateForEditing(dueDate)
        } else {
            self.dueDateText = ""
        }

        // Start validation
        validateForm()
    }

    // MARK: - Form Actions

    func saveTask() async {
        guard isFormValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Update task properties
            originalTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            originalTask.taskDescription = taskDescription.isEmpty ? nil : taskDescription
            originalTask.priority = priority
            originalTask.category = selectedCategory
            originalTask.dueDate = parsedDueDate

            // Handle type changes
            if isTypeChanging {
                if canConvertToRecurring && recurrenceRule != nil {
                    // Convert to recurring task or habit
                    originalTask.taskType = taskType
                    originalTask.recurrenceRule = recurrenceRule

                    // Create habit if converting to habit type
                    if taskType == .habit {
                        try await createHabitFromTask(originalTask)
                    }

                } else if canConvertToRegular {
                    // Convert to one-time task
                    originalTask.taskType = .oneTime
                    originalTask.recurrenceRule = nil

                    // Remove associated habit if it exists
                    try await removeHabitFromTask(originalTask)
                }
            } else if taskType.requiresRecurrence {
                // Update recurrence rule for existing recurring task or habit
                originalTask.recurrenceRule = recurrenceRule
            }

            // Save the updated task
            try await taskService.updateTask(originalTask)

            // Navigate back
            dismissAction?()

        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }

    func cancel() {
        if hasUnsavedChanges {
            showingDiscardAlert = true
        } else {
            dismissAction?()
        }
    }

    func discardChanges() {
        dismissAction?()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Validation

    func validateForm() {
        validationErrors.removeAll()

        // Title validation
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            validationErrors.append(.titleRequired)
        } else if trimmedTitle.count > 200 {
            validationErrors.append(.titleTooLong(maxLength: 200))
        }

        // Date validation (if provided)
        if !dueDateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedDueDate == nil {
            validationErrors.append(.invalidDateFormat(input: dueDateText))
        }

        // For one-time tasks, don't allow past dates (unless already completed)
        if let date = parsedDueDate, taskType == .oneTime && !originalTask.isCompleted && date < Date() {
            validationErrors.append(.pastDateNotAllowed)
        }

        // Recurrence validation
        if taskType.requiresRecurrence && recurrenceRule == nil {
            validationErrors.append(.recurrenceRuleRequired)
        }

        // Type change validation
        if isTypeChanging {
            if canConvertToRecurring && recurrenceRule == nil {
                validationErrors.append(.recurrenceRequiredForConversion)
            }
        }
    }

    // MARK: - Date Parsing

    func parseDateFromText() {
        let parser = NaturalLanguageDateParser()
        let result = parser.parseDate(from: dueDateText)

        switch result {
        case .success(let date, _):
            parsedDueDate = date
        case .ambiguous(let dates, _):
            // Use first option for now, could show picker later
            parsedDueDate = dates.first
        case .failed:
            parsedDueDate = nil
        }

        validateForm()
    }

    private static func formatDateForEditing(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(date, inSameDayAs: now) {
            return "today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "tomorrow"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    // MARK: - Private Helpers

    private func createHabitFromTask(_ task: Task) async throws {
        let habit = Habit(baseTask: task, targetCompletionsPerPeriod: 30) // Default to 30 days
        try await taskService.createHabit(habit)
    }

    private func removeHabitFromTask(_ task: Task) async throws {
        // Find and remove associated habit
        // This would need to be implemented in the task service
        try await taskService.removeHabitForTask(task)
    }
}

// MARK: - Extended Validation Errors

extension ValidationError {
    static let recurrenceRequired = ValidationError.custom("Recurring tasks need a recurrence pattern")
    static let recurrenceRequiredForConversion = ValidationError.custom("Please set a recurrence pattern to convert to recurring task")
}

