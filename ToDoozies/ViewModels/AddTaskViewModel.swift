//
//  AddTaskViewModel.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import Foundation
import Observation

@Observable
final class AddTaskViewModel {

    // MARK: - Form Fields
    var title: String = ""
    var taskDescription: String = ""
    var dueDateText: String = ""
    var parsedDueDate: Date?
    var priority: Priority = .medium
    var selectedCategory: Category?
    var isRecurring: Bool = false
    var recurrenceRule: RecurrenceRule?

    // MARK: - Validation State
    var validationErrors: [ValidationError] = []
    var isFormValid: Bool {
        validationErrors.isEmpty && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - UI State
    var isLoading: Bool = false
    var showingRecurrenceSheet: Bool = false
    var showingAttachmentPicker: Bool = false
    var showingCategoryPicker: Bool = false

    // MARK: - Services
    private let taskService: TaskServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let navigationCoordinator: NavigationCoordinator
    private let appState: AppState

    // MARK: - Initialization
    init(
        appState: AppState,
        taskService: TaskServiceProtocol,
        categoryService: CategoryServiceProtocol,
        navigationCoordinator: NavigationCoordinator
    ) {
        self.appState = appState
        self.taskService = taskService
        self.categoryService = categoryService
        self.navigationCoordinator = navigationCoordinator

        // Set default category to first available
        self.selectedCategory = appState.categories.first

        // Start validation
        validateForm()
    }

    // MARK: - Form Actions

    func saveTask() async {
        guard isFormValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let task = createTaskFromForm()
            try await taskService.createTask(task)

            // If creating a habit, also create the habit record
            if isRecurring {
                try await createHabitFromTask(task)
            }

            // Navigate back
            navigationCoordinator.dismissSheet()

        } catch {
            appState.setError(.dataSavingFailed("Failed to create task: \(error.localizedDescription)"))
        }
    }

    func cancel() {
        navigationCoordinator.dismissSheet()
    }

    // MARK: - Validation

    func validateForm() {
        validationErrors.removeAll()

        // Title validation
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            validationErrors.append(.titleRequired)
        } else if trimmedTitle.count > 200 {
            validationErrors.append(.titleTooLong(maxLength: 200))
        }

        // Date validation (if provided)
        if !dueDateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedDueDate == nil {
            validationErrors.append(.invalidDateFormat(input: dueDateText))
        }

        // For non-recurring tasks, don't allow past dates
        if let date = parsedDueDate, !isRecurring && date < Date() {
            validationErrors.append(.pastDateNotAllowed)
        }
    }

    // MARK: - Date Parsing

    func parseDateFromText() {
        let parser = NaturalLanguageDateParser()
        let result = parser.parseDate(from: dueDateText)

        switch result {
        case .success(let date, _):
            parsedDueDate = date
        case .ambiguous(let dates, _):
            // Use first option for now, could show picker later
            parsedDueDate = dates.first
        case .failed:
            parsedDueDate = nil
        }

        validateForm()
    }

    // MARK: - Private Helpers

    private func createTaskFromForm() -> Task {
        let task = Task(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.isEmpty ? nil : taskDescription,
            dueDate: parsedDueDate,
            priority: priority,
            status: .notStarted
        )

        task.category = selectedCategory
        task.isRecurring = isRecurring
        task.recurrenceRule = recurrenceRule

        return task
    }

    private func createHabitFromTask(_ task: Task) async throws {
        let habit = Habit(baseTask: task, targetCompletionsPerPeriod: 30) // Default to 30 days
        try await taskService.createHabit(habit)
    }
}

// MARK: - Validation Error Types

enum ValidationError: LocalizedError, Equatable {
    case titleRequired
    case titleTooLong(maxLength: Int)
    case invalidDateFormat(input: String)
    case pastDateNotAllowed
    case categoryRequired
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .titleRequired:
            return "Task title is required"
        case .titleTooLong(let maxLength):
            return "Title must be \(maxLength) characters or less"
        case .invalidDateFormat(let input):
            return "Could not understand date format: '\(input)'"
        case .pastDateNotAllowed:
            return "Due date cannot be in the past"
        case .categoryRequired:
            return "Please select a category"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Natural Language Date Parser

final class NaturalLanguageDateParser {
    private let calendar = Calendar.current
    private let dataDetector: NSDataDetector

    init() {
        self.dataDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }

    func parseDate(from text: String) -> DateParseResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Handle empty input
        guard !trimmedText.isEmpty else {
            return .failed(reason: "Empty input")
        }

        // Try relative date parsing first
        if let relativeDate = parseRelativeDate(trimmedText) {
            return .success(relativeDate, confidence: 0.9)
        }

        // Try NSDataDetector for formal dates
        if let detectedDate = parseWithDataDetector(text) {
            return .success(detectedDate, confidence: 0.8)
        }

        // Try natural language patterns
        if let naturalDate = parseNaturalLanguage(trimmedText) {
            return .success(naturalDate, confidence: 0.7)
        }

        return .failed(reason: "Could not parse date")
    }

    private func parseRelativeDate(_ text: String) -> Date? {
        let now = Date()

        switch text {
        case "today":
            return calendar.startOfDay(for: now)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        case "next week":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        case "next month":
            return calendar.date(byAdding: .month, value: 1, to: now)
        default:
            break
        }

        // Try "in X days/weeks/months" pattern
        if text.hasPrefix("in ") && (text.contains("day") || text.contains("week") || text.contains("month")) {
            return parseInPattern(text)
        }

        // Try "next [weekday]" pattern
        if text.hasPrefix("next ") {
            return parseNextWeekday(text)
        }

        return nil
    }

    private func parseWithDataDetector(_ text: String) -> Date? {
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = dataDetector.matches(in: text, options: [], range: range)

        return matches.first?.date
    }

    private func parseNaturalLanguage(_ text: String) -> Date? {
        // Parse weekday names
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        for (index, weekday) in weekdays.enumerated() {
            if text.contains(weekday) {
                return nextDate(for: index + 1) // Calendar.weekday is 1-based
            }
        }

        return nil
    }

    private func parseInPattern(_ text: String) -> Date? {
        // Pattern: "in 3 days", "in 2 weeks", etc.
        let components = text.components(separatedBy: " ")
        guard components.count >= 3,
              components[0] == "in",
              let number = Int(components[1]) else {
            return nil
        }

        let unit = components[2]
        let now = Date()

        if unit.hasPrefix("day") {
            return calendar.date(byAdding: .day, value: number, to: now)
        } else if unit.hasPrefix("week") {
            return calendar.date(byAdding: .weekOfYear, value: number, to: now)
        } else if unit.hasPrefix("month") {
            return calendar.date(byAdding: .month, value: number, to: now)
        }

        return nil
    }

    private func parseNextWeekday(_ text: String) -> Date? {
        let weekdayName = String(text.dropFirst(5)) // Remove "next "
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        guard let index = weekdays.firstIndex(of: weekdayName) else {
            return nil
        }

        return nextDate(for: index + 1)
    }

    private func nextDate(for weekday: Int) -> Date? {
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)

        var daysToAdd = weekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7 // Next week
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: today))
    }
}

// MARK: - Date Parse Result

enum DateParseResult {
    case success(Date, confidence: Float)
    case ambiguous([Date], suggestions: [String])
    case failed(reason: String)
}