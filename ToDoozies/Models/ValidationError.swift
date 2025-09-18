//
//  ValidationError.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/16/25.
//

import Foundation

// MARK: - Shared Validation Error

enum ValidationError: LocalizedError, Equatable {
    // Common validation errors
    case emptyTitle
    case titleRequired
    case titleTooLong(maxLength: Int = 100)
    case descriptionTooLong
    case custom(String)

    // Task-specific validation errors
    case invalidDateFormat(input: String)
    case pastDateNotAllowed
    case categoryRequired
    case invalidDueDate
    case invalidRecurrence
    case recurrenceRuleRequired
    case invalidTaskType(allowed: [TaskType])

    // Habit-specific validation errors
    case invalidTargetCompletions

    var errorDescription: String? {
        switch self {
        case .emptyTitle, .titleRequired:
            return "Title is required"
        case .titleTooLong(let maxLength):
            return "Title must be \(maxLength) characters or less"
        case .descriptionTooLong:
            return "Description must be 500 characters or less"
        case .invalidTargetCompletions:
            return "Target completions must be at least 1"
        case .invalidDateFormat(let input):
            return "Could not understand date format: '\(input)'"
        case .pastDateNotAllowed:
            return "Due date cannot be in the past"
        case .categoryRequired:
            return "Please select a category"
        case .invalidDueDate:
            return "Due date is invalid"
        case .invalidRecurrence:
            return "Recurrence rule is invalid"
        case .recurrenceRuleRequired:
            return "Recurrence pattern is required for recurring tasks and habits"
        case .invalidTaskType(let allowed):
            let allowedNames = allowed.map { $0.displayName }.joined(separator: ", ")
            return "Only the following task types are allowed: \(allowedNames)"
        case .custom(let message):
            return message
        }
    }
}