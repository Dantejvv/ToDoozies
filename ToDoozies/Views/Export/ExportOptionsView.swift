//
//  ExportOptionsView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var container

    @State private var exportOptions = ICSExportService.ExportOptions()
    @State private var exportType: ExportType = .tasks
    @State private var isExporting = false
    @State private var exportError: Error?
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?

    private let tasks: [Task]
    private let habits: [Habit]
    private let exportService = ICSExportService()

    enum ExportType: String, CaseIterable {
        case tasks = "Tasks Only"
        case habits = "Habits Only"
        case combined = "Tasks & Habits"
    }

    init(tasks: [Task] = [], habits: [Habit] = []) {
        self.tasks = tasks
        self.habits = habits
    }

    var body: some View {
        NavigationStack {
            Form {
                exportTypeSection
                exportRangeSection
                optionsSection
                previewSection
            }
            .navigationTitle("Export Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        performExport()
                    }
                    .disabled(isExporting || filteredItemCount == 0)
                }
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK") {
                    exportError = nil
                }
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - View Sections

    private var exportTypeSection: some View {
        Section("Export Type") {
            Picker("Type", selection: $exportType) {
                ForEach(ExportType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var exportRangeSection: some View {
        Section("Date Range") {
            VStack(alignment: .leading, spacing: .spacing3) {
                HStack {
                    Text("Range:")
                        .foregroundColor(.secondary)

                    Spacer()

                    Menu {
                        Button("All Time") {
                            exportOptions.dateRange = nil
                        }
                        Button("Today") {
                            exportOptions.dateRange = .today
                        }
                        Button("This Week") {
                            exportOptions.dateRange = .thisWeek
                        }
                        Button("This Month") {
                            exportOptions.dateRange = .thisMonth
                        }
                    } label: {
                        Text(dateRangeDisplayText)
                            .foregroundColor(.accentColor)
                    }
                }

                if exportType == .habits || exportType == .combined {
                    Toggle("Include Habits", isOn: $exportOptions.includeHabits)
                }
            }
        }
    }

    private var optionsSection: some View {
        Section("Export Options") {
            HStack {
                Text("Calendar Name:")
                Spacer()
                TextField("Calendar Name", text: $exportOptions.calendarName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 150)
            }

            Toggle("Include Completed Tasks", isOn: $exportOptions.includeCompletedTasks)

            VStack(alignment: .leading, spacing: .spacing2) {
                Text("Event Format:")
                    .foregroundColor(.secondary)

                Picker("Format", selection: $exportOptions.exportFormat) {
                    Text("All-Day Events").tag(ICSExportService.ExportOptions.ExportFormat.allDay)
                    Text("1 Hour Events").tag(ICSExportService.ExportOptions.ExportFormat.timed(duration: 3600))
                    Text("2 Hour Events").tag(ICSExportService.ExportOptions.ExportFormat.timed(duration: 7200))
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var previewSection: some View {
        Section("Export Preview") {
            VStack(alignment: .leading, spacing: .spacing2) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)

                    Text("Items to Export:")
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(filteredItemCount)")
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }

                if filteredItemCount > 0 {
                    VStack(alignment: .leading, spacing: .spacing1) {
                        if exportType == .tasks || exportType == .combined {
                            let taskCount = filteredTasks.count
                            if taskCount > 0 {
                                Text("• \(taskCount) task\(taskCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if (exportType == .habits || exportType == .combined) && exportOptions.includeHabits {
                            let habitCount = habits.count
                            if habitCount > 0 {
                                Text("• \(habitCount) habit\(habitCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("No items match the export criteria")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .spacingPadding(.spacing3)
            .background(Color(.systemGray6))
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
    }

    // MARK: - Computed Properties

    private var dateRangeDisplayText: String {
        guard let dateRange = exportOptions.dateRange else {
            return "All Time"
        }

        switch dateRange {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .custom: return "Custom Range"
        }
    }

    private var filteredTasks: [Task] {
        return tasks.filter { task in
            if !exportOptions.includeCompletedTasks && task.isCompleted {
                return false
            }

            if let dateRange = exportOptions.dateRange {
                guard let dueDate = task.dueDate else { return false }
                return dateRange.dateInterval.contains(dueDate)
            }

            return true
        }
    }

    private var filteredItemCount: Int {
        var count = 0

        if exportType == .tasks || exportType == .combined {
            count += filteredTasks.count
        }

        if (exportType == .habits || exportType == .combined) && exportOptions.includeHabits {
            count += habits.count
        }

        return count
    }

    // MARK: - Actions

    private func performExport() {
        isExporting = true

        ConcurrentTask {
            do {
                let url = try await exportData()
                await MainActor.run {
                    exportedFileURL = url
                    showingShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    isExporting = false
                }
            }
        }
    }

    private func exportData() async throws -> URL {
        switch exportType {
        case .tasks:
            return try exportService.exportTasks(filteredTasks, options: exportOptions)

        case .habits:
            return try exportService.exportHabits(habits, options: exportOptions)

        case .combined:
            return try exportService.exportCombined(tasks: filteredTasks, habits: habits, options: exportOptions)
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo
        ]
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    @MainActor
    func createPreview() -> some View {
        let sampleTasks = [
            Task(title: "Review Code", dueDate: Date(), priority: .high),
            Task(title: "Update Documentation", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), priority: .medium),
            Task(title: "Team Meeting", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), priority: .low)
        ]

        let sampleHabits = [
            Habit(baseTask: Task(title: "Daily Exercise", priority: .high)),
            Habit(baseTask: Task(title: "Read 30 Minutes", priority: .medium))
        ]

        return ExportOptionsView(tasks: sampleTasks, habits: sampleHabits)
    }

    return createPreview()
}