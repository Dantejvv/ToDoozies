//
//  Task.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Task: @unchecked Sendable {
    var id: UUID = UUID()
    var title: String = ""
    var taskDescription: String?
    var dueDate: Date?
    var priority: Priority = Priority.medium
    var status: TaskStatus = TaskStatus.notStarted
    var completedDate: Date?
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()
    var taskType: TaskType = TaskType.oneTime

    @Relationship(deleteRule: .nullify, inverse: \Category.tasks)
    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \Subtask.parentTask)
    var subtasks: [Subtask]?

    @Relationship(deleteRule: .cascade, inverse: \Attachment.parentTask)
    var attachments: [Attachment]?

    @Relationship(deleteRule: .nullify, inverse: \RecurrenceRule.task)
    var recurrenceRule: RecurrenceRule?

    @Relationship(deleteRule: .cascade, inverse: \Habit.baseTask)
    var habit: Habit?

    init(
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        status: TaskStatus = .notStarted
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.completedDate = nil
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.taskType = .oneTime
        self.subtasks = nil
        self.attachments = nil
    }

    func markCompleted() {
        status = .complete
        completedDate = Date()
        modifiedDate = Date()
    }

    func markIncomplete() {
        status = .notStarted
        completedDate = nil
        modifiedDate = Date()
    }

    func updateModifiedDate() {
        modifiedDate = Date()
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, !status.isCompleted else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    var subtaskProgress: Double {
        guard let subtasks = subtasks, !subtasks.isEmpty else { return 0.0 }
        let completedCount = subtasks.filter { $0.isComplete }.count
        return Double(completedCount) / Double(subtasks.count)
    }

    var isCompleted: Bool {
        status.isCompleted
    }

    // MARK: - TaskType Convenience Properties

    var isRecurring: Bool {
        taskType == .recurring || taskType == .habit
    }

    var isHabit: Bool {
        taskType == .habit
    }

    var isOneTime: Bool {
        taskType == .oneTime
    }

    func addSubtask(title: String) {
        if subtasks == nil {
            subtasks = []
        }
        let currentCount = subtasks?.count ?? 0
        let subtask = Subtask(title: title, order: currentCount, parentTask: self)
        subtasks?.append(subtask)
        updateModifiedDate()
    }

    func removeSubtask(_ subtask: Subtask) {
        subtasks?.removeAll { $0.id == subtask.id }
        updateModifiedDate()
    }

    func addAttachment(_ attachment: Attachment) {
        if attachments == nil {
            attachments = []
        }
        attachments?.append(attachment)
        attachment.parentTask = self
        updateModifiedDate()
    }

    func removeAttachment(_ attachment: Attachment) {
        attachments?.removeAll { $0.id == attachment.id }
        updateModifiedDate()
    }
}

// MARK: - Hashable Conformance

extension Task: Hashable {
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Priority Enum
enum Priority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - TaskStatus Enum
enum TaskStatus: String, CaseIterable, Codable {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case complete = "complete"

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .complete: return "Complete"
        }
    }

    var isCompleted: Bool {
        self == .complete
    }
}

// MARK: - TaskType Enum
enum TaskType: String, CaseIterable, Codable {
    case oneTime = "oneTime"
    case recurring = "recurring"
    case habit = "habit"

    var displayName: String {
        switch self {
        case .oneTime: return "One-Time Task"
        case .recurring: return "Recurring Task"
        case .habit: return "Habit"
        }
    }

    var systemImage: String {
        switch self {
        case .oneTime: return "checkmark.circle"
        case .recurring: return "repeat.circle"
        case .habit: return "flame.circle"
        }
    }

    var description: String {
        switch self {
        case .oneTime: return "Single occurrence with due date"
        case .recurring: return "Repeating task instances with schedule"
        case .habit: return "Streak-building activity with consistency focus"
        }
    }

    var requiresRecurrence: Bool {
        switch self {
        case .oneTime: return false
        case .recurring, .habit: return true
        }
    }

    var supportsStreakTracking: Bool {
        switch self {
        case .oneTime, .recurring: return false
        case .habit: return true
        }
    }
}

// MARK: - Preview Support

extension Task {
    static var preview: Task {
        let task = Task(
            title: "Sample Task",
            description: "This is a sample task for preview purposes",
            dueDate: Date().addingTimeInterval(86400), // Tomorrow
            priority: .medium,
            status: .notStarted
        )
        return task
    }
}