//
//  ICSEvent.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import Foundation

struct ICSEvent {
    let uid: String
    let title: String
    let description: String?
    let startDate: Date?
    let endDate: Date?
    let isAllDay: Bool
    let priority: Priority?
    let category: String?
    let location: String?
    let url: String?
    let isRecurring: Bool
    let recurrenceRule: String?

    // Metadata for linking back to ToDoozies
    let todooziesTaskId: String?
    let todooziesHabitId: String?

    init(from task: Task) {
        self.uid = "todoozies-task-\(task.id.uuidString)"
        self.title = task.title
        self.description = task.taskDescription
        self.priority = task.priority
        self.category = task.category?.name
        self.location = nil // Tasks don't have location in current model
        self.url = "todoozies://task?id=\(task.id.uuidString)"
        self.isRecurring = false
        self.recurrenceRule = nil
        self.todooziesTaskId = task.id.uuidString
        self.todooziesHabitId = nil

        // Handle date configuration
        if let dueDate = task.dueDate {
            let calendar = Calendar.current

            // Check if task has specific time or should be all-day
            let components = calendar.dateComponents([.hour, .minute], from: dueDate)
            if components.hour == 0 && components.minute == 0 {
                // All-day event
                self.isAllDay = true
                self.startDate = calendar.startOfDay(for: dueDate)
                self.endDate = calendar.date(byAdding: .day, value: 1, to: self.startDate!)
            } else {
                // Timed event (default 1 hour duration)
                self.isAllDay = false
                self.startDate = dueDate
                self.endDate = calendar.date(byAdding: .hour, value: 1, to: dueDate)
            }
        } else {
            // No due date - create all-day event for today
            self.isAllDay = true
            self.startDate = Calendar.current.startOfDay(for: Date())
            self.endDate = Calendar.current.date(byAdding: .day, value: 1, to: self.startDate!)
        }
    }

    init(from habit: Habit, startDate: Date, endDate: Date) {
        self.uid = "todoozies-habit-\(habit.id.uuidString)-\(Int(startDate.timeIntervalSince1970))"
        self.title = habit.baseTask?.title ?? "Habit"
        self.description = habit.baseTask?.taskDescription
        self.priority = habit.baseTask?.priority
        self.category = habit.baseTask?.category?.name
        self.location = nil
        self.url = "todoozies://habit?id=\(habit.id.uuidString)"
        self.isRecurring = true
        self.todooziesTaskId = nil
        self.todooziesHabitId = habit.id.uuidString

        // Habits are typically recurring daily events
        self.isAllDay = true
        self.startDate = startDate
        self.endDate = endDate

        // Generate recurrence rule based on habit frequency
        let targetCompletions = habit.targetCompletionsPerPeriod ?? 1
        switch targetCompletions {
        case 1:
            self.recurrenceRule = "FREQ=DAILY"
        case let count where count > 1 && count <= 7:
            self.recurrenceRule = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU"
        default:
            self.recurrenceRule = "FREQ=DAILY"
        }
    }

    // Custom initializer for flexible event creation
    init(uid: String, title: String, description: String? = nil, startDate: Date?, endDate: Date?, isAllDay: Bool = false, priority: Priority? = nil, category: String? = nil, isRecurring: Bool = false, recurrenceRule: String? = nil) {
        self.uid = uid
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.priority = priority
        self.category = category
        self.location = nil
        self.url = nil
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.todooziesTaskId = nil
        self.todooziesHabitId = nil
    }
}

// MARK: - iCS String Generation

extension ICSEvent {
    var icsString: String {
        var components: [String] = []

        components.append("BEGIN:VEVENT")
        components.append("UID:\(uid)")
        components.append("SUMMARY:\(escapeICSString(title))")

        if let description = description, !description.isEmpty {
            components.append("DESCRIPTION:\(escapeICSString(description))")
        }

        // Add priority if specified
        if let priority = priority {
            let icsPriority = convertPriorityToICS(priority)
            components.append("PRIORITY:\(icsPriority)")
        }

        // Add category if specified
        if let category = category {
            components.append("CATEGORIES:\(escapeICSString(category))")
        }

        // Add dates
        if let startDate = startDate {
            if isAllDay {
                components.append("DTSTART;VALUE=DATE:\(formatDateForICS(startDate, allDay: true))")
                if let endDate = endDate {
                    components.append("DTEND;VALUE=DATE:\(formatDateForICS(endDate, allDay: true))")
                }
            } else {
                components.append("DTSTART:\(formatDateForICS(startDate, allDay: false))")
                if let endDate = endDate {
                    components.append("DTEND:\(formatDateForICS(endDate, allDay: false))")
                }
            }
        }

        // Add recurrence rule if this is a recurring event
        if isRecurring, let recurrenceRule = recurrenceRule {
            components.append("RRULE:\(recurrenceRule)")
        }

        // Add ToDoozies-specific URL
        if let url = url {
            components.append("URL:\(url)")
        }

        // Add timestamps
        let now = Date()
        components.append("DTSTAMP:\(formatDateForICS(now, allDay: false))")
        components.append("CREATED:\(formatDateForICS(now, allDay: false))")
        components.append("LAST-MODIFIED:\(formatDateForICS(now, allDay: false))")

        components.append("END:VEVENT")

        return components.joined(separator: "\r\n")
    }

    private func escapeICSString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    private func formatDateForICS(_ date: Date, allDay: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")

        if allDay {
            formatter.dateFormat = "yyyyMMdd"
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        }

        return formatter.string(from: date)
    }

    private func convertPriorityToICS(_ priority: Priority) -> Int {
        switch priority {
        case .high: return 1
        case .medium: return 5
        case .low: return 9
        }
    }
}

// MARK: - Bulk ICS Generation

struct ICSCalendar {
    let events: [ICSEvent]
    let calendarName: String
    let description: String?

    init(events: [ICSEvent], calendarName: String = "ToDoozies Export", description: String? = nil) {
        self.events = events
        self.calendarName = calendarName
        self.description = description
    }

    var icsString: String {
        var components: [String] = []

        // Calendar header
        components.append("BEGIN:VCALENDAR")
        components.append("VERSION:2.0")
        components.append("PRODID:-//ToDoozies//ToDoozies App//EN")
        components.append("CALSCALE:GREGORIAN")
        components.append("METHOD:PUBLISH")
        components.append("X-WR-CALNAME:\(calendarName)")

        if let description = description {
            components.append("X-WR-CALDESC:\(description)")
        }

        // Add all events
        for event in events {
            components.append(event.icsString)
        }

        // Calendar footer
        components.append("END:VCALENDAR")

        return components.joined(separator: "\r\n") + "\r\n"
    }
}