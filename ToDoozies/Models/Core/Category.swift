//
//  Category.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Category {
    var id: UUID
    var name: String
    var color: String
    var icon: String
    var order: Int
    var createdDate: Date
    var modifiedDate: Date

    @Relationship(deleteRule: .nullify, inverse: \Task.category)
    var tasks: [Task] = []

    init(
        name: String,
        color: String = "#007AFF",
        icon: String = "list.bullet",
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.order = order
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    func updateModifiedDate() {
        modifiedDate = Date()
    }

    var taskCount: Int {
        tasks.count
    }

    var completedTaskCount: Int {
        tasks.filter { $0.status.isCompleted }.count
    }

    var completionPercentage: Double {
        guard taskCount > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(taskCount)
    }
}

// MARK: - Predefined Categories
extension Category {
    static var defaultCategories: [Category] {
        [
            Category(name: "Personal", color: "#007AFF", icon: "person.fill", order: 1),
            Category(name: "Work", color: "#FF9500", icon: "briefcase.fill", order: 2),
            Category(name: "Health", color: "#34C759", icon: "heart.fill", order: 3),
            Category(name: "Learning", color: "#5856D6", icon: "book.fill", order: 4),
            Category(name: "Home", color: "#FF2D92", icon: "house.fill", order: 5)
        ]
    }
}