//
//  EditTaskView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import SwiftUI
import SwiftData
import Foundation

struct EditTaskView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: EditTaskViewModel?

    let task: Task

    var body: some View {
        Group {
            if let viewModel = viewModel {
                EditTaskFormView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil, let container = diContainer {
                viewModel = container.makeEditTaskViewModel(task: task)
            }
        }
    }
}

struct EditTaskFormView: View {
    @Bindable var viewModel: EditTaskViewModel

    var body: some View {
        NavigationStack {
            Form {
                // Type change warning section
                if viewModel.isTypeChanging {
                    typeChangeWarningSection
                }

                // Task type section
                taskTypeSection

                // Basic info section
                basicInfoSection

                // Schedule section
                scheduleSection

                // Recurrence section (if recurring)
                if viewModel.isRecurring {
                    recurrenceSection
                }

                // Attachments section (placeholder)
                attachmentsSection
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _Concurrency.Task { @MainActor in
                            await viewModel.saveTask()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            })
            .disabled(viewModel.isLoading)
            .alert("Discard Changes?", isPresented: $viewModel.showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.discardChanges()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .sheet(isPresented: $viewModel.showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
            .sheet(isPresented: $viewModel.showingRecurrenceSheet) {
                RecurrencePickerView(recurrenceRule: $viewModel.recurrenceRule)
            }
        }
    }

    // MARK: - Type Change Warning Section

    private var typeChangeWarningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Task Type Change", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)

                if viewModel.canConvertToRecurring {
                    Text("Converting this task to a recurring habit will create a new habit entry and enable streak tracking.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if viewModel.canConvertToRegular {
                    Text("Converting this recurring task to a regular task will remove habit tracking and streak data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Task Type Section

    private var taskTypeSection: some View {
        Section("Task Type") {
            Picker("Type", selection: $viewModel.isRecurring) {
                Label("Regular Task", systemImage: "checkmark.circle")
                    .tag(false)
                Label("Recurring Habit", systemImage: "repeat.circle")
                    .tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.isRecurring) { _, _ in
                viewModel.validateForm()
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section("Details") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Task Title", text: $viewModel.title)
                    .submitLabel(.next)
                    .onChange(of: viewModel.title) { _, _ in
                        viewModel.validateForm()
                    }

                // Show title validation error
                if let titleError = viewModel.validationErrors.first(where: { error in
                    if case .titleRequired = error { return true }
                    if case .titleTooLong = error { return true }
                    return false
                }) {
                    Label(titleError.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            TextField("Description (Optional)", text: $viewModel.taskDescription, axis: .vertical)
                .lineLimit(1...3)
                .submitLabel(.done)
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        Section("Schedule") {
            // Smart Date Input
            SmartDateField(
                text: $viewModel.dueDateText,
                parsedDate: $viewModel.parsedDueDate,
                onTextChange: { _ in
                    viewModel.parseDateFromText()
                }
            )

            // Priority Selection
            Picker("Priority", selection: $viewModel.priority) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    HStack {
                        Circle()
                            .fill(priorityColor(for: priority))
                            .frame(width: 12, height: 12)
                        Text(priority.displayName)
                    }
                    .tag(priority)
                }
            }

            // Category Selection
            HStack {
                Text("Category")
                Spacer()
                Button(action: { viewModel.showingCategoryPicker = true }) {
                    HStack {
                        if let category = viewModel.selectedCategory {
                            Circle()
                                .fill(Color(hex: category.color) ?? .blue)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Select Category")
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Recurrence Section

    private var recurrenceSection: some View {
        Section("Recurrence") {
            HStack {
                Text("Pattern")
                Spacer()
                Button(action: { viewModel.showingRecurrenceSheet = true }) {
                    HStack {
                        if let rule = viewModel.recurrenceRule {
                            Text(rule.frequency.displayName)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Set Pattern")
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
            }

            // Show recurrence validation errors
            if let recurrenceError = viewModel.validationErrors.first(where: { error in
                if case .custom(let message) = error,
                   message.contains("recurrence") || message.contains("Recurring") {
                    return true
                }
                return false
            }) {
                Label(recurrenceError.localizedDescription, systemImage: "info.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    // MARK: - Attachments Section

    private var attachmentsSection: some View {
        Section("Attachments") {
            Button(action: { viewModel.showingAttachmentPicker = true }) {
                Label("Add Attachment", systemImage: "paperclip")
            }
            .disabled(true) // Placeholder for now
        }
    }

    // MARK: - Helper Methods

    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}


// MARK: - Preview

#Preview {
    EditTaskView(task: Task.preview)
        .inject(DIContainer(modelContext: ModelContext.preview))
}