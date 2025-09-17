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
    @Environment(\.editMode) private var editMode
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var selectedTasks = Set<UUID>()
    @State private var showingBatchDeleteConfirmation = false
    @State private var isEditingTasks = false

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
            .navigationDestination(coordinator: container?.navigationCoordinator ?? NavigationCoordinator())
            .toolbar {
                // Leading toolbar - Edit button
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(isEditingTasks ? "Done" : "Edit") {
                        isEditingTasks.toggle()
                        if !isEditingTasks {
                            selectedTasks.removeAll()
                        }
                    }
                }

                // Trailing toolbar - Selection buttons or normal buttons
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isEditingTasks {
                        if selectedTasks.isEmpty {
                            Button("Select All") {
                                selectAllVisibleTasks()
                            }
                            .font(.caption)
                        } else {
                            Button("Deselect All") {
                                selectedTasks.removeAll()
                            }
                            .font(.caption)
                        }
                    } else {
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

                // Bottom toolbar - Batch action buttons
                ToolbarItemGroup(placement: .bottomBar) {
                    if isEditingTasks {
                        Button("Complete \(selectedTasks.count)") {
                            viewModel.batchCompleteTasks(selectedTasks)
                            selectedTasks.removeAll()
                        }
                        .disabled(selectedTasks.isEmpty)

                        Spacer()

                        Text("\(selectedTasks.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Delete \(selectedTasks.count)", role: .destructive) {
                            showingBatchDeleteConfirmation = true
                        }
                        .disabled(selectedTasks.isEmpty)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedTasks.count) tasks",
                isPresented: $showingBatchDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(selectedTasks.count) Tasks", role: .destructive) {
                    viewModel.batchDeleteTasks(selectedTasks)
                    selectedTasks.removeAll()
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
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
                            .horizontalSpacingPadding(.spacing3)
                            .verticalSpacingPadding(.spacing2)
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
                    FilterBadge(
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
        List(selection: $selectedTasks) {
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

            // Task sections - simplified selection
            ForEach(viewModel.taskSections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.tasks, id: \.id) { task in
                        TaskListRowView(task: task) {
                            if task.isCompleted {
                                viewModel.uncompleteTask(task)
                            } else {
                                viewModel.completeTask(task)
                            }
                        } onEdit: {
                            container?.navigationCoordinator.showEditTask(task)
                        }
                        .tag(task.id)  // Explicitly tag with the task ID
                        .onTapGesture {
                            if !isEditingTasks {
                                container?.navigationCoordinator.showTaskDetail(task)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                viewModel.deleteTask(task)
                            }

                            Button("Edit") {
                                container?.navigationCoordinator.showEditTask(task)
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            taskContextMenu(for: task)
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(isEditingTasks ? .active : .inactive))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: .spacing5) {
            Spacer()

            Image(systemName: viewModel.hasActiveFilters ? "magnifyingglass" : "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: .spacing2) {
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
        .spacingPadding(.spacing4)
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

    // MARK: - Selection Helpers

    private func selectAllVisibleTasks() {
        let visibleTaskIds = Set(viewModel.displayedTasks.map { $0.id })
        selectedTasks = visibleTaskIds
    }
}

// MARK: - Task List Row View

struct TaskListRowView: View {
    let task: Task
    let onToggleComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            CompletionButton(
                isCompleted: task.isCompleted,
                style: .task,
                accessibilityLabel: task.isCompleted ? "Mark incomplete" : "Mark complete"
            ) {
                onToggleComplete()
            }

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

            // Options button
            Button(action: onEdit) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Task options")
            .accessibilityHint("Double tap to view task options and details")
        }
    }

    private func priorityBadge(_ priority: Priority) -> some View {
        PriorityBadge(priority: priority, size: .small)
    }
}

// MARK: - Filter Chip (Legacy - use FilterBadge instead)

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
