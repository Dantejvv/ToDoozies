//
//  NavigationViewBuilder.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/17/25.
//

import SwiftUI

// MARK: - Navigation View Builder
// Modern SwiftUI navigation view factory using native iOS 16+ APIs

struct NavigationViewBuilder {

    // MARK: - Task Destinations

    @ViewBuilder
    static func view(for destination: TaskDestination) -> some View {
        switch destination {
        case .add:
            AddTaskView()
        case .detail(let task):
            TaskDetailView(task: task)
        case .edit(let task):
            EditTaskView(task: task)
        }
    }

    // MARK: - Habit Destinations

    @ViewBuilder
    static func view(for destination: HabitDestination) -> some View {
        switch destination {
        case .add:
            AddHabitView()
        case .detail(let habit):
            HabitDetailView(habit: habit)
        case .edit(let habit):
            EditHabitView(habit: habit)
        }
    }

    // MARK: - App Destinations

    @ViewBuilder
    static func view(for destination: AppDestination) -> some View {
        switch destination {
        case .settings:
            SettingsView()
        case .categories:
            Text("Categories View")
                .navigationTitle("Categories")
        case .addCategory:
            Text("Add Category View")
                .navigationTitle("Add Category")
        case .editCategory(let category):
            Text("Edit Category View for: \(category.name)")
                .navigationTitle("Edit Category")
        case .notificationSettings:
            Text("Notification Settings View")
                .navigationTitle("Notifications")
        case .about:
            Text("About View")
                .navigationTitle("About")
        case .search:
            Text("Search View")
                .navigationTitle("Search")
        case .filters:
            Text("Filters View")
                .navigationTitle("Filters")
        }
    }
}

// MARK: - Navigation View Modifiers
// Modern SwiftUI navigation modifiers using navigationDestination and sheet APIs

extension View {

    func taskNavigation(_ model: TaskNavigationModel) -> some View {
        self
            .navigationDestination(item: Binding(
                get: { model.destination },
                set: { model.destination = $0 }
            )) { destination in
                NavigationViewBuilder.view(for: destination)
            }
            .sheet(item: Binding(
                get: { model.destination?.requiresFullScreen == true ? model.destination : nil },
                set: { _ in model.dismiss() }
            )) { destination in
                NavigationStack {
                    NavigationViewBuilder.view(for: destination)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    model.dismiss()
                                }
                            }
                        }
                }
            }
    }

    func habitNavigation(_ model: HabitNavigationModel) -> some View {
        self
            .navigationDestination(item: Binding(
                get: { model.destination },
                set: { model.destination = $0 }
            )) { destination in
                NavigationViewBuilder.view(for: destination)
            }
            .sheet(item: Binding(
                get: { model.destination?.requiresFullScreen == true ? model.destination : nil },
                set: { _ in model.dismiss() }
            )) { destination in
                NavigationStack {
                    NavigationViewBuilder.view(for: destination)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    model.dismiss()
                                }
                            }
                        }
                }
            }
    }

    func appNavigation(_ model: AppNavigationModel) -> some View {
        self
            .navigationDestination(item: Binding(
                get: { model.destination },
                set: { model.destination = $0 }
            )) { destination in
                NavigationViewBuilder.view(for: destination)
            }
            .sheet(item: Binding(
                get: { model.destination?.requiresFullScreen == true ? model.destination : nil },
                set: { _ in model.dismiss() }
            )) { destination in
                NavigationStack {
                    NavigationViewBuilder.view(for: destination)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    model.dismiss()
                                }
                            }
                        }
                }
            }
    }
}