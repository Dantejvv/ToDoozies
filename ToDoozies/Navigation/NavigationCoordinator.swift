//
//  NavigationCoordinator.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftUI
import Observation

// MARK: - Navigation Coordinator

@Observable
final class NavigationCoordinator {
    // MARK: - Navigation State
    var selectedTab: AppTab = .today
    var destination: AppDestination?

    // MARK: - Navigation History
    private var navigationHistory: [AppDestination] = []

    init() {}

    // MARK: - Tab Navigation

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    // MARK: - Destination Navigation

    func navigate(to destination: AppDestination) {
        self.destination = destination
        navigationHistory.append(destination)
    }

    func dismiss() {
        destination = nil
    }

    func dismissSheet() {
        destination = nil
    }

    func goBack() {
        destination = nil
        if !navigationHistory.isEmpty {
            navigationHistory.removeLast()
        }
    }

    // MARK: - Convenience Navigation Methods

    func showAddTask() {
        navigate(to: .addTask)
    }

    func showTaskDetail(_ task: Task) {
        navigate(to: .taskDetail(task))
    }

    func showEditTask(_ task: Task) {
        navigate(to: .editTask(task))
    }

    func showAddHabit() {
        navigate(to: .addHabit)
    }

    func showHabitDetail(_ habit: Habit) {
        navigate(to: .habitDetail(habit))
    }

    func showEditHabit(_ habit: Habit) {
        navigate(to: .editHabit(habit))
    }

    func showSettings() {
        navigate(to: .settings)
    }

    func showCategories() {
        navigate(to: .categories)
    }

    func showAddCategory() {
        navigate(to: .addCategory)
    }

    func showNotificationSettings() {
        navigate(to: .notificationSettings)
    }

    func showAbout() {
        navigate(to: .about)
    }

    // MARK: - Deep Linking Support

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }

        switch host {
        case "task":
            if let taskIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let taskId = UUID(uuidString: taskIdString) {
                // Find task and navigate to it
                // This would typically involve a lookup from your data source
                // For now, we'll just navigate to the tasks tab
                selectedTab = .tasks
            }

        case "habit":
            if let habitIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let habitId = UUID(uuidString: habitIdString) {
                // Find habit and navigate to it
                selectedTab = .habits
            }

        case "add":
            if let type = components.queryItems?.first(where: { $0.name == "type" })?.value {
                switch type {
                case "task":
                    showAddTask()
                case "habit":
                    showAddHabit()
                default:
                    break
                }
            }

        default:
            break
        }
    }

    // MARK: - State Queries

    var canGoBack: Bool {
        !navigationHistory.isEmpty
    }

    var currentDestination: AppDestination? {
        destination
    }
}

// MARK: - App Destination Enum

// Note: This will need to be updated to use @CasePathable when Swift Navigation library is added
enum AppDestination: Hashable, Identifiable {
    var id: String {
        switch self {
        case .addTask: return "addTask"
        case .taskDetail(let task): return "taskDetail-\(task.id)"
        case .editTask(let task): return "editTask-\(task.id)"
        case .addHabit: return "addHabit"
        case .habitDetail(let habit): return "habitDetail-\(habit.id)"
        case .editHabit(let habit): return "editHabit-\(habit.id)"
        case .categories: return "categories"
        case .addCategory: return "addCategory"
        case .editCategory(let category): return "editCategory-\(category.id)"
        case .settings: return "settings"
        case .notificationSettings: return "notificationSettings"
        case .about: return "about"
        case .search: return "search"
        case .filters: return "filters"
        }
    }
    // Task-related destinations
    case addTask
    case taskDetail(Task)
    case editTask(Task)

    // Habit-related destinations
    case addHabit
    case habitDetail(Habit)
    case editHabit(Habit)

    // Category-related destinations
    case categories
    case addCategory
    case editCategory(Category)

    // Settings-related destinations
    case settings
    case notificationSettings
    case about

    // Other destinations
    case search
    case filters
}

// MARK: - Navigation Extensions

extension AppDestination {
    var title: String {
        switch self {
        case .addTask:
            return "Add Task"
        case .taskDetail(_):
            return "Task Details"
        case .editTask(_):
            return "Edit Task"
        case .addHabit:
            return "Add Habit"
        case .habitDetail(_):
            return "Habit Details"
        case .editHabit(_):
            return "Edit Habit"
        case .categories:
            return "Categories"
        case .addCategory:
            return "Add Category"
        case .editCategory(_):
            return "Edit Category"
        case .settings:
            return "Settings"
        case .notificationSettings:
            return "Notifications"
        case .about:
            return "About"
        case .search:
            return "Search"
        case .filters:
            return "Filters"
        }
    }

    var requiresFullScreen: Bool {
        switch self {
        case .addTask, .addHabit, .addCategory, .editTask(_), .editHabit(_), .editCategory(_):
            return true
        default:
            return false
        }
    }
}

// MARK: - Navigation View Modifiers

extension View {
    func navigationDestination(coordinator: NavigationCoordinator) -> some View {
        self.navigationDestination(item: Binding(
            get: { coordinator.destination },
            set: { coordinator.destination = $0 }
        )) { destination in
            destinationView(for: destination, coordinator: coordinator)
        }
    }

    func sheet(coordinator: NavigationCoordinator) -> some View {
        self.sheet(item: Binding(
            get: { coordinator.destination?.requiresFullScreen == true ? coordinator.destination : nil },
            set: { _ in coordinator.dismiss() }
        )) { destination in
            NavigationStack {
                destinationView(for: destination, coordinator: coordinator)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                coordinator.dismiss()
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination, coordinator: NavigationCoordinator) -> some View {
        switch destination {
        case .addTask:
            AddTaskView()

        case .taskDetail(let task):
            TaskDetailView(task: task)

        case .editTask(let task):
            EditTaskView(task: task)

        case .addHabit:
            Text("Add Habit View")
                .navigationTitle(destination.title)

        case .habitDetail(let habit):
            Text("Habit Detail View for: \(habit.baseTask?.title ?? "Unknown")")
                .navigationTitle(destination.title)

        case .editHabit(let habit):
            Text("Edit Habit View for: \(habit.baseTask?.title ?? "Unknown")")
                .navigationTitle(destination.title)

        case .categories:
            Text("Categories View")
                .navigationTitle(destination.title)

        case .addCategory:
            Text("Add Category View")
                .navigationTitle(destination.title)

        case .editCategory(let category):
            Text("Edit Category View for: \(category.name)")
                .navigationTitle(destination.title)

        case .settings:
            Text("Settings View")
                .navigationTitle(destination.title)

        case .notificationSettings:
            Text("Notification Settings View")
                .navigationTitle(destination.title)

        case .about:
            Text("About View")
                .navigationTitle(destination.title)

        case .search:
            Text("Search View")
                .navigationTitle(destination.title)

        case .filters:
            Text("Filters View")
                .navigationTitle(destination.title)
        }
    }
}