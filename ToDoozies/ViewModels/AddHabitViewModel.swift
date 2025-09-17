//
//  AddHabitViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/16/25.
//

import Foundation
import Observation

@Observable
final class AddHabitViewModel {

    // MARK: - Form Fields
    var title: String = ""
    var habitDescription: String = ""
    var selectedCategory: Category?
    var targetCompletionsPerPeriod: Int = 1

    // MARK: - Validation State
    var validationErrors: [ValidationError] = []
    var isFormValid: Bool {
        validationErrors.isEmpty && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - UI State
    var isLoading: Bool = false
    var showingCategoryPicker: Bool = false
    var errorMessage: String?

    // MARK: - Services
    private let appState: AppState
    private let habitService: HabitServiceProtocol
    private let taskService: TaskServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let navigationCoordinator: NavigationCoordinator

    // MARK: - Computed Properties

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDescription: String {
        habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty && !isLoading
    }

    var availableCategories: [Category] {
        appState.categories
    }

    // MARK: - Initialization

    init(
        appState: AppState,
        habitService: HabitServiceProtocol,
        taskService: TaskServiceProtocol,
        categoryService: CategoryServiceProtocol,
        navigationCoordinator: NavigationCoordinator
    ) {
        self.appState = appState
        self.habitService = habitService
        self.taskService = taskService
        self.categoryService = categoryService
        self.navigationCoordinator = navigationCoordinator
    }

    // MARK: - Validation

    func validateForm() {
        validationErrors.removeAll()

        if trimmedTitle.isEmpty {
            validationErrors.append(.emptyTitle)
        }

        if trimmedTitle.count > 100 {
            validationErrors.append(.titleTooLong(maxLength: 100))
        }

        if trimmedDescription.count > 500 {
            validationErrors.append(.descriptionTooLong)
        }

        if targetCompletionsPerPeriod < 1 {
            validationErrors.append(.invalidTargetCompletions)
        }
    }

    // MARK: - Actions

    func save() async {
        validateForm()
        guard isFormValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Create the base task first
            let task = Task(
                title: trimmedTitle,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                priority: .medium, // Habits default to medium priority
                status: .notStarted
            )

            // Set category if selected
            if let category = selectedCategory {
                task.category = category
            }

            // Create the task
            try await taskService.createTask(task)

            // Create the habit
            let habit = Habit(
                baseTask: task,
                targetCompletionsPerPeriod: targetCompletionsPerPeriod > 1 ? targetCompletionsPerPeriod : nil
            )

            try await habitService.createHabit(habit)

            // Navigate back
            navigationCoordinator.dismiss()

        } catch {
            errorMessage = "Failed to create habit: \(error.localizedDescription)"
        }
    }

    func cancel() {
        navigationCoordinator.dismiss()
    }

    // MARK: - Category Selection

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        showingCategoryPicker = false
    }

    func showCategoryPicker() {
        showingCategoryPicker = true
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Field Validation

    func validateTitle() {
        // Remove title-related errors and re-validate
        validationErrors.removeAll { error in
            switch error {
            case .emptyTitle, .titleTooLong: return true
            default: return false
            }
        }

        if trimmedTitle.isEmpty {
            validationErrors.append(.emptyTitle)
        } else if trimmedTitle.count > 100 {
            validationErrors.append(.titleTooLong(maxLength: 100))
        }
    }

    func validateDescription() {
        // Remove description-related errors and re-validate
        validationErrors.removeAll { error in
            switch error {
            case .descriptionTooLong: return true
            default: return false
            }
        }

        if trimmedDescription.count > 500 {
            validationErrors.append(.descriptionTooLong)
        }
    }

    func validateTargetCompletions() {
        // Remove target completions-related errors and re-validate
        validationErrors.removeAll { error in
            switch error {
            case .invalidTargetCompletions: return true
            default: return false
            }
        }

        if targetCompletionsPerPeriod < 1 {
            validationErrors.append(.invalidTargetCompletions)
        }
    }
}

