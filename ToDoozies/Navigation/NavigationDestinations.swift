//
//  NavigationDestinations.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/17/25.
//

import Foundation
import SwiftUI

// MARK: - Task Navigation Destinations

// Modern SwiftUI navigation using native iOS 16+ APIs
enum TaskDestination: Hashable, Identifiable {
    var id: String {
        switch self {
        case .add: return "add"
        case .detail(let task): return "detail-\(task.id)"
        case .edit(let task): return "edit-\(task.id)"
        }
    }
    case add
    case detail(Task)
    case edit(Task)
}

// MARK: - Habit Navigation Destinations

// Modern SwiftUI navigation using native iOS 16+ APIs
enum HabitDestination: Hashable, Identifiable {
    var id: String {
        switch self {
        case .add: return "add"
        case .detail(let habit): return "detail-\(habit.id)"
        case .edit(let habit): return "edit-\(habit.id)"
        }
    }
    case add
    case detail(Habit)
    case edit(Habit)
}

// MARK: - App-Level Destinations

// Modern SwiftUI navigation using native iOS 16+ APIs
enum AppDestination: Hashable, Identifiable {
    var id: String {
        switch self {
        case .settings: return "settings"
        case .categories: return "categories"
        case .addCategory: return "addCategory"
        case .editCategory(let category): return "editCategory-\(category.id)"
        case .notificationSettings: return "notificationSettings"
        case .about: return "about"
        case .search: return "search"
        case .filters: return "filters"
        }
    }
    case settings
    case categories
    case addCategory
    case editCategory(Category)
    case notificationSettings
    case about
    case search
    case filters
}

// MARK: - Navigation Models
// Using @Observable for modern SwiftUI state management (iOS 17+)

@Observable
final class TaskNavigationModel {
    var destination: TaskDestination?

    func showAdd() {
        destination = TaskDestination.add
    }

    func showDetail(_ task: Task) {
        destination = TaskDestination.detail(task)
    }

    func showEdit(_ task: Task) {
        destination = TaskDestination.edit(task)
    }

    func dismiss() {
        destination = nil
    }
}

@Observable
final class HabitNavigationModel {
    var destination: HabitDestination?

    func showAdd() {
        destination = HabitDestination.add
    }

    func showDetail(_ habit: Habit) {
        destination = HabitDestination.detail(habit)
    }

    func showEdit(_ habit: Habit) {
        destination = HabitDestination.edit(habit)
    }

    func dismiss() {
        destination = nil
    }
}

@Observable
final class AppNavigationModel {
    var destination: AppDestination?
    var selectedTab: AppTab = .today

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func showSettings() {
        destination = AppDestination.settings
    }

    func showCategories() {
        destination = AppDestination.categories
    }

    func showAddCategory() {
        destination = AppDestination.addCategory
    }

    func showEditCategory(_ category: Category) {
        destination = AppDestination.editCategory(category)
    }

    func showNotificationSettings() {
        destination = AppDestination.notificationSettings
    }

    func showAbout() {
        destination = AppDestination.about
    }

    func showSearch() {
        destination = AppDestination.search
    }

    func showFilters() {
        destination = AppDestination.filters
    }

    func dismiss() {
        destination = nil
    }
}

// MARK: - Navigation Extensions

extension TaskDestination {
    var title: String {
        switch self {
        case .add:
            return "Add Task"
        case .detail(_):
            return "Task Details"
        case .edit(_):
            return "Edit Task"
        }
    }

    var requiresFullScreen: Bool {
        switch self {
        case .add, .edit(_):
            return true
        case .detail(_):
            return false
        }
    }
}

extension HabitDestination {
    var title: String {
        switch self {
        case .add:
            return "Add Habit"
        case .detail(_):
            return "Habit Details"
        case .edit(_):
            return "Edit Habit"
        }
    }

    var requiresFullScreen: Bool {
        switch self {
        case .add, .edit(_):
            return true
        case .detail(_):
            return false
        }
    }
}

extension AppDestination {
    var title: String {
        switch self {
        case .settings:
            return "Settings"
        case .categories:
            return "Categories"
        case .addCategory:
            return "Add Category"
        case .editCategory(_):
            return "Edit Category"
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
        case .addCategory, .editCategory(_):
            return true
        default:
            return false
        }
    }
}