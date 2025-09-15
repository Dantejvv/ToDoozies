//
//  ToDooziesApp.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/13/25.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct ToDooziesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Task.self,
            RecurrenceRule.self,
            Category.self,
            Subtask.self,
            Attachment.self,
            Habit.self,
        ])

        // Configure shared container URL for app group
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dante.ToDoozies")
        let databaseURL = appGroupURL?.appendingPathComponent("ToDoozies.sqlite") ?? URL.documentsDirectory.appendingPathComponent("ToDoozies.sqlite")

        let modelConfiguration = ModelConfiguration(
            url: databaseURL,
            cloudKitDatabase: .private("iCloud.dante.ToDoozies")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
