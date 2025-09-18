//
//  ToDooziesApp.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/13/25.
//

import SwiftUI
import SwiftData
import CloudKit
import UserNotifications

@main
struct ToDooziesApp: App {
    @State private var diContainer: DIContainer?
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
            RecurrenceRule.self,
            Category.self,
            Subtask.self,
            Attachment.self,
            Habit.self
        ])

        do {
            // Primary configuration with CloudKit sync
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.dante.ToDoozies"),
                cloudKitDatabase: .private("iCloud.dante.ToDoozies")
            )

            return try ModelContainer(for: schema, configurations: [configuration])

        } catch {
            print("CloudKit: Failed to create CloudKit ModelContainer: \(error)")
            print("CloudKit: This is expected when no iCloud account is configured. Falling back to local storage.")

            // Fallback to local-only storage
            do {
                let localConfiguration = ModelConfiguration(
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    groupContainer: .identifier("group.dante.ToDoozies")
                )

                return try ModelContainer(for: schema, configurations: [localConfiguration])

            } catch {
                print("CloudKit: Failed to create local ModelContainer: \(error)")

                // Last resort - in-memory container
                do {
                    let memoryConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
                    return try ModelContainer(for: schema, configurations: [memoryConfiguration])
                } catch {
                    //fatalError("Could not create any ModelContainer: \(error)")
                    fatalError("ModelContainer creation error: \(error.localizedDescription)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = diContainer {
                    ContentView()
                        .inject(container)
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Loading ToDoozies...")
                            .font(.headline)
                            .padding(.top)
                    }
                }
            }
            .task {
                if diContainer == nil {
                    await MainActor.run {
                        diContainer = DIContainer(modelContext: sharedModelContainer.mainContext)
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
