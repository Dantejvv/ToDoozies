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

    @State private var offlineToast: ToastItem?

    // Theme management
    @AppStorage("selectedColorScheme") private var selectedColorScheme: String = "system"

    private var navigationCoordinator: NavigationCoordinator {
        container?.navigationCoordinator ?? NavigationCoordinator()
    }

    private var appState: AppState {
        container?.appState ?? AppState()
    }

    private var preferredColorScheme: ColorScheme? {
        switch selectedColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
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

            // Calendar Tab
            CalendarTabView()
                .tabItem {
                    Image(systemName: AppTab.calendar.iconName)
                    Text(AppTab.calendar.title)
                }
                .tag(AppTab.calendar)
                .accessibilityLabel("Calendar view")
                .accessibilityHint("View tasks and habits in calendar format with heatmaps and streak chains")

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
        .overlay(alignment: .top) {
            // Offline toast notification (shows at top)
            if appState.showOfflineToast && appState.offlineMode == .offline {
                OfflineToast(
                    mode: appState.offlineMode,
                    isVisible: appState.showOfflineToast,
                    onDismiss: {
                        appState.dismissOfflineToast()
                    }
                )
                .padding(.top, 8) // Below status bar
                .zIndex(1000) // Ensure it appears above all other content
            }
        }
        .overlay(alignment: .bottom) {
            // Enhanced sync status with offline indicator
            if appState.syncStatus == .syncing || appState.offlineMode != .online {
                SyncStatusView(
                    status: appState.syncStatus,
                    message: appState.syncStatusMessage,
                    offlineMode: appState.offlineMode,
                    pendingChanges: appState.pendingChangesCount,
                    connectionType: container?.networkMonitor.connectionDescription,
                    onRetry: {
                        ConcurrentTask {
                            await container?.cloudKitSyncService.forcSync()
                        }
                    }
                )
                .horizontalSpacingPadding(.spacing4)
                .padding(.bottom) // Above tab bar
            }
        }
        .toast($offlineToast)
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
        .onChange(of: appState.offlineMode) { oldMode, newMode in
            // Show toast when transitioning to/from offline
            if oldMode != newMode {
                switch newMode {
                case .offline:
                    offlineToast = ToastItem(mode: .offline, duration: 5.0)
                case .online where oldMode == .offline || oldMode == .reconnecting:
                    offlineToast = ToastItem(mode: .online, duration: 3.0)
                default:
                    break
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

// MARK: - Settings View Placeholder

struct SettingsView: View {
    @Environment(\.diContainer) private var container
    @Environment(\.colorScheme) private var currentColorScheme

    // Theme preferences
    @AppStorage("selectedColorScheme") private var selectedColorScheme: String = "system"

    // Notification preferences
    @AppStorage("showCompletionCelebrations") private var showCompletionCelebrations = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false

    // Sync preferences
    @AppStorage("autoSyncOnLaunch") private var autoSyncOnLaunch = true

    // Accessibility preferences
    @AppStorage("announceCompletions") private var announceCompletions = true
    @AppStorage("reduceAnimations") private var reduceAnimations = false

    // Services
    @State private var notificationService = NotificationPermissionService()
    @State private var themeManager = ThemeManager()
    @State private var showingExportOptions = false

    private var appState: AppState {
        container?.appState ?? AppState()
    }

    private var cloudKitService: CloudKitSyncService? {
        container?.cloudKitSyncService
    }

    var body: some View {
        NavigationStack {
            Form {
                // App Appearance Section
                appearanceSection

                // iCloud Sync Section
                iCloudSyncSection

                // Notification Settings Section
                notificationSection

                // Data Management Section
                dataManagementSection

                // Accessibility Section
                accessibilitySection

                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                await notificationService.checkAuthorizationStatus()
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(
                    tasks: appState.tasks,
                    habits: appState.habits
                )
            }
        }
    }

    // MARK: - View Sections

    private var appearanceSection: some View {
        Section("Appearance") {
            HStack {
                Image(systemName: AppTheme(rawValue: selectedColorScheme)?.systemImage ?? "gearshape")
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Theme")
                    Text(themeManager.themeDescription(for: EnvironmentValues()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Picker("Theme", selection: $selectedColorScheme) {
                    ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            .accessibilityLabel("App theme")
            .accessibilityValue(AppTheme(rawValue: selectedColorScheme)?.displayName ?? "System")
            .accessibilityHint("Changes the app's color scheme")
        }
    }

    private var iCloudSyncSection: some View {
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
            .accessibilityLabel("iCloud sync status")
            .accessibilityValue(appState.syncStatusMessage)

            if appState.isSyncEnabled {
                Button("Sync Now") {
                    ConcurrentTask {
                        await cloudKitService?.forcSync()
                    }
                }
                .disabled(appState.syncStatus == .syncing)
                .accessibilityLabel("Manually sync data")
            }

            Toggle("Auto-sync on app launch", isOn: $autoSyncOnLaunch)
                .accessibilityLabel("Automatically sync when app starts")
        }
    }

    private var notificationSection: some View {
        Section("Notifications") {
            HStack {
                Image(systemName: notificationService.statusSystemImage)
                    .foregroundColor(notificationService.statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notification Permission")
                    Text(notificationService.statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if notificationService.canRequestPermission {
                    Button("Enable") {
                        ConcurrentTask {
                            await notificationService.requestPermission()
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(notificationService.isLoading)
                } else if notificationService.needsSettingsAccess {
                    Button("Settings") {
                        notificationService.openAppSettings()
                    }
                    .buttonStyle(.borderless)
                }
            }
            .accessibilityLabel("Notification permission")
            .accessibilityValue(notificationService.statusDisplayName)

            if notificationService.authorizationStatus == .authorized {
                Toggle("Completion celebrations", isOn: $showCompletionCelebrations)
                    .accessibilityLabel("Show celebrations when completing tasks")

                Toggle("Quiet hours", isOn: $quietHoursEnabled)
                    .accessibilityLabel("Enable quiet hours for notifications")
            }
        }
    }

    private var dataManagementSection: some View {
        Section("Data Management") {
            Button {
                showingExportOptions = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Calendar")
                            .foregroundColor(.primary)
                        Text("Export tasks and habits as ICS file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Export data")
            .accessibilityHint("Export tasks and habits as calendar file")

            HStack {
                Image(systemName: "internaldrive")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("App Data")
                    Text("\(appState.tasks.count) tasks, \(appState.habits.count) habits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .accessibilityLabel("App data summary")
            .accessibilityValue("\(appState.tasks.count) tasks, \(appState.habits.count) habits")

            if appState.offlineMode != .online {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline Changes")
                        Text("\(appState.pendingChangesCount) pending changes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .accessibilityLabel("Offline status")
                .accessibilityValue("\(appState.pendingChangesCount) pending changes")
            }
        }
    }

    private var accessibilitySection: some View {
        Section("Accessibility") {
            Toggle("Announce completions", isOn: $announceCompletions)
                .accessibilityLabel("Announce task completions to VoiceOver")
                .onChange(of: announceCompletions) { _, newValue in
                    appState.shouldAnnounceCompletions = newValue
                }

            Toggle("Reduce animations", isOn: $reduceAnimations)
                .accessibilityLabel("Reduce motion and animations")

            HStack {
                Image(systemName: "textformat.size")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Text Size")
                    Text(appState.currentDynamicTypeSize.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("System")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Text size setting")
            .accessibilityValue("Controlled by system settings")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ToDoozies")
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .accessibilityLabel("App information")
            .accessibilityValue("ToDoozies version \(appVersion)")

            HStack {
                Image(systemName: "hand.raised")
                    .foregroundColor(.secondary)

                Text("Privacy Policy")

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Privacy policy")
            .accessibilityHint("Opens privacy policy")

            HStack {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)

                Text("Support")

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Support and help")
            .accessibilityHint("Get help and support")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Extensions

extension DynamicTypeSize {
    var description: String {
        switch self {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "Extra Extra Large"
        case .xxxLarge: return "Extra Extra Extra Large"
        case .accessibility1: return "Accessibility 1"
        case .accessibility2: return "Accessibility 2"
        case .accessibility3: return "Accessibility 3"
        case .accessibility4: return "Accessibility 4"
        case .accessibility5: return "Accessibility 5"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Preview Helper
// ModelContext.preview extension is defined in DIContainer.swift

#Preview {
    ContentView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}
