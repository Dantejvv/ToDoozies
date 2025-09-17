//
//  AddTaskView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import SwiftUI
import SwiftData
import Foundation

struct AddTaskView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: AddTaskViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                AddTaskFormView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil, let container = diContainer {
                viewModel = container.makeAddTaskViewModel()
            }
        }
    }
}

struct AddTaskFormView: View {
    @Bindable var viewModel: AddTaskViewModel

    var body: some View {
        NavigationStack {
            Form {
                taskTypeSection
                basicInfoSection
                scheduleSection

                if viewModel.isRecurring {
                    recurrenceSection
                }

                attachmentsSection
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
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
            .sheet(isPresented: $viewModel.showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
            .sheet(isPresented: $viewModel.showingRecurrenceSheet) {
                RecurrencePickerView(recurrenceRule: $viewModel.recurrenceRule)
            }
        }
    }

    // MARK: - Form Sections

    private var taskTypeSection: some View {
        Section("Task Type") {
            Picker("Type", selection: $viewModel.isRecurring) {
                Label("Regular Task", systemImage: "checkmark.circle")
                    .tag(false)
                Label("Recurring Habit", systemImage: "repeat.circle")
                    .tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

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

            if viewModel.isRecurring && viewModel.recurrenceRule == nil {
                Label("Recurring tasks need a recurrence pattern", systemImage: "info.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    private var attachmentsSection: some View {
        Section("Attachments") {
            // Add attachment button
            Button(action: { viewModel.showingAttachmentPicker = true }) {
                Label("Add Files", systemImage: "paperclip")
            }

            // Show selected attachments
            if !viewModel.selectedAttachments.isEmpty {
                ForEach(viewModel.selectedAttachments, id: \.id) { attachment in
                    AttachmentRowView(
                        attachment: attachment,
                        onDelete: { viewModel.removeAttachment(attachment) },
                        onTap: { /* Preview not needed in add view */ }
                    )
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingAttachmentPicker,
            allowedContentTypes: viewModel.supportedContentTypes,
            allowsMultipleSelection: true
        ) { result in
            viewModel.handleFilePickerResult(result)
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

// MARK: - Smart Date Field

struct SmartDateField: View {
    @Binding var text: String
    @Binding var parsedDate: Date?
    let onTextChange: (String) -> Void

    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Due date (e.g., 'tomorrow', 'next Friday')", text: $text)
                .focused($isEditing)
                .onChange(of: text) { _, newValue in
                    onTextChange(newValue)
                }
                .onSubmit {
                    // Handle submission if needed
                }

            // Date parsing feedback
            if !text.isEmpty {
                if let parsedDate = parsedDate {
                    Label(
                        parsedDate.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                    .font(.caption)
                } else if !isEditing {
                    Label(
                        "Could not understand date format",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - Placeholder Views Removed
// CategoryPickerView and RecurrencePickerView are now implemented as separate components

// MARK: - Preview

#Preview {
    AddTaskView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}
