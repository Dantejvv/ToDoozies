//
//  TasksView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.diContainer) private var container
    @State private var showingFilters = false
    @State private var searchText = ""

    private var viewModel: TasksViewModel {
        container?.tasksViewModel ?? TasksViewModel(
            appState: AppState(),
            taskService: TaskService(modelContext: ModelContext.preview, appState: AppState())
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filter indicators
                if viewModel.hasActiveFilters {
                    activeFiltersView
                }

                // Task sections
                if viewModel.displayedTasks.isEmpty {
                    emptyStateView
                } else {
                    tasksList
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }

                    Button(action: {
                        container?.navigationCoordinator.showAddTask()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingFilters) {
                FiltersView(viewModel: viewModel)
            }
            .searchable(text: $searchText, prompt: "Search tasks...")
            .onChange(of: searchText) { _, newValue in
                viewModel.updateSearchText(newValue)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack {
            if !searchText.isEmpty && !viewModel.searchSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                searchText = suggestion
                                viewModel.updateSearchText(suggestion)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Active Filters View

    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(activeFilterChips, id: \.title) { chip in
                    FilterChip(
                        title: chip.title,
                        systemImage: chip.systemImage,
                        onRemove: chip.onRemove
                    )
                }

                if viewModel.hasActiveFilters {
                    Button("Clear All") {
                        viewModel.clearAllFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Tasks List

    private var tasksList: some View {
        List {
            // Task count summary
            Section {
                HStack {
                    Text(viewModel.taskCountText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    sortPicker
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }

            // Task sections
            ForEach(viewModel.taskSections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.tasks) { task in
                        TaskListRowView(task: task) {
                            if task.isCompleted {
                                viewModel.uncompleteTask(task)
                            } else {
                                viewModel.completeTask(task)
                            }
                        } onTap: {
                            container?.navigationCoordinator.showTaskDetail(task)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                viewModel.deleteTask(task)
                            }

                            Button("Edit") {
                                container?.navigationCoordinator.showEditTask(task)
                            }
                            .tint(.blue)

                            Button("Duplicate") {
                                viewModel.duplicateTask(task)
                            }
                            .tint(.green)
                        }
                        .contextMenu {
                            taskContextMenu(for: task)
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: viewModel.hasActiveFilters ? "magnifyingglass" : "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(viewModel.hasActiveFilters ? "No matching tasks" : "No tasks yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(viewModel.hasActiveFilters ? "Try adjusting your filters" : "Add your first task to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.hasActiveFilters {
                Button("Add Task") {
                    container?.navigationCoordinator.showAddTask()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        Menu {
            ForEach(TaskSortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.setSortOption(option)
                } label: {
                    HStack {
                        Text(option.displayName)
                        if viewModel.selectedSortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.selectedSortOption.iconName)
                Text(viewModel.selectedSortOption.displayName)
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Helper Views

    private func taskContextMenu(for task: Task) -> some View {
        Group {
            Button("View Details") {
                container?.navigationCoordinator.showTaskDetail(task)
            }

            Button("Edit") {
                container?.navigationCoordinator.showEditTask(task)
            }

            Button("Duplicate") {
                viewModel.duplicateTask(task)
            }

            Divider()

            if !task.isCompleted {
                Button("Mark Complete") {
                    viewModel.completeTask(task)
                }
            } else {
                Button("Mark Incomplete") {
                    viewModel.uncompleteTask(task)
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                viewModel.deleteTask(task)
            }
        }
    }

    // MARK: - Active Filter Chips

    private var activeFilterChips: [FilterChipData] {
        var chips: [FilterChipData] = []

        if !searchText.isEmpty {
            chips.append(FilterChipData(
                title: "Search: \(searchText)",
                systemImage: "magnifyingglass",
                onRemove: { viewModel.clearSearch() }
            ))
        }

        if let priority = container?.appState.selectedPriority {
            chips.append(FilterChipData(
                title: priority.displayName,
                systemImage: "exclamationmark.triangle",
                onRemove: { viewModel.selectPriorityFilter(nil) }
            ))
        }

        if let category = container?.appState.selectedCategory {
            chips.append(FilterChipData(
                title: category.name,
                systemImage: "folder",
                onRemove: { viewModel.selectCategoryFilter(nil) }
            ))
        }

        if container?.appState.showOnlyIncomplete == true {
            chips.append(FilterChipData(
                title: "Incomplete Only",
                systemImage: "circle",
                onRemove: { viewModel.toggleIncompleteFilter() }
            ))
        }

        return chips
    }
}

// MARK: - Task List Row View

struct TaskListRowView: View {
    let task: Task
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion button
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())

                // Task content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .multilineTextAlignment(.leading)

                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Metadata row
                    HStack {
                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                Text(dueDate, style: task.isDueToday ? .time : .date)
                            }
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                        }

                        // Category
                        if let category = task.category {
                            HStack(spacing: 2) {
                                Image(systemName: "folder")
                                Text(category.name)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Priority badge
                        if task.priority != .medium {
                            priorityBadge(task.priority)
                        }

                        // Subtasks indicator
                        if let subtasks = task.subtasks, !subtasks.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "checklist")
                                Text("\(subtasks.filter { $0.isComplete }.count)/\(subtasks.count)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let systemImage: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)

            Text(title)
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .foregroundColor(.accentColor)
        .clipShape(Capsule())
    }
}

struct FilterChipData {
    let title: String
    let systemImage: String
    let onRemove: () -> Void
}

// MARK: - Filters View

struct FiltersView: View {
    let viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var container

    var body: some View {
        NavigationStack {
            List {
                Section("Priority") {
                    ForEach([Priority.high, Priority.medium, Priority.low], id: \.self) { priority in
                        Button {
                            if container?.appState.selectedPriority == priority {
                                viewModel.selectPriorityFilter(nil)
                            } else {
                                viewModel.selectPriorityFilter(priority)
                            }
                        } label: {
                            HStack {
                                Text(priority.displayName)
                                Spacer()
                                if container?.appState.selectedPriority == priority {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section("Category") {
                    ForEach(viewModel.availableCategories) { category in
                        Button {
                            if container?.appState.selectedCategory?.id == category.id {
                                viewModel.selectCategoryFilter(nil)
                            } else {
                                viewModel.selectCategoryFilter(category)
                            }
                        } label: {
                            HStack {
                                Text(category.name)
                                Spacer()
                                if container?.appState.selectedCategory?.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section("Status") {
                    Button {
                        viewModel.toggleIncompleteFilter()
                    } label: {
                        HStack {
                            Text("Show only incomplete")
                            Spacer()
                            if container?.appState.showOnlyIncomplete == true {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }

                if viewModel.hasActiveFilters {
                    Section {
                        Button("Clear All Filters") {
                            viewModel.clearAllFilters()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TasksView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}