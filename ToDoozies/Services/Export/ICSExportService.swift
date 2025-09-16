//
//  ICSExportService.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import Foundation
import UniformTypeIdentifiers

@MainActor
final class ICSExportService: ObservableObject {
    private let fileManager = FileManager.default

    // MARK: - Export Options

    struct ExportOptions {
        var includeCompletedTasks: Bool = false
        var dateRange: DateRange?
        var categories: Set<Category> = []
        var exportFormat: ExportFormat = .allDay
        var calendarName: String = "ToDoozies Export"
        var includeHabits: Bool = true
        var habitDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days in seconds

        enum ExportFormat: Hashable {
            case allDay
            case timed(duration: TimeInterval)
        }

        enum DateRange {
            case today
            case thisWeek
            case thisMonth
            case custom(start: Date, end: Date)

            var dateInterval: DateInterval {
                let calendar = Calendar.current
                let now = Date()

                switch self {
                case .today:
                    let start = calendar.startOfDay(for: now)
                    let end = calendar.date(byAdding: .day, value: 1, to: start)!
                    return DateInterval(start: start, end: end)

                case .thisWeek:
                    let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                    let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
                    return DateInterval(start: start, end: end)

                case .thisMonth:
                    let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
                    let end = calendar.date(byAdding: .month, value: 1, to: start)!
                    return DateInterval(start: start, end: end)

                case .custom(let start, let end):
                    return DateInterval(start: start, end: end)
                }
            }
        }
    }

    // MARK: - Export Methods

    func exportTasks(_ tasks: [Task], options: ExportOptions = ExportOptions()) throws -> URL {
        let filteredTasks = filterTasks(tasks, with: options)
        let events = filteredTasks.map { createICSEvent(from: $0, options: options) }

        let calendar = ICSCalendar(
            events: events,
            calendarName: options.calendarName,
            description: generateCalendarDescription(for: filteredTasks, options: options)
        )

        return try writeICSFile(calendar, filename: generateFilename(for: "tasks", options: options))
    }

    func exportHabits(_ habits: [Habit], options: ExportOptions = ExportOptions()) throws -> URL {
        guard options.includeHabits else {
            throw ExportError.habitsNotIncluded
        }

        var events: [ICSEvent] = []

        for habit in habits {
            let habitEvents = createICSEvents(from: habit, options: options)
            events.append(contentsOf: habitEvents)
        }

        let calendar = ICSCalendar(
            events: events,
            calendarName: "\(options.calendarName) - Habits",
            description: generateCalendarDescription(for: habits, options: options)
        )

        return try writeICSFile(calendar, filename: generateFilename(for: "habits", options: options))
    }

    func exportCombined(tasks: [Task], habits: [Habit], options: ExportOptions = ExportOptions()) throws -> URL {
        let filteredTasks = filterTasks(tasks, with: options)
        var events: [ICSEvent] = []

        // Add task events
        events.append(contentsOf: filteredTasks.map { createICSEvent(from: $0, options: options) })

        // Add habit events if included
        if options.includeHabits {
            for habit in habits {
                let habitEvents = createICSEvents(from: habit, options: options)
                events.append(contentsOf: habitEvents)
            }
        }

        let calendar = ICSCalendar(
            events: events,
            calendarName: options.calendarName,
            description: generateCalendarDescription(for: filteredTasks, habits: habits, options: options)
        )

        return try writeICSFile(calendar, filename: generateFilename(for: "combined", options: options))
    }

    // MARK: - Private Helper Methods

    private func filterTasks(_ tasks: [Task], with options: ExportOptions) -> [Task] {
        return tasks.filter { task in
            // Filter by completion status
            if !options.includeCompletedTasks && task.isCompleted {
                return false
            }

            // Filter by date range
            if let dateRange = options.dateRange {
                guard let dueDate = task.dueDate else { return false }
                if !dateRange.dateInterval.contains(dueDate) {
                    return false
                }
            }

            // Filter by categories
            if !options.categories.isEmpty {
                guard let taskCategory = task.category,
                      options.categories.contains(taskCategory) else {
                    return false
                }
            }

            return true
        }
    }

    private func createICSEvent(from task: Task, options: ExportOptions) -> ICSEvent {
        var event = ICSEvent(from: task)

        // Apply export format options
        switch options.exportFormat {
        case .allDay:
            // ICSEvent(from: Task) already handles this correctly
            break

        case .timed(let duration):
            if let startDate = event.startDate, !event.isAllDay {
                // Already has specific time, just adjust duration
                let newEvent = ICSEvent(
                    uid: event.uid,
                    title: event.title,
                    description: event.description,
                    startDate: startDate,
                    endDate: startDate.addingTimeInterval(duration),
                    isAllDay: false,
                    priority: event.priority,
                    category: event.category
                )
                event = newEvent
            }
        }

        return event
    }

    private func createICSEvents(from habit: Habit, options: ExportOptions) -> [ICSEvent] {
        let calendar = Calendar.current
        let now = Date()

        // Create recurring event for the habit
        let startDate = calendar.startOfDay(for: now)
        let habitEndDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        let event = ICSEvent(from: habit, startDate: startDate, endDate: habitEndDate)
        return [event]
    }

    private func writeICSFile(_ calendar: ICSCalendar, filename: String) throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        let icsData = calendar.icsString.data(using: .utf8)!
        try icsData.write(to: fileURL)

        return fileURL
    }

    private func generateFilename(for type: String, options: ExportOptions) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let sanitizedCalendarName = options.calendarName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")

        return "\(sanitizedCalendarName)_\(type)_\(dateString).ics"
    }

    private func generateCalendarDescription(for tasks: [Task], options: ExportOptions) -> String {
        let taskCount = tasks.count
        let completedCount = tasks.filter { $0.isCompleted }.count

        return "Exported from ToDoozies: \(taskCount) tasks (\(completedCount) completed)"
    }

    private func generateCalendarDescription(for habits: [Habit], options: ExportOptions) -> String {
        let habitCount = habits.count

        return "Exported from ToDoozies: \(habitCount) habits"
    }

    private func generateCalendarDescription(for tasks: [Task], habits: [Habit], options: ExportOptions) -> String {
        let taskCount = tasks.count
        let habitCount = habits.count

        return "Exported from ToDoozies: \(taskCount) tasks, \(habitCount) habits"
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case habitsNotIncluded
    case noTasksToExport
    case fileWriteFailed
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .habitsNotIncluded:
            return "Habits are not included in export options"
        case .noTasksToExport:
            return "No tasks match the export criteria"
        case .fileWriteFailed:
            return "Failed to write export file"
        case .invalidDateRange:
            return "Invalid date range specified"
        }
    }
}

// MARK: - UTType Extension

extension UTType {
    static let ics = UTType(filenameExtension: "ics") ?? UTType.data
}