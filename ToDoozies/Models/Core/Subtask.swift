//
//  Subtask.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Subtask: @unchecked Sendable {
    var id: UUID = UUID()
    var title: String = ""
    var isComplete: Bool = false
    var order: Int = 0
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()

    @Relationship
    var parentTask: Task?

    init(
        title: String,
        order: Int = 0,
        parentTask: Task? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.isComplete = false
        self.order = order
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.parentTask = parentTask
    }

    func toggle() {
        isComplete.toggle()
        modifiedDate = Date()
    }

    func markCompleted() {
        isComplete = true
        modifiedDate = Date()
    }

    func markIncomplete() {
        isComplete = false
        modifiedDate = Date()
    }

    func updateModifiedDate() {
        modifiedDate = Date()
    }
}

// MARK: - Subtask Extensions
extension Subtask: Comparable {
    static func < (lhs: Subtask, rhs: Subtask) -> Bool {
        if lhs.isComplete != rhs.isComplete {
            return !lhs.isComplete && rhs.isComplete
        }
        return lhs.order < rhs.order
    }
}