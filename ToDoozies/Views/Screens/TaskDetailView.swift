//
//  TaskDetailView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: TaskDetailViewModel?

    let task: Task

    var body: some View {
        Group {
            if let viewModel = viewModel {
                TaskDetailContentView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil, let container = diContainer {
                viewModel = container.makeTaskDetailViewModel(task: task)
            }
        }
    }
}

struct TaskDetailContentView: View {
    @Bindable var viewModel: TaskDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                taskHeaderSection

                // Status Section
                taskStatusSection

                // Description Section
                if let description = viewModel.task.taskDescription, !description.isEmpty {
                    descriptionSection(description)
                }

                // Due Date and Priority Section
                metadataSection

                // Category Section
                if let category = viewModel.task.category {
                    categorySection(category)
                }

                // Subtasks Section
                subtasksSection

                // Attachments Section (Placeholder)
                attachmentsSection

                // Actions Section
                actionsSection

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(viewModel.task.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(content: {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit") {
                    viewModel.editTask()
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
            await viewModel.refreshTask()
        }
        .alert("Delete Task", isPresented: $viewModel.showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                _Concurrency.Task { await viewModel.deleteTask() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(viewModel.task.title)'? This action cannot be undone.")
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
        .sheet(isPresented: $viewModel.showingAddSubtaskSheet) {
            AddSubtaskSheet(viewModel: viewModel)
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

    private var taskHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    _Concurrency.Task { await viewModel.toggleTaskCompletion() }
                }) {
                    Image(systemName: viewModel.task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(viewModel.task.isCompleted ? .green : .gray)
                }
                .disabled(viewModel.isLoading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .strikethrough(viewModel.task.isCompleted)
                        .foregroundColor(viewModel.task.isCompleted ? .secondary : .primary)

                    if viewModel.task.isRecurring {
                        Label("Recurring Task", systemImage: "repeat.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Status Section

    private var taskStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
                .fontWeight(.medium)

            HStack {
                statusBadge
                Spacer()
                priorityBadge
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Text(viewModel.task.priority.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.2))
        .foregroundColor(priorityColor)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        if viewModel.task.isCompleted {
            return .green
        } else if viewModel.isOverdue {
            return .red
        } else if viewModel.isDueSoon {
            return .orange
        } else {
            return .blue
        }
    }

    private var statusText: String {
        if viewModel.task.isCompleted {
            return "Completed"
        } else if viewModel.isOverdue {
            return "Overdue"
        } else if viewModel.isDueSoon {
            return "Due Soon"
        } else {
            return "In Progress"
        }
    }

    private var priorityColor: Color {
        switch viewModel.task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
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

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .fontWeight(.medium)

            VStack(spacing: 12) {
                if let formattedDueDate = viewModel.formattedDueDate {
                    metadataRow(
                        icon: "calendar",
                        title: "Due Date",
                        value: formattedDueDate,
                        valueColor: viewModel.isOverdue ? .red : .primary
                    )
                }

                metadataRow(
                    icon: "calendar.badge.plus",
                    title: "Created",
                    value: viewModel.task.createdDate.formatted(date: .abbreviated, time: .shortened)
                )

                if viewModel.task.modifiedDate != viewModel.task.createdDate {
                    metadataRow(
                        icon: "pencil",
                        title: "Modified",
                        value: viewModel.task.modifiedDate.formatted(date: .abbreviated, time: .shortened)
                    )
                }

                if let completedDate = viewModel.task.completedDate {
                    metadataRow(
                        icon: "checkmark.circle",
                        title: "Completed",
                        value: completedDate.formatted(date: .abbreviated, time: .shortened),
                        valueColor: .green
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metadataRow(
        icon: String,
        title: String,
        value: String,
        valueColor: Color = .secondary
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
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
    }

    // MARK: - Category Section

    private func categorySection(_ category: Category) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.headline)
                .fontWeight(.medium)

            HStack {
                Circle()
                    .fill(Color(hex: category.color) ?? .blue)
                    .frame(width: 12, height: 12)

                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if !category.icon.isEmpty {
                    Image(systemName: category.icon)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Subtasks Section

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subtasks")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                if let subtasks = viewModel.task.subtasks, !subtasks.isEmpty {
                    Text(viewModel.formattedProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    viewModel.showAddSubtaskSheet()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }

            if let subtasks = viewModel.task.subtasks, !subtasks.isEmpty {
                VStack(spacing: 8) {
                    // Progress bar
                    ProgressView(value: viewModel.subtaskProgress)
                        .tint(.blue)

                    // Subtasks list
                    ForEach(subtasks.sorted { $0.order < $1.order }) { subtask in
                        SubtaskRowView(
                            subtask: subtask,
                            isEditing: viewModel.editingSubtask?.id == subtask.id,
                            editingTitle: $viewModel.editingSubtaskTitle,
                            onToggle: {
                                _Concurrency.Task { await viewModel.toggleSubtaskCompletion(subtask) }
                            },
                            onEdit: {
                                viewModel.startEditingSubtask(subtask)
                            },
                            onSave: {
                                _Concurrency.Task { await viewModel.saveSubtaskEdit() }
                            },
                            onCancel: {
                                viewModel.cancelSubtaskEdit()
                            },
                            onDelete: {
                                _Concurrency.Task { await viewModel.deleteSubtask(subtask) }
                            }
                        )
                    }
                }
            } else {
                Text("No subtasks yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Attachments Section

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Button(action: {
                    viewModel.showAttachmentPicker()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(true) // Placeholder for now
            }

            Text("Coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if viewModel.canMarkComplete {
                Button(action: {
                    _Concurrency.Task { await viewModel.toggleTaskCompletion() }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark Complete")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }

            if viewModel.canMarkIncomplete {
                Button(action: {
                    _Concurrency.Task { await viewModel.toggleTaskCompletion() }
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("Mark Incomplete")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
            }
        }
    }
}

// MARK: - Subtask Row View

struct SubtaskRowView: View {
    let subtask: Subtask
    let isEditing: Bool
    @Binding var editingTitle: String
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: subtask.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(subtask.isComplete ? .green : .gray)
            }

            if isEditing {
                TextField("Subtask title", text: $editingTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        onSave()
                    }

                Button("Save", action: onSave)
                    .font(.caption)
                    .buttonStyle(.borderedProminent)

                Button("Cancel", action: onCancel)
                    .font(.caption)
                    .buttonStyle(.bordered)
            } else {
                Text(subtask.title)
                    .strikethrough(subtask.isComplete)
                    .foregroundColor(subtask.isComplete ? .secondary : .primary)

                Spacer()

                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Subtask Sheet

struct AddSubtaskSheet: View {
    @Bindable var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form(content: {
                Section("New Subtask") {
                    TextField("Subtask title", text: $viewModel.newSubtaskTitle)
                        .onSubmit {
                            if viewModel.canAddSubtask {
                                _Concurrency.Task {
                                    await viewModel.addSubtask()
                                    dismiss()
                                }
                            }
                        }
                }
            })
            .navigationTitle("Add Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        _Concurrency.Task {
                            await viewModel.addSubtask()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canAddSubtask || viewModel.isLoading)
                }
            })
        }
    }
}


// MARK: - Preview

#Preview {
    TaskDetailView(task: Task.preview)
        .inject(DIContainer(modelContext: ModelContext.preview))
}
