//
//  TasksViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class TasksViewModel {
    private let appState: AppState
    private let taskService: TaskServiceProtocol

    // MARK: - View State
    var isRefreshing: Bool = false
    var showingAddTask: Bool = false
    var showingFilters: Bool = false
    var selectedSortOption: TaskSortOption = .dueDate
    var showingSearch: Bool = false

    init(
        appState: AppState,
        taskService: TaskServiceProtocol
    ) {
        self.appState = appState
        self.taskService = taskService
    }

    // MARK: - Computed Properties

    /// All tasks filtered and sorted according to current settings
    var displayedTasks: [Task] {
        var tasks = appState.filteredTasks

        // Apply sorting
        switch selectedSortOption {
        case .dueDate:
            tasks.sort { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case let (date1?, date2?):
                    return date1 < date2
                case (nil, _?):
                    return false // Tasks without due date go to end
                case (_?, nil):
                    return true // Tasks with due date go first
                case (nil, nil):
                    return task1.createdDate > task2.createdDate // Newest first
                }
            }
        case .priority:
            tasks.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        case .title:
            tasks.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .createdDate:
            tasks.sort { $0.createdDate > $1.createdDate }
        case .category:
            tasks.sort { task1, task2 in
                let category1 = task1.category?.name ?? "No Category"
                let category2 = task2.category?.name ?? "No Category"
                return category1.localizedCompare(category2) == .orderedAscending
            }
        }

        return tasks
    }

    /// Tasks grouped by sections for display
    var taskSections: [TaskSection] {
        let tasks = displayedTasks
        var sections: [TaskSection] = []

        switch selectedSortOption {
        case .dueDate:
            sections = groupTasksByDueDate(tasks)
        case .priority:
            sections = groupTasksByPriority(tasks)
        case .category:
            sections = groupTasksByCategory(tasks)
        case .title, .createdDate:
            // For these sort options, don't group - show as single section
            if !tasks.isEmpty {
                sections = [TaskSection(title: "All Tasks", tasks: tasks)]
            }
        }

        return sections
    }

    /// Search suggestions based on current input
    var searchSuggestions: [String] {
        guard !appState.searchText.isEmpty else { return [] }

        let allTitles = appState.tasks.map { $0.title }
        let suggestions = allTitles.filter { title in
            title.localizedCaseInsensitiveContains(appState.searchText) &&
            title.lowercased() != appState.searchText.lowercased()
        }

        return Array(Set(suggestions)).prefix(5).map { String($0) }
    }

    /// Available categories for filtering
    var availableCategories: [Category] {
        appState.categories.sorted { $0.name < $1.name }
    }

    /// Task count summary text
    var taskCountText: String {
        let total = displayedTasks.count
        let completed = displayedTasks.filter { $0.isCompleted }.count
        return "\(completed) of \(total) tasks completed"
    }

    /// Whether filters are active
    var hasActiveFilters: Bool {
        !appState.searchText.isEmpty ||
        appState.selectedPriority != nil ||
        appState.selectedCategory != nil ||
        appState.showOnlyIncomplete
    }

    // MARK: - Actions

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await taskService.refreshTasks()
        } catch {
            appState.setError(.dataLoadingFailed(error.localizedDescription))
        }
    }

    func completeTask(_ task: Task) {
        task.markCompleted()
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
        _Concurrency.Task {
            do {
                try await taskService.updateTask(task)
            } catch {
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

    func duplicateTask(_ task: Task) {
        let duplicatedTask = Task(
            title: "\(task.title) (Copy)",
            description: task.taskDescription,
            dueDate: task.dueDate,
            priority: task.priority,
            status: .notStarted
        )
        duplicatedTask.category = task.category

        appState.addTask(duplicatedTask)

        _Concurrency.Task {
            do {
                try await taskService.createTask(duplicatedTask)
            } catch {
                appState.removeTask(duplicatedTask) // Rollback on error
                appState.setError(.dataSavingFailed(error.localizedDescription))
            }
        }
    }

    func updateSearchText(_ text: String) {
        appState.searchText = text
    }

    func clearSearch() {
        appState.searchText = ""
    }

    func selectPriorityFilter(_ priority: Priority?) {
        appState.selectedPriority = priority
    }

    func selectCategoryFilter(_ category: Category?) {
        appState.selectedCategory = category
    }

    func toggleIncompleteFilter() {
        appState.showOnlyIncomplete.toggle()
    }

    func clearAllFilters() {
        appState.searchText = ""
        appState.selectedPriority = nil
        appState.selectedCategory = nil
        appState.showOnlyIncomplete = false
    }

    func setSortOption(_ option: TaskSortOption) {
        selectedSortOption = option
    }

    // MARK: - Helper Methods

    private func groupTasksByDueDate(_ tasks: [Task]) -> [TaskSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!

        var sections: [TaskSection] = []

        // Overdue
        let overdue = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < today && !task.isCompleted
        }
        if !overdue.isEmpty {
            sections.append(TaskSection(title: "Overdue", tasks: overdue))
        }

        // Today
        let todayTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today)
        }
        if !todayTasks.isEmpty {
            sections.append(TaskSection(title: "Today", tasks: todayTasks))
        }

        // Tomorrow
        let tomorrowTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: tomorrow)
        }
        if !tomorrowTasks.isEmpty {
            sections.append(TaskSection(title: "Tomorrow", tasks: tomorrowTasks))
        }

        // This Week
        let thisWeekTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate > tomorrow && dueDate < nextWeek
        }
        if !thisWeekTasks.isEmpty {
            sections.append(TaskSection(title: "This Week", tasks: thisWeekTasks))
        }

        // Later
        let laterTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= nextWeek
        }
        if !laterTasks.isEmpty {
            sections.append(TaskSection(title: "Later", tasks: laterTasks))
        }

        // No Due Date
        let noDueDateTasks = tasks.filter { $0.dueDate == nil }
        if !noDueDateTasks.isEmpty {
            sections.append(TaskSection(title: "No Due Date", tasks: noDueDateTasks))
        }

        return sections
    }

    private func groupTasksByPriority(_ tasks: [Task]) -> [TaskSection] {
        var sections: [TaskSection] = []

        for priority in Priority.allCases.reversed() { // High to Low
            let priorityTasks = tasks.filter { $0.priority == priority }
            if !priorityTasks.isEmpty {
                sections.append(TaskSection(title: priority.displayName, tasks: priorityTasks))
            }
        }

        return sections
    }

    private func groupTasksByCategory(_ tasks: [Task]) -> [TaskSection] {
        var sections: [TaskSection] = []

        // Group by category
        let categorizedTasks = Dictionary(grouping: tasks) { task in
            task.category?.name ?? "No Category"
        }

        // Sort categories alphabetically
        let sortedCategories = categorizedTasks.keys.sorted()

        for categoryName in sortedCategories {
            if let categoryTasks = categorizedTasks[categoryName] {
                sections.append(TaskSection(title: categoryName, tasks: categoryTasks))
            }
        }

        return sections
    }
}

// MARK: - Supporting Types

struct TaskSection {
    let title: String
    let tasks: [Task]
}

enum TaskSortOption: String, CaseIterable {
    case dueDate = "dueDate"
    case priority = "priority"
    case title = "title"
    case createdDate = "createdDate"
    case category = "category"

    var displayName: String {
        switch self {
        case .dueDate: return "Due Date"
        case .priority: return "Priority"
        case .title: return "Title"
        case .createdDate: return "Created Date"
        case .category: return "Category"
        }
    }

    var iconName: String {
        switch self {
        case .dueDate: return "calendar"
        case .priority: return "exclamationmark.triangle"
        case .title: return "textformat.abc"
        case .createdDate: return "clock"
        case .category: return "folder"
        }
    }
}
