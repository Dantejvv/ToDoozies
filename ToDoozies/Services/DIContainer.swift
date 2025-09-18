//
//  DIContainer.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import Network

// MARK: - ModelContext Preview Extension
extension ModelContext {
    @MainActor
    static var preview: ModelContext {
        let schema = Schema([
            Task.self,
            RecurrenceRule.self,
            Category.self,
            Subtask.self,
            Attachment.self,
            Habit.self,
        ])

        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container.mainContext
        } catch {
            fatalError("Could not create preview ModelContext: \(error)")
        }
    }
}

// MARK: - Dependency Injection Container

@MainActor
final class DIContainer {
    // MARK: - Core Dependencies
    let modelContext: ModelContext
    let appState: AppState
    let navigationCoordinator: NavigationCoordinator // Legacy - will be removed

    // MARK: - New Navigation Models
    let taskNavigation: TaskNavigationModel
    let habitNavigation: HabitNavigationModel
    let appNavigation: AppNavigationModel

    // MARK: - Services
    private(set) var taskService: TaskServiceProtocol
    private(set) var habitService: HabitServiceProtocol
    private(set) var categoryService: CategoryServiceProtocol
    private(set) var attachmentService: AttachmentServiceProtocol
    private(set) var notificationService: NotificationServiceProtocol
    private(set) var cloudKitSyncService: CloudKitSyncService
    private(set) var networkMonitor: NetworkMonitor

    // MARK: - Combine Support
    private var cancellables = Set<AnyCancellable>()

    // MARK: - ViewModels
    private(set) lazy var todayViewModel: TodayViewModel = TodayViewModel(
        appState: appState,
        taskService: taskService,
        habitService: habitService
    )

    private(set) lazy var tasksViewModel: TasksViewModel = TasksViewModel(
        appState: appState,
        taskService: taskService
    )

    private(set) lazy var habitsViewModel: HabitsViewModel = HabitsViewModel(
        appState: appState,
        habitService: habitService,
        taskService: taskService
    )

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize core dependencies
        self.appState = AppState()
        self.navigationCoordinator = NavigationCoordinator() // Legacy

        // Initialize new navigation models
        self.taskNavigation = TaskNavigationModel()
        self.habitNavigation = HabitNavigationModel()
        self.appNavigation = AppNavigationModel()

        // Initialize services
        let taskService = TaskService(modelContext: modelContext, appState: appState)
        let habitService = HabitService(modelContext: modelContext, appState: appState)
        let attachmentService = AttachmentService(modelContext: modelContext, appState: appState)

        self.taskService = taskService
        self.habitService = habitService
        self.categoryService = CategoryService(modelContext: modelContext, appState: appState)
        self.attachmentService = attachmentService
        self.notificationService = NotificationService()
        self.cloudKitSyncService = CloudKitSyncService(appState: appState)
        self.networkMonitor = NetworkMonitor()

        // Set back-references for offline tracking
        if let taskService = self.taskService as? TaskService {
            taskService.diContainer = self
        }
        if let habitService = self.habitService as? HabitService {
            habitService.diContainer = self
        }
        if let attachmentService = self.attachmentService as? AttachmentService {
            attachmentService.diContainer = self
        }

        // ViewModels are initialized lazily when first accessed
        setupNetworkMonitoring()
    }

    // MARK: - Factory Methods

    func makeAddTaskViewModel() -> AddTaskViewModel {
        return AddTaskViewModel(
            appState: appState,
            taskService: taskService,
            categoryService: categoryService,
            attachmentService: attachmentService,
            navigationCoordinator: navigationCoordinator
        )
    }

    func makeEditTaskViewModel(task: Task) -> EditTaskViewModel {
        return EditTaskViewModel(
            task: task,
            appState: appState,
            taskService: taskService,
            categoryService: categoryService,
            navigationCoordinator: navigationCoordinator
        )
    }

    func makeAddHabitViewModel() -> AddHabitViewModel {
        return AddHabitViewModel(
            appState: appState,
            habitService: habitService,
            taskService: taskService,
            categoryService: categoryService
        )
    }

    func makeTaskDetailViewModel(task: Task) -> TaskDetailViewModel {
        return TaskDetailViewModel(
            task: task,
            appState: appState,
            taskService: taskService,
            attachmentService: attachmentService,
            navigationCoordinator: navigationCoordinator
        )
    }

    func makeHabitDetailViewModel(habit: Habit) -> HabitDetailViewModel {
        return HabitDetailViewModel(
            habit: habit,
            appState: appState,
            habitService: habitService,
            navigationCoordinator: navigationCoordinator
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            appState: appState,
            notificationService: notificationService,
            navigationCoordinator: navigationCoordinator
        )
    }

    // MARK: - Lifecycle Methods

    func loadInitialData() async {
        do {
            // Start CloudKit sync monitoring
            cloudKitSyncService.startMonitoring()

            async let tasks: Void = taskService.refreshTasks()
            async let habits: Void = habitService.refreshHabits()
            async let categories: Void = categoryService.refreshCategories()

            try await tasks
            try await habits
            try await categories

            // Load default categories if none exist
            if appState.categories.isEmpty {
                try await createDefaultCategories()
            }

        } catch {
            appState.setError(.dataLoadingFailed("Failed to load initial data: \(error.localizedDescription)"))
        }
    }

    private func createDefaultCategories() async throws {
        let defaultCategories = [
            Category(name: "Personal", color: "#007AFF", icon: "person.fill", order: 1),
            Category(name: "Work", color: "#FF9500", icon: "briefcase.fill", order: 2),
            Category(name: "Health", color: "#34C759", icon: "heart.fill", order: 3),
            Category(name: "Learning", color: "#5856D6", icon: "book.fill", order: 4),
            Category(name: "Home", color: "#FF2D92", icon: "house.fill", order: 5)
        ]

        for category in defaultCategories {
            try await categoryService.createCategory(category)
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        // Perform any necessary cleanup
        // Cancel ongoing tasks, save state, etc.
        cloudKitSyncService.stopMonitoring()
        networkMonitor.stopMonitoring()
        cancellables.removeAll()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        // Monitor network connectivity changes
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                self?.handleNetworkChange(isConnected: isConnected)
            }
            .store(in: &cancellables)

        // Monitor connection type changes for better user feedback
        networkMonitor.$connectionType
            .removeDuplicates()
            .sink { [weak self] connectionType in
                self?.handleConnectionTypeChange(connectionType)
            }
            .store(in: &cancellables)
    }

    private func handleNetworkChange(isConnected: Bool) {
        if isConnected {
            // Network came back online
            appState.setOfflineMode(.reconnecting)

            // Attempt to sync when coming back online
            ConcurrentTask {
                do {
                    await cloudKitSyncService.forcSync()
                    appState.setOfflineMode(.online)
                    appState.clearPendingChanges()
                } catch {
                    // Sync failed, but we're connected - might be a server issue
                    appState.setOfflineMode(.online)
                    print("Sync failed after reconnection: \(error)")
                }
            }
        } else {
            // Network went offline
            appState.setOfflineMode(.offline)
        }
    }

    private func handleConnectionTypeChange(_ connectionType: NWInterface.InterfaceType?) {
        // This could be used for more sophisticated handling
        // e.g., warn users on expensive cellular connections
        if connectionType == .cellular && networkMonitor.isExpensive {
            // Could show a warning about data usage
            print("Using cellular connection - may be expensive")
        }
    }

    // MARK: - Offline Change Tracking

    func trackOfflineChange() {
        if !networkMonitor.isConnected {
            appState.incrementPendingChanges()
        }
    }
}

// MARK: - Environment Keys

struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer? = nil
}

struct TaskNavigationKey: EnvironmentKey {
    static let defaultValue: TaskNavigationModel? = nil
}

struct HabitNavigationKey: EnvironmentKey {
    static let defaultValue: HabitNavigationModel? = nil
}

struct AppNavigationKey: EnvironmentKey {
    static let defaultValue: AppNavigationModel? = nil
}

extension EnvironmentValues {
    var diContainer: DIContainer? {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }

    var taskNavigation: TaskNavigationModel? {
        get { self[TaskNavigationKey.self] }
        set { self[TaskNavigationKey.self] = newValue }
    }

    var habitNavigation: HabitNavigationModel? {
        get { self[HabitNavigationKey.self] }
        set { self[HabitNavigationKey.self] = newValue }
    }

    var appNavigation: AppNavigationModel? {
        get { self[AppNavigationKey.self] }
        set { self[AppNavigationKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    func inject(_ container: DIContainer) -> some View {
        self
            .environment(\.diContainer, container)
            .environment(\.taskNavigation, container.taskNavigation)
            .environment(\.habitNavigation, container.habitNavigation)
            .environment(\.appNavigation, container.appNavigation)
    }
}

// MARK: - Additional Service Protocols and Implementations

// MARK: - Category Service

protocol CategoryServiceProtocol {
    func refreshCategories() async throws
    func createCategory(_ category: Category) async throws
    func updateCategory(_ category: Category) async throws
    func deleteCategory(_ category: Category) async throws
}

@MainActor
final class CategoryService: CategoryServiceProtocol {
    private let modelContext: ModelContext
    private let appState: AppState

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    func refreshCategories() async throws {
        do {
            let descriptor = FetchDescriptor<Category>(
                sortBy: [SortDescriptor(\.order), SortDescriptor(\.name)]
            )
            let categories = try modelContext.fetch(descriptor)
            appState.setCategories(categories)
        } catch {
            throw AppError.dataLoadingFailed("Failed to refresh categories: \(error.localizedDescription)")
        }
    }

    func createCategory(_ category: Category) async throws {
        do {
            modelContext.insert(category)
            try modelContext.save()
            appState.addCategory(category)
        } catch {
            throw AppError.dataSavingFailed("Failed to create category: \(error.localizedDescription)")
        }
    }

    func updateCategory(_ category: Category) async throws {
        do {
            category.updateModifiedDate()
            try modelContext.save()
        } catch {
            throw AppError.dataSavingFailed("Failed to update category: \(error.localizedDescription)")
        }
    }

    func deleteCategory(_ category: Category) async throws {
        do {
            modelContext.delete(category)
            try modelContext.save()
            appState.removeCategory(category)
        } catch {
            throw AppError.dataSavingFailed("Failed to delete category: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Service

protocol NotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func scheduleTaskReminder(for task: Task) async throws
    func cancelTaskReminder(for task: Task) async throws
    func scheduleHabitReminder(for habit: Habit) async throws
}

final class NotificationService: NotificationServiceProtocol {
    func requestPermission() async throws -> Bool {
        // TODO: Implement notification permission request
        return true
    }

    func scheduleTaskReminder(for task: Task) async throws {
        // TODO: Implement task reminder scheduling
    }

    func cancelTaskReminder(for task: Task) async throws {
        // TODO: Implement task reminder cancellation
    }

    func scheduleHabitReminder(for habit: Habit) async throws {
        // TODO: Implement habit reminder scheduling
    }

}

// MARK: - Placeholder ViewModels

// These are placeholder classes that will be implemented later





class SettingsViewModel: ObservableObject {
    init(appState: AppState, notificationService: NotificationServiceProtocol, navigationCoordinator: NavigationCoordinator) {}
}