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
final class Task {
    var id: UUID
    var title: String
    var taskDescription: String?
    var dueDate: Date?
    var priority: Priority
    var status: TaskStatus
    var completedDate: Date?
    var createdDate: Date
    var modifiedDate: Date
    var isRecurring: Bool

    @Relationship(deleteRule: .nullify)
    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \Subtask.parentTask)
    var subtasks: [Subtask] = []

    @Relationship(deleteRule: .cascade, inverse: \Attachment.parentTask)
    var attachments: [Attachment] = []

    @Relationship(deleteRule: .nullify)
    var recurrenceRule: RecurrenceRule?

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
        self.isRecurring = false
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
        guard !subtasks.isEmpty else { return 0.0 }
        let completedCount = subtasks.filter { $0.isComplete }.count
        return Double(completedCount) / Double(subtasks.count)
    }

    var isCompleted: Bool {
        status.isCompleted
    }

    func addSubtask(title: String) {
        let subtask = Subtask(title: title, order: subtasks.count, parentTask: self)
        subtasks.append(subtask)
        updateModifiedDate()
    }

    func removeSubtask(_ subtask: Subtask) {
        subtasks.removeAll { $0.id == subtask.id }
        updateModifiedDate()
    }

    func addAttachment(_ attachment: Attachment) {
        attachments.append(attachment)
        attachment.parentTask = self
        updateModifiedDate()
    }

    func removeAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
        updateModifiedDate()
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