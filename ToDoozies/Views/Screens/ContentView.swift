//
//  ContentView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.diContainer) private var container
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var navigationCoordinator: NavigationCoordinator {
        container?.navigationCoordinator ?? NavigationCoordinator()
    }

    private var appState: AppState {
        container?.appState ?? AppState()
    }

    var body: some View {
        TabView(selection: Binding(
            get: { navigationCoordinator.selectedTab },
            set: { navigationCoordinator.selectTab($0) }
        )) {
            // Today Tab
            TodayView()
                .tabItem {
                    Image(systemName: AppTab.today.iconName)
                    Text(AppTab.today.title)
                }
                .tag(AppTab.today)
                .accessibilityLabel("Today's tasks and habits")
                .accessibilityHint("Shows tasks due today and daily habit progress")

            // Tasks Tab
            TasksView()
                .tabItem {
                    Image(systemName: AppTab.tasks.iconName)
                    Text(AppTab.tasks.title)
                }
                .tag(AppTab.tasks)
                .badge(appState.incompleteTasks.count > 0 ? appState.incompleteTasks.count : 0)
                .accessibilityLabel("All tasks")
                .accessibilityValue(appState.incompleteTasks.count > 0 ?
                                  "\(appState.incompleteTasks.count) incomplete tasks" :
                                  "No incomplete tasks")
                .accessibilityHint("View and manage all your tasks")

            // Habits Tab
            HabitsView()
                .tabItem {
                    Image(systemName: AppTab.habits.iconName)
                    Text(AppTab.habits.title)
                }
                .tag(AppTab.habits)
                .badge(appState.activeHabits.filter { !$0.isCompletedToday }.count > 0 ?
                       appState.activeHabits.filter { !$0.isCompletedToday }.count : 0)
                .accessibilityLabel("Habits dashboard")
                .accessibilityValue({
                    let incompleteCount = appState.activeHabits.filter { !$0.isCompletedToday }.count
                    return incompleteCount > 0 ?
                        "\(incompleteCount) habits not completed today" :
                        "All habits completed today"
                }())
                .accessibilityHint("Track your daily habits and streaks")

            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: AppTab.settings.iconName)
                    Text(AppTab.settings.title)
                }
                .tag(AppTab.settings)
                .accessibilityLabel("App settings")
                .accessibilityHint("Configure app preferences and sync settings")
        }
        .sheet(coordinator: navigationCoordinator)
        .alert("Error", isPresented: Binding(
            get: { appState.error != nil },
            set: { _ in appState.clearError() }
        )) {
            Button("OK") {
                appState.clearError()
            }

            // Add retry button for recoverable errors
            if let error = appState.error, error.isRecoverable {
                Button("Retry") {
                    appState.clearError()
                    ConcurrentTask {
                        await container?.cloudKitSyncService.forcSync()
                    }
                }
            }
        } message: {
            if let error = appState.error {
                Text(error.localizedDescription)
            }
        }
        .overlay(alignment: .bottom) {
            // Show sync status bar when appropriate
            if appState.syncStatus == .syncing ||
               (appState.syncStatus != .synced && appState.syncStatus != .unknown) {
                SyncStatusView(
                    status: appState.syncStatus,
                    message: appState.syncStatusMessage
                )
                .horizontalSpacingPadding(.spacing4)
                .padding(.bottom) // Above tab bar
            }
        }
        .task {
            await container?.loadInitialData()
        }
        .onChange(of: voiceOverEnabled) { _, enabled in
            // Update app state when VoiceOver status changes
            appState.isVoiceOverActive = enabled
        }
        .onChange(of: dynamicTypeSize) { _,  newSize in
            // Handle dynamic type size changes if needed
            appState.currentDynamicTypeSize = newSize
        }
    }
}

// MARK: - Settings View Placeholder

struct SettingsView: View {
    @Environment(\.diContainer) private var container

    private var appState: AppState {
        container?.appState ?? AppState()
    }

    private var cloudKitService: CloudKitSyncService? {
        container?.cloudKitSyncService
    }

    var body: some View {
        NavigationStack {
            List {
                // Sync Section
                Section("iCloud Sync") {
                    HStack {
                        Image(systemName: appState.isSyncEnabled ? "icloud.fill" : "icloud.slash")
                            .foregroundColor(appState.isSyncEnabled ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                            Text(appState.syncStatusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if appState.syncStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    if appState.isSyncEnabled {
                        Button("Sync Now") {
                            ConcurrentTask {
                                await cloudKitService?.forcSync()
                            }
                        }
                        .disabled(appState.syncStatus == .syncing)
                    }
                }

                Section("App") {
                    HStack {
                        Image(systemName: "bell")
                        Text("Notifications")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "folder")
                        Text("Categories")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About ToDoozies")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(coordinator: container?.navigationCoordinator ?? NavigationCoordinator())
        }
    }
}

// MARK: - Preview Helper
// ModelContext.preview extension is defined in DIContainer.swift

#Preview {
    ContentView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}
