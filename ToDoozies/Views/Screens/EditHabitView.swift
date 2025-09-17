//
//  EditHabitView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/16/25.
//

import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: EditHabitViewModel?

    let habit: Habit

    var body: some View {
        Group {
            if let viewModel = viewModel {
                EditHabitFormView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil, let container = diContainer {
                viewModel = EditHabitViewModel(
                    habit: habit,
                    appState: container.appState,
                    habitService: container.habitService,
                    taskService: container.taskService,
                    categoryService: container.categoryService,
                    navigationCoordinator: container.navigationCoordinator
                )
            }
        }
    }
}

struct EditHabitFormView: View {
    @Bindable var viewModel: EditHabitViewModel

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                categorySection
                targetSection

                if !viewModel.validationErrors.isEmpty {
                    validationErrorsSection
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") {
                        _Concurrency.Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
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
            .sheet(isPresented: $viewModel.showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
        }
    }

    // MARK: - Form Sections

    private var basicInfoSection: some View {
        Section("Habit Details") {
            TextField("Habit name", text: $viewModel.title)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.title) { _, _ in
                    viewModel.validateTitle()
                }
                .accessibilityLabel("Habit name")

            TextField("Description (optional)", text: $viewModel.habitDescription, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .onChange(of: viewModel.habitDescription) { _, _ in
                    viewModel.validateDescription()
                }
                .accessibilityLabel("Habit description")
        }
    }

    private var categorySection: some View {
        Section("Organization") {
            Button(action: {
                viewModel.showCategoryPicker()
            }) {
                HStack {
                    Text("Category")
                        .foregroundColor(.primary)

                    Spacer()

                    if let category = viewModel.selectedCategory {
                        CategoryBadge(category: category, size: .small)
                    } else {
                        Text("None")
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Category")
            .accessibilityValue(viewModel.selectedCategory?.name ?? "None selected")
            .accessibilityHint("Double tap to select a category")
        }
    }

    private var targetSection: some View {
        Section("Goal") {
            HStack {
                Text("Target completions per period")
                    .foregroundColor(.primary)

                Spacer()

                Stepper(
                    value: $viewModel.targetCompletionsPerPeriod,
                    in: 1...7
                ) {
                    Text("\(viewModel.targetCompletionsPerPeriod)")
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
                .onChange(of: viewModel.targetCompletionsPerPeriod) { _, _ in
                    viewModel.validateTargetCompletions()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Target completions per period")
            .accessibilityValue("\(viewModel.targetCompletionsPerPeriod)")

            Text("This helps track your habit completion goals. Most daily habits should be set to 1.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var validationErrorsSection: some View {
        Section {
            ForEach(viewModel.validationErrors, id: \.localizedDescription) { error in
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        } header: {
            Text("Please fix the following issues:")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Edit Habit ViewModel

@Observable
final class EditHabitViewModel {
    // MARK: - Core Properties
    let habit: Habit

    // MARK: - Form Fields
    var title: String
    var habitDescription: String
    var selectedCategory: Category?
    var targetCompletionsPerPeriod: Int

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
        !trimmedTitle.isEmpty && !isLoading && hasChanges
    }

    var hasChanges: Bool {
        let originalTitle = habit.baseTask?.title ?? ""
        let originalDescription = habit.baseTask?.taskDescription ?? ""
        let originalCategoryId = habit.baseTask?.category?.id
        let originalTarget = habit.targetCompletionsPerPeriod ?? 1

        return trimmedTitle != originalTitle ||
               trimmedDescription != originalDescription ||
               selectedCategory?.id != originalCategoryId ||
               targetCompletionsPerPeriod != originalTarget
    }

    var availableCategories: [Category] {
        appState.categories
    }

    // MARK: - Initialization

    init(
        habit: Habit,
        appState: AppState,
        habitService: HabitServiceProtocol,
        taskService: TaskServiceProtocol,
        categoryService: CategoryServiceProtocol,
        navigationCoordinator: NavigationCoordinator
    ) {
        self.habit = habit
        self.appState = appState
        self.habitService = habitService
        self.taskService = taskService
        self.categoryService = categoryService
        self.navigationCoordinator = navigationCoordinator

        // Initialize form fields with current values
        self.title = habit.baseTask?.title ?? ""
        self.habitDescription = habit.baseTask?.taskDescription ?? ""
        self.selectedCategory = habit.baseTask?.category
        self.targetCompletionsPerPeriod = habit.targetCompletionsPerPeriod ?? 1
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
        guard isFormValid && hasChanges else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Update the base task
            if let baseTask = habit.baseTask {
                baseTask.title = trimmedTitle
                baseTask.taskDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
                baseTask.category = selectedCategory

                try await taskService.updateTask(baseTask)
            }

            // Update the habit
            habit.targetCompletionsPerPeriod = targetCompletionsPerPeriod > 1 ? targetCompletionsPerPeriod : nil
            try await habitService.updateHabit(habit)

            // Navigate back
            navigationCoordinator.dismiss()

        } catch {
            errorMessage = "Failed to update habit: \(error.localizedDescription)"
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

// MARK: - Preview

#Preview {
    EditHabitView(habit: Habit.preview)
        .inject(DIContainer(modelContext: ModelContext.preview))
}
