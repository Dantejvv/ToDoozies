//
//  ContentView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(tasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task)
                    } label: {
                        TaskRowView(task: task)
                    }
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addTask) {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a task")
                .foregroundStyle(.secondary)
        }
    }

    private func addTask() {
        withAnimation {
            let newTask = Task(title: "New Task")
            modelContext.insert(newTask)
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }
}

// MARK: - Temporary Views (to be moved to separate files)
struct TaskRowView: View {
    let task: Task

    var body: some View {
        HStack {
            Button(action: { task.markCompleted() }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)

                if let description = task.taskDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            if task.priority != .medium {
                Text(task.priority.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(priorityColor(task.priority))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct TaskDetailView: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.title)
                .font(.largeTitle)
                .bold()

            if let description = task.taskDescription {
                Text(description)
                    .font(.body)
            }

            if let dueDate = task.dueDate {
                HStack {
                    Text("Due:")
                        .font(.headline)
                    Text(dueDate, style: .date)
                        .foregroundColor(task.isOverdue ? .red : .primary)
                }
            }

            HStack {
                Text("Priority:")
                    .font(.headline)
                Text(task.priority.displayName)
                    .foregroundColor(priorityColor(task.priority))
            }

            HStack {
                Text("Status:")
                    .font(.headline)
                Text(task.status.displayName)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
