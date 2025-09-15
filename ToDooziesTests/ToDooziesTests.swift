//
//  ToDooziesTests.swift
//  ToDooziesTests
//
//  Created by Dante Vercelli on 9/13/25.
//

import Testing
import SwiftData
import Foundation
@testable import ToDoozies

// MARK: - Test Data Factories

struct TaskFactory {
    static func create(
        title: String = "Test Task",
        description: String? = "Test Description",
        dueDate: Date? = nil,
        priority: Priority = .medium,
        status: TaskStatus = .notStarted,
        isRecurring: Bool = false
    ) -> Task {
        let task = Task(
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority,
            status: status
        )
        task.isRecurring = isRecurring
        return task
    }

    static func createOverdue() -> Task {
        return create(
            title: "Overdue Task",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            priority: .high
        )
    }

    static func createDueToday() -> Task {
        return create(
            title: "Due Today",
            dueDate: Date(),
            priority: .medium
        )
    }

    static func createDueTomorrow() -> Task {
        return create(
            title: "Due Tomorrow",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            priority: .low
        )
    }

    static func createCompleted() -> Task {
        let task = create(title: "Completed Task")
        task.markCompleted()
        return task
    }

    static func createWithSubtasks(subtaskCount: Int = 3) -> Task {
        let task = create(title: "Task with Subtasks")
        for i in 1...subtaskCount {
            task.addSubtask(title: "Subtask \(i)")
        }
        return task
    }
}

struct CategoryFactory {
    static func create(
        name: String = "Test Category",
        color: String = "#007AFF",
        icon: String = "list.bullet",
        order: Int = 0
    ) -> ToDoozies.Category {
        return ToDoozies.Category(name: name, color: color, icon: icon, order: order)
    }

    static func createPersonal() -> ToDoozies.Category {
        return create(name: "Personal", color: "#007AFF", icon: "person.fill", order: 1)
    }

    static func createWork() -> ToDoozies.Category {
        return create(name: "Work", color: "#FF9500", icon: "briefcase.fill", order: 2)
    }

    static func createHealth() -> ToDoozies.Category {
        return create(name: "Health", color: "#34C759", icon: "heart.fill", order: 3)
    }

    static func createDefaultCategories() -> [ToDoozies.Category] {
        return [
            createPersonal(),
            createWork(),
            createHealth(),
            create(name: "Learning", color: "#5856D6", icon: "book.fill", order: 4),
            create(name: "Home", color: "#FF2D92", icon: "house.fill", order: 5)
        ]
    }
}

struct RecurrenceRuleFactory {
    static func create(
        frequency: RecurrenceFrequency = .daily,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        endDate: Date? = nil
    ) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            endDate: endDate
        )
    }

    static func createDaily() -> RecurrenceRule {
        return create(frequency: .daily, interval: 1)
    }

    static func createEveryOtherDay() -> RecurrenceRule {
        return create(frequency: .daily, interval: 2)
    }

    static func createWeekdays() -> RecurrenceRule {
        return create(frequency: .weekly, daysOfWeek: [2, 3, 4, 5, 6]) // Mon-Fri
    }

    static func createWeekends() -> RecurrenceRule {
        return create(frequency: .weekly, daysOfWeek: [1, 7]) // Sun, Sat
    }

    static func createWeekly() -> RecurrenceRule {
        return create(frequency: .weekly, interval: 1)
    }

    static func createBiweekly() -> RecurrenceRule {
        return create(frequency: .weekly, interval: 2)
    }

    static func createMonthly() -> RecurrenceRule {
        return create(frequency: .monthly, interval: 1, dayOfMonth: 15)
    }

    static func createFirstOfMonth() -> RecurrenceRule {
        return create(frequency: .monthly, interval: 1, dayOfMonth: 1)
    }

    static func createWithEndDate(daysFromNow: Int) -> RecurrenceRule {
        let endDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())
        return create(frequency: .daily, endDate: endDate)
    }
}

struct SubtaskFactory {
    static func create(
        title: String = "Test Subtask",
        order: Int = 0,
        isComplete: Bool = false,
        parentTask: Task? = nil
    ) -> Subtask {
        let subtask = Subtask(title: title, order: order, parentTask: parentTask)
        if isComplete {
            subtask.markCompleted()
        }
        return subtask
    }

    static func createMultiple(count: Int, for task: Task) -> [Subtask] {
        var subtasks: [Subtask] = []
        for i in 0..<count {
            let subtask = create(
                title: "Subtask \(i + 1)",
                order: i,
                parentTask: task
            )
            subtasks.append(subtask)
        }
        return subtasks
    }

    static func createMixed(totalCount: Int, completedCount: Int, for task: Task) -> [Subtask] {
        var subtasks: [Subtask] = []

        // Create completed subtasks
        for i in 0..<completedCount {
            let subtask = create(
                title: "Completed Subtask \(i + 1)",
                order: i,
                isComplete: true,
                parentTask: task
            )
            subtasks.append(subtask)
        }

        // Create incomplete subtasks
        for i in completedCount..<totalCount {
            let subtask = create(
                title: "Incomplete Subtask \(i + 1)",
                order: i,
                isComplete: false,
                parentTask: task
            )
            subtasks.append(subtask)
        }

        return subtasks
    }
}

struct AttachmentFactory {
    static func create(
        fileName: String = "test-file.txt",
        fileExtension: String = "txt",
        mimeType: String = "text/plain",
        fileSize: Int64 = 1024,
        localURL: String? = "/tmp/test-file.txt",
        parentTask: Task? = nil
    ) -> Attachment {
        return Attachment(
            fileName: fileName,
            fileExtension: fileExtension,
            mimeType: mimeType,
            fileSize: fileSize,
            localURL: localURL,
            parentTask: parentTask
        )
    }

    static func createImage() -> Attachment {
        return create(
            fileName: "photo.jpg",
            fileExtension: "jpg",
            mimeType: "image/jpeg",
            fileSize: 2048576, // 2MB
            localURL: "/tmp/photo.jpg"
        )
    }

    static func createDocument() -> Attachment {
        return create(
            fileName: "document.pdf",
            fileExtension: "pdf",
            mimeType: "application/pdf",
            fileSize: 512000, // 500KB
            localURL: "/tmp/document.pdf"
        )
    }

    static func createAudio() -> Attachment {
        return create(
            fileName: "recording.m4a",
            fileExtension: "m4a",
            mimeType: "audio/mp4",
            fileSize: 1024000, // 1MB
            localURL: "/tmp/recording.m4a"
        )
    }

    static func createVideo() -> Attachment {
        return create(
            fileName: "video.mp4",
            fileExtension: "mp4",
            mimeType: "video/mp4",
            fileSize: 10485760, // 10MB
            localURL: "/tmp/video.mp4"
        )
    }

    static func createMultiple(count: Int, for task: Task) -> [Attachment] {
        var attachments: [Attachment] = []
        for i in 0..<count {
            let attachment = create(
                fileName: "file-\(i + 1).txt",
                parentTask: task
            )
            attachments.append(attachment)
        }
        return attachments
    }
}

struct HabitFactory {
    static func create(
        baseTask: Task? = nil,
        targetCompletionsPerPeriod: Int? = nil,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        totalCompletions: Int = 0,
        completionDates: [Date] = [],
        protectionDaysUsed: Int = 0
    ) -> Habit {
        let task = baseTask ?? TaskFactory.create(title: "Test Habit", isRecurring: true)
        let habit = Habit(baseTask: task, targetCompletionsPerPeriod: targetCompletionsPerPeriod)

        // Set test values
        habit.currentStreak = currentStreak
        habit.bestStreak = bestStreak
        habit.totalCompletions = totalCompletions
        habit.completionDates = completionDates
        habit.protectionDaysUsed = protectionDaysUsed

        return habit
    }

    static func createWithCurrentStreak(days: Int) -> Habit {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var completionDates: [Date] = []

        // Create consecutive completion dates ending today
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                completionDates.append(date)
            }
        }

        let task = TaskFactory.create(title: "\(days)-Day Streak Habit", isRecurring: true)
        return create(
            baseTask: task,
            currentStreak: days,
            bestStreak: days,
            totalCompletions: days,
            completionDates: completionDates.sorted()
        )
    }

    static func createWithBrokenStreak(currentStreak: Int, bestStreak: Int) -> Habit {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var completionDates: [Date] = []

        // Create current streak
        for i in 0..<currentStreak {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                completionDates.append(date)
            }
        }

        // Add gap (missed day) - intentionally skip this day to break the streak

        // Add previous streak to reach best streak total
        let previousStreakDays = bestStreak - currentStreak
        for i in 0..<previousStreakDays {
            if let date = calendar.date(byAdding: .day, value: -(currentStreak + 2 + i), to: today) {
                completionDates.append(date)
            }
        }

        let task = TaskFactory.create(title: "Broken Streak Habit", isRecurring: true)
        return create(
            baseTask: task,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalCompletions: completionDates.count,
            completionDates: completionDates.sorted()
        )
    }

    static func createDailyMeditation() -> Habit {
        let task = TaskFactory.create(title: "Daily Meditation", description: "10 minutes of mindfulness", isRecurring: true)
        task.recurrenceRule = RecurrenceRuleFactory.createDaily()
        return create(baseTask: task, targetCompletionsPerPeriod: 30) // 30 days per month
    }

    static func createWeekdayWorkout() -> Habit {
        let task = TaskFactory.create(title: "Weekday Workout", description: "Exercise routine", isRecurring: true)
        task.recurrenceRule = RecurrenceRuleFactory.createWeekdays()
        return create(baseTask: task, targetCompletionsPerPeriod: 22) // ~22 weekdays per month
    }

    static func createWithProtectionDays(used: Int) -> Habit {
        let habit = createDailyMeditation()
        habit.protectionDaysUsed = used
        habit.lastProtectionDate = Date()
        return habit
    }
}

// MARK: - Test Helper Functions

struct TestHelpers {
    @MainActor
    static func createIsolatedModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            RecurrenceRule.self,
            Category.self,
            Subtask.self,
            Attachment.self,
            Habit.self
        ])

        // Use unique identifier for true test isolation
        let configuration = ModelConfiguration(
            "TestContainer-\(UUID())",
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func withTestContext<T>(
        _ test: @escaping (ModelContext) async throws -> T
    ) async throws -> T {
        let container = try createIsolatedModelContainer()
        let context = ModelContext(container)

        // Ensure clean state for testing
        context.autosaveEnabled = false

        return try await test(context)
    }

    // Legacy method for backward compatibility
    @MainActor
    static func createInMemoryModelContainer() throws -> ModelContainer {
        return try createIsolatedModelContainer()
    }

    static func createTestDate(daysFromNow: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }

    static func createTestDatetime(daysFromNow: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let baseDate = calendar.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate) ?? baseDate
    }

    static func areDatesInSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    static func daysBetween(_ date1: Date, _ date2: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day ?? 0
    }

    static func createDateSequence(
        starting: Date = Date(),
        count: Int,
        interval: TimeInterval = 86400 // 1 day
    ) -> [Date] {
        return (0..<count).map { i in
            starting.addingTimeInterval(TimeInterval(i) * interval)
        }
    }

    static func testModifiedDateUpdate<T: AnyObject>(
        on object: T,
        modifiedDateKeyPath: ReferenceWritableKeyPath<T, Date>,
        updateMethod: (T) -> Void
    ) {
        let originalDate = object[keyPath: modifiedDateKeyPath]
        let newDate = originalDate.addingTimeInterval(1.0)
        object[keyPath: modifiedDateKeyPath] = newDate
        updateMethod(object)

        let finalDate = object[keyPath: modifiedDateKeyPath]
        assert(finalDate > originalDate, "Modified date should be updated")
    }
}

// MARK: - Basic Test Structure

struct ToDooziesTests {

    @Test func factoriesCreateValidObjects() async throws {
        // Test that all factories create valid objects
        let task = TaskFactory.create()
        #expect(task.title == "Test Task")
        #expect(task.priority == .medium)
        #expect(task.status == .notStarted)

        let category = CategoryFactory.createPersonal()
        #expect(category.name == "Personal")
        #expect(category.color == "#007AFF")

        let rule = RecurrenceRuleFactory.createDaily()
        #expect(rule.frequency == .daily)
        #expect(rule.interval == 1)

        let subtask = SubtaskFactory.create()
        #expect(subtask.title == "Test Subtask")
        #expect(subtask.isComplete == false)

        let attachment = AttachmentFactory.createImage()
        #expect(attachment.attachmentType == .image)
        #expect(attachment.isImage == true)

        let habit = HabitFactory.createDailyMeditation()
        #expect(habit.baseTask?.title == "Daily Meditation")
        #expect(habit.currentStreak == 0)
    }

    @Test func testHelpersWork() async throws {
        let container = try await TestHelpers.createInMemoryModelContainer()
        // Test that container was created successfully
        #expect(true) // Container creation didn't throw, so it worked

        let futureDate = TestHelpers.createTestDate(daysFromNow: 5)
        let today = Date()
        #expect(futureDate > today)

        let datetime = TestHelpers.createTestDatetime(daysFromNow: 1, hour: 14, minute: 30)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: datetime)
        let minute = calendar.component(.minute, from: datetime)
        #expect(hour == 14)
        #expect(minute == 30)
    }
}

// MARK: - Task Model Tests

struct TaskModelTests {

    @Test func taskCreation() async throws {
        let task = TaskFactory.create(
            title: "Test Task",
            description: "Test Description",
            priority: .high,
            status: .inProgress
        )

        #expect(task.title == "Test Task")
        #expect(task.taskDescription == "Test Description")
        #expect(task.priority == .high)
        #expect(task.status == .inProgress)
        #expect(task.isRecurring == false)
        #expect(task.completedDate == nil)
        #expect(task.isCompleted == false)
        #expect(task.createdDate <= Date())
        #expect(task.modifiedDate <= Date())
    }

    @Test func taskCompletion() async throws {
        let task = TaskFactory.create(title: "Incomplete Task")

        // Initially not completed
        #expect(task.status == .notStarted)
        #expect(task.completedDate == nil)
        #expect(task.isCompleted == false)

        // Mark as completed
        task.markCompleted()

        #expect(task.status == .complete)
        #expect(task.completedDate != nil)
        #expect(task.isCompleted == true)
        #expect(task.modifiedDate <= Date())
    }

    @Test func taskMarkIncomplete() async throws {
        let task = TaskFactory.createCompleted()

        // Initially completed
        #expect(task.status == .complete)
        #expect(task.completedDate != nil)
        #expect(task.isCompleted == true)

        // Mark as incomplete
        task.markIncomplete()

        #expect(task.status == .notStarted)
        #expect(task.completedDate == nil)
        #expect(task.isCompleted == false)
    }

    @Test func taskDueDateProperties() async throws {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // Due today
        let taskDueToday = TaskFactory.create(dueDate: today)
        #expect(taskDueToday.isDueToday == true)
        #expect(taskDueToday.isDueTomorrow == false)
        #expect(taskDueToday.isOverdue == false)

        // Due tomorrow
        let taskDueTomorrow = TaskFactory.create(dueDate: tomorrow)
        #expect(taskDueTomorrow.isDueToday == false)
        #expect(taskDueTomorrow.isDueTomorrow == true)
        #expect(taskDueTomorrow.isOverdue == false)

        // Overdue
        let overdueTask = TaskFactory.create(dueDate: yesterday)
        #expect(overdueTask.isDueToday == false)
        #expect(overdueTask.isDueTomorrow == false)
        #expect(overdueTask.isOverdue == true)

        // Completed task is never overdue
        let completedOverdueTask = TaskFactory.create(dueDate: yesterday)
        completedOverdueTask.markCompleted()
        #expect(completedOverdueTask.isOverdue == false)
    }

    @Test func taskSubtaskManagement() async throws {
        let task = TaskFactory.create(title: "Parent Task")

        // Initially no subtasks
        #expect(task.subtasks.isEmpty)
        #expect(task.subtaskProgress == 0.0)

        // Add subtasks
        task.addSubtask(title: "Subtask 1")
        task.addSubtask(title: "Subtask 2")
        task.addSubtask(title: "Subtask 3")

        #expect(task.subtasks.count == 3)
        #expect(task.subtaskProgress == 0.0) // None completed

        // Complete one subtask
        task.subtasks[0].markCompleted()
        #expect(task.subtaskProgress == 1.0/3.0)

        // Complete all subtasks
        task.subtasks[1].markCompleted()
        task.subtasks[2].markCompleted()
        #expect(task.subtaskProgress == 1.0)
    }

    @Test func taskSubtaskRemoval() async throws {
        let task = TaskFactory.createWithSubtasks(subtaskCount: 3)
        let subtaskToRemove = task.subtasks.first!

        #expect(task.subtasks.count == 3)

        task.removeSubtask(subtaskToRemove)
        #expect(task.subtasks.count == 2)
        #expect(!task.subtasks.contains { $0.id == subtaskToRemove.id })
    }

    @Test func taskAttachmentManagement() async throws {
        let task = TaskFactory.create(title: "Task with Attachments")

        // Initially no attachments
        #expect(task.attachments.isEmpty)

        // Add attachments
        let imageAttachment = AttachmentFactory.createImage()
        let documentAttachment = AttachmentFactory.createDocument()

        task.addAttachment(imageAttachment)
        task.addAttachment(documentAttachment)

        #expect(task.attachments.count == 2)
        #expect(imageAttachment.parentTask === task)
        #expect(documentAttachment.parentTask === task)
    }

    @Test func taskAttachmentRemoval() async throws {
        let task = TaskFactory.create(title: "Task with Attachments")
        let attachment = AttachmentFactory.createImage()

        task.addAttachment(attachment)
        #expect(task.attachments.count == 1)

        task.removeAttachment(attachment)
        #expect(task.attachments.isEmpty)
    }

    @Test func taskModifiedDateUpdate() async throws {
        let task = TaskFactory.create()
        let originalModifiedDate = task.modifiedDate

        // Test with explicit date advancement
        let newDate = originalModifiedDate.addingTimeInterval(1.0) // 1 second later
        task.modifiedDate = newDate
        task.updateModifiedDate()

        #expect(task.modifiedDate > originalModifiedDate)
    }

    @Test func taskPriorityEnum() async throws {
        #expect(Priority.low.displayName == "Low")
        #expect(Priority.medium.displayName == "Medium")
        #expect(Priority.high.displayName == "High")

        #expect(Priority.low.sortOrder == 1)
        #expect(Priority.medium.sortOrder == 2)
        #expect(Priority.high.sortOrder == 3)

        #expect(Priority.allCases.count == 3)
    }

    @Test func taskStatusEnum() async throws {
        #expect(TaskStatus.notStarted.displayName == "Not Started")
        #expect(TaskStatus.inProgress.displayName == "In Progress")
        #expect(TaskStatus.complete.displayName == "Complete")

        #expect(TaskStatus.notStarted.isCompleted == false)
        #expect(TaskStatus.inProgress.isCompleted == false)
        #expect(TaskStatus.complete.isCompleted == true)

        #expect(TaskStatus.allCases.count == 3)
    }
}

// MARK: - RecurrenceRule Model Tests

struct RecurrenceRuleModelTests {

    @Test func recurrenceRuleCreation() async throws {
        let rule = RecurrenceRuleFactory.create(
            frequency: .weekly,
            interval: 2,
            daysOfWeek: [2, 4, 6], // Mon, Wed, Fri
            endDate: TestHelpers.createTestDate(daysFromNow: 30)
        )

        #expect(rule.frequency == .weekly)
        #expect(rule.interval == 2)
        #expect(rule.daysOfWeek == [2, 4, 6])
        #expect(rule.endDate != nil)
        #expect(rule.exceptions.isEmpty)
        #expect(rule.createdDate <= Date())
        #expect(rule.modifiedDate <= Date())
    }

    @Test func dailyRecurrence() async throws {
        let rule = RecurrenceRuleFactory.createDaily()
        let startDate = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        let expectedNext = Calendar.current.date(byAdding: .day, value: 1, to: startDate)

        #expect(nextOccurrence != nil)
        #expect(TestHelpers.areDatesInSameDay(nextOccurrence!, expectedNext!))
    }

    @Test func everyOtherDayRecurrence() async throws {
        let rule = RecurrenceRuleFactory.createEveryOtherDay()
        let startDate = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        let expectedNext = Calendar.current.date(byAdding: .day, value: 2, to: startDate)

        #expect(nextOccurrence != nil)
        #expect(TestHelpers.areDatesInSameDay(nextOccurrence!, expectedNext!))
    }

    @Test func weeklyRecurrence() async throws {
        let rule = RecurrenceRuleFactory.createWeekly()
        let startDate = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        let expectedNext = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate)

        #expect(nextOccurrence != nil)
        #expect(TestHelpers.areDatesInSameDay(nextOccurrence!, expectedNext!))
    }

    @Test func weekdayRecurrence() async throws {
        let rule = RecurrenceRuleFactory.createWeekdays()
        let calendar = Calendar.current

        // Test from a Sunday (should go to Monday)
        let sunday = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sunday)
        components.weekday = 1 // Sunday
        let testSunday = calendar.date(from: components)!

        let nextFromSunday = rule.nextOccurrence(after: testSunday)
        #expect(nextFromSunday != nil)

        let nextWeekday = calendar.component(.weekday, from: nextFromSunday!)
        #expect([2, 3, 4, 5, 6].contains(nextWeekday)) // Mon-Fri
    }

    @Test func monthlyRecurrence() async throws {
        let rule = RecurrenceRuleFactory.createMonthly()
        let startDate = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        let expectedNext = Calendar.current.date(byAdding: .month, value: 1, to: startDate)

        #expect(nextOccurrence != nil)

        // Should be same day of month, next month
        let nextDay = Calendar.current.component(.day, from: nextOccurrence!)
        #expect(nextDay == 15) // RecurrenceRuleFactory.createMonthly() uses day 15
    }

    @Test func exceptionManagement() async throws {
        let rule = RecurrenceRuleFactory.createDaily()
        let exceptionDate = TestHelpers.createTestDate(daysFromNow: 5)

        // Initially no exceptions
        #expect(rule.exceptions.isEmpty)
        #expect(rule.isValidOccurrence(date: exceptionDate) == true)

        // Add exception
        rule.addException(date: exceptionDate)
        #expect(rule.exceptions.count == 1)
        #expect(rule.isValidOccurrence(date: exceptionDate) == false)

        // Remove exception
        rule.removeException(date: exceptionDate)
        #expect(rule.exceptions.isEmpty)
        #expect(rule.isValidOccurrence(date: exceptionDate) == true)
    }

    @Test func multipleExceptions() async throws {
        let rule = RecurrenceRuleFactory.createDaily()
        let exception1 = TestHelpers.createTestDate(daysFromNow: 1)
        let exception2 = TestHelpers.createTestDate(daysFromNow: 3)
        let exception3 = TestHelpers.createTestDate(daysFromNow: 5)

        rule.addException(date: exception1)
        rule.addException(date: exception2)
        rule.addException(date: exception3)

        #expect(rule.exceptions.count == 3)
        #expect(rule.isValidOccurrence(date: exception1) == false)
        #expect(rule.isValidOccurrence(date: exception2) == false)
        #expect(rule.isValidOccurrence(date: exception3) == false)

        // Non-exception dates should still be valid
        let validDate = TestHelpers.createTestDate(daysFromNow: 2)
        #expect(rule.isValidOccurrence(date: validDate) == true)
    }

    @Test func endDateRespected() async throws {
        let endDate = TestHelpers.createTestDate(daysFromNow: 7)
        let rule = RecurrenceRuleFactory.createWithEndDate(daysFromNow: 7)

        #expect(rule.endDate != nil)
        #expect(TestHelpers.areDatesInSameDay(rule.endDate!, endDate))
    }

    @Test func recurrenceFrequencyEnum() async throws {
        #expect(RecurrenceFrequency.daily.displayName == "Daily")
        #expect(RecurrenceFrequency.weekly.displayName == "Weekly")
        #expect(RecurrenceFrequency.monthly.displayName == "Monthly")
        #expect(RecurrenceFrequency.custom.displayName == "Custom")

        #expect(RecurrenceFrequency.allCases.count == 4)
    }

    @Test func complexWeeklyPattern() async throws {
        // Every Tuesday and Thursday
        let rule = RecurrenceRuleFactory.create(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [3, 5] // Tue, Thu
        )

        let calendar = Calendar.current
        let today = Date()

        // Find next occurrence
        let nextOccurrence = rule.nextOccurrence(after: today)
        #expect(nextOccurrence != nil)

        let nextWeekday = calendar.component(.weekday, from: nextOccurrence!)
        #expect([3, 5].contains(nextWeekday)) // Should be Tue or Thu
    }

    @Test func biweeklyPattern() async throws {
        let rule = RecurrenceRuleFactory.createBiweekly()
        let startDate = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        #expect(nextOccurrence != nil)

        // Should be 2 weeks later
        let daysBetween = TestHelpers.daysBetween(startDate, nextOccurrence!)
        #expect(daysBetween == 14)
    }

    @Test func firstOfMonthPattern() async throws {
        let rule = RecurrenceRuleFactory.createFirstOfMonth()
        let calendar = Calendar.current

        let startDate = TestHelpers.createTestDatetime(daysFromNow: 0, hour: 10)
        let nextOccurrence = rule.nextOccurrence(after: startDate)

        #expect(nextOccurrence != nil)

        let dayOfMonth = calendar.component(.day, from: nextOccurrence!)
        #expect(dayOfMonth == 1)
    }
}

// MARK: - Habit Model Tests

struct HabitModelTests {

    @Test func habitCreation() async throws {
        let task = TaskFactory.create(title: "Daily Exercise", isRecurring: true)
        let habit = Habit(baseTask: task, targetCompletionsPerPeriod: 30)

        #expect(habit.baseTask === task)
        #expect(habit.currentStreak == 0)
        #expect(habit.bestStreak == 0)
        #expect(habit.totalCompletions == 0)
        #expect(habit.completionDates.isEmpty)
        #expect(habit.protectionDaysUsed == 0)
        #expect(habit.lastProtectionDate == nil)
        #expect(habit.targetCompletionsPerPeriod == 30)
        #expect(habit.isCompletedToday == false)
        #expect(task.isRecurring == true)
    }

    @Test func habitCompletion() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let today = Date()

        // Initially not completed
        #expect(habit.isCompletedToday == false)
        #expect(habit.currentStreak == 0)
        #expect(habit.totalCompletions == 0)

        // Mark completed today
        habit.markCompleted(on: today)

        #expect(habit.isCompletedToday == true)
        #expect(habit.currentStreak == 1)
        #expect(habit.bestStreak == 1)
        #expect(habit.totalCompletions == 1)
        #expect(habit.completionDates.count == 1)
        #expect(habit.baseTask?.isCompleted == true)
    }

    @Test func habitMultipleDayStreak() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Complete for 5 consecutive days
        for i in 0..<5 {
            let completionDate = calendar.date(byAdding: .day, value: -i, to: today)!
            habit.markCompleted(on: completionDate)
        }

        #expect(habit.currentStreak == 5)
        #expect(habit.bestStreak == 5)
        #expect(habit.totalCompletions == 5)
        #expect(habit.completionDates.count == 5)
    }

    @Test func habitStreakBreaking() async throws {
        let habit = HabitFactory.createWithCurrentStreak(days: 7)

        #expect(habit.currentStreak == 7)
        #expect(habit.bestStreak == 7)

        // Now create a habit with broken streak scenario
        let brokenStreakHabit = HabitFactory.createWithBrokenStreak(currentStreak: 3, bestStreak: 7)

        #expect(brokenStreakHabit.currentStreak == 3)
        #expect(brokenStreakHabit.bestStreak == 7)
    }

    @Test func habitDuplicateCompletion() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let today = Date()

        // Mark completed twice on same day
        habit.markCompleted(on: today)
        habit.markCompleted(on: today)

        // Should only count once
        #expect(habit.totalCompletions == 1)
        #expect(habit.completionDates.count == 1)
        #expect(habit.currentStreak == 1)
    }

    @Test func habitMarkIncomplete() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let today = Date()

        // Complete then mark incomplete
        habit.markCompleted(on: today)
        #expect(habit.totalCompletions == 1)
        #expect(habit.isCompletedToday == true)

        habit.markIncomplete(on: today)
        #expect(habit.totalCompletions == 0)
        #expect(habit.isCompletedToday == false)
        #expect(habit.currentStreak == 0)
        #expect(habit.baseTask?.isCompleted == false)
    }

    @Test func habitProtectionDays() async throws {
        let habit = HabitFactory.createDailyMeditation()

        // Initially no protection days used
        #expect(habit.protectionDaysUsed == 0)
        #expect(habit.availableProtectionDays == 2)
        #expect(habit.lastProtectionDate == nil)

        // Use first protection day
        let success1 = habit.useProtectionDay()
        #expect(success1 == true)
        #expect(habit.protectionDaysUsed == 1)
        #expect(habit.availableProtectionDays == 1)
        #expect(habit.lastProtectionDate != nil)

        // Use second protection day
        let success2 = habit.useProtectionDay()
        #expect(success2 == true)
        #expect(habit.protectionDaysUsed == 2)
        #expect(habit.availableProtectionDays == 0)

        // Try to use third protection day (should fail)
        let success3 = habit.useProtectionDay()
        #expect(success3 == false)
        #expect(habit.protectionDaysUsed == 2) // Should remain 2
    }

    @Test func habitProtectionDaysMonthlyReset() async throws {
        let habit = HabitFactory.createWithProtectionDays(used: 2)
        let calendar = Calendar.current

        #expect(habit.protectionDaysUsed == 2)
        #expect(habit.availableProtectionDays == 0)

        // Set last protection date to previous month
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        habit.lastProtectionDate = lastMonth

        // Should now have protection days available again
        #expect(habit.availableProtectionDays == 2)

        // Using protection day should reset counter
        let success = habit.useProtectionDay()
        #expect(success == true)
        #expect(habit.protectionDaysUsed == 1)
    }

    @Test func habitCompletionRate() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let calendar = Calendar.current

        // Set creation date to 10 days ago
        let creationDate = calendar.date(byAdding: .day, value: -9, to: Date())!
        habit.createdDate = creationDate

        // Complete 5 out of 10 days
        for i in [0, 2, 4, 6, 8] {
            let completionDate = calendar.date(byAdding: .day, value: -i, to: Date())!
            habit.markCompleted(on: completionDate)
        }

        let expectedRate = 5.0 / 10.0 // 5 completions in 10 days
        #expect(abs(habit.completionRate - expectedRate) < 0.01)
    }

    @Test func habitCompletionDatesInRange() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let calendar = Calendar.current
        let today = Date()

        // Complete several days
        let completionDates = [
            calendar.date(byAdding: .day, value: -1, to: today)!, // Yesterday
            calendar.date(byAdding: .day, value: -3, to: today)!, // 3 days ago
            calendar.date(byAdding: .day, value: -7, to: today)!, // 1 week ago
            calendar.date(byAdding: .day, value: -14, to: today)! // 2 weeks ago
        ]

        for date in completionDates {
            habit.markCompleted(on: date)
        }

        // Test range: last week only
        let weekStart = calendar.date(byAdding: .day, value: -7, to: today)!
        let weekEnd = today

        let weekCompletions = habit.completionDatesInRange(from: weekStart, to: weekEnd)
        #expect(weekCompletions.count == 2) // Yesterday and 3 days ago
    }

    @Test func habitStreakOnSpecificDate() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Complete days: today, yesterday, day before yesterday
        for i in 0..<3 {
            let completionDate = calendar.date(byAdding: .day, value: -i, to: today)!
            habit.markCompleted(on: completionDate)
        }

        // Skip day -3, then complete days -4 and -5
        for i in 4..<6 {
            let completionDate = calendar.date(byAdding: .day, value: -i, to: today)!
            habit.markCompleted(on: completionDate)
        }

        // Check streak on different dates
        let streakToday = habit.streakOnDate(today)
        #expect(streakToday == 3)

        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let streakTwoDaysAgo = habit.streakOnDate(twoDaysAgo)
        #expect(streakTwoDaysAgo == 3)

        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!
        let streakFourDaysAgo = habit.streakOnDate(fourDaysAgo)
        #expect(streakFourDaysAgo == 2) // Only days -4 and -5
    }

    @Test func habitMonthlyCompletionRate() async throws {
        let habit = HabitFactory.createDailyMeditation()
        let calendar = Calendar.current
        let today = Date()

        // Complete 15 days this month
        for i in 0..<15 {
            let completionDate = calendar.date(byAdding: .day, value: -i, to: today)!
            habit.markCompleted(on: completionDate)
        }

        let monthlyRate = habit.monthlyCompletionRate(for: today)
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let expectedRate = 15.0 / Double(daysInMonth)

        #expect(abs(monthlyRate - expectedRate) < 0.01)
    }

    @Test func habitAnalytics() async throws {
        let habit = HabitFactory.createWithCurrentStreak(days: 10)

        // Verify analytics properties
        #expect(habit.currentStreak == 10)
        #expect(habit.bestStreak == 10)
        #expect(habit.totalCompletions == 10)
        #expect(habit.completionDates.count == 10)
        #expect(habit.completionRate > 0.0)
        #expect(habit.isCompletedToday == true)

        // Test monthly completion rate
        let monthlyRate = habit.monthlyCompletionRate(for: Date())
        #expect(monthlyRate > 0.0)
        #expect(monthlyRate <= 1.0)
    }
}

// MARK: - Category Model Tests

struct CategoryModelTests {

    @Test func categoryCreation() async throws {
        let category = CategoryFactory.create(
            name: "Work Projects",
            color: "#FF5722",
            icon: "briefcase",
            order: 5
        )

        #expect(category.name == "Work Projects")
        #expect(category.color == "#FF5722")
        #expect(category.icon == "briefcase")
        #expect(category.order == 5)
        #expect(category.tasks.isEmpty)
        #expect(category.taskCount == 0)
        #expect(category.completedTaskCount == 0)
        #expect(category.completionPercentage == 0.0)
    }

    @Test func categoryTaskCounting() async throws {
        let category = CategoryFactory.createWork()
        let task1 = TaskFactory.create(title: "Task 1")
        let task2 = TaskFactory.create(title: "Task 2")
        let task3 = TaskFactory.createCompleted()

        // Assign tasks to category
        task1.category = category
        task2.category = category
        task3.category = category

        category.tasks = [task1, task2, task3]

        #expect(category.taskCount == 3)
        #expect(category.completedTaskCount == 1) // Only task3 is completed
        #expect(abs(category.completionPercentage - (1.0/3.0)) < 0.01)
    }

    @Test func categoryCompletionPercentage() async throws {
        let category = CategoryFactory.createPersonal()

        // No tasks
        #expect(category.completionPercentage == 0.0)

        // Add tasks
        let tasks = [
            TaskFactory.create(title: "Task 1"),
            TaskFactory.createCompleted(),
            TaskFactory.createCompleted(),
            TaskFactory.create(title: "Task 4")
        ]

        for task in tasks {
            task.category = category
        }
        category.tasks = tasks

        // 2 out of 4 completed = 50%
        #expect(abs(category.completionPercentage - 0.5) < 0.01)
    }

    @Test func categoryDefaultCategories() async throws {
        let defaultCategories = CategoryFactory.createDefaultCategories()

        #expect(defaultCategories.count == 5)

        let names = defaultCategories.map { $0.name }
        #expect(names.contains("Personal"))
        #expect(names.contains("Work"))
        #expect(names.contains("Health"))
        #expect(names.contains("Learning"))
        #expect(names.contains("Home"))

        // Check orders are sequential
        let orders = defaultCategories.map { $0.order }.sorted()
        #expect(orders == [1, 2, 3, 4, 5])
    }

    @Test func categoryModifiedDateUpdate() async throws {
        let category = CategoryFactory.create()
        let originalModifiedDate = category.modifiedDate

        // Test with explicit date advancement
        let newDate = originalModifiedDate.addingTimeInterval(1.0) // 1 second later
        category.modifiedDate = newDate
        category.updateModifiedDate()

        #expect(category.modifiedDate > originalModifiedDate)
    }
}

// MARK: - Subtask Model Tests

struct SubtaskModelTests {

    @Test func subtaskCreation() async throws {
        let task = TaskFactory.create(title: "Parent Task")
        let subtask = SubtaskFactory.create(
            title: "Complete subtask",
            order: 1,
            isComplete: false,
            parentTask: task
        )

        #expect(subtask.title == "Complete subtask")
        #expect(subtask.order == 1)
        #expect(subtask.isComplete == false)
        #expect(subtask.parentTask === task)
        #expect(subtask.createdDate <= Date())
        #expect(subtask.modifiedDate <= Date())
    }

    @Test func subtaskCompletion() async throws {
        let subtask = SubtaskFactory.create(title: "Test Subtask")

        // Initially incomplete
        #expect(subtask.isComplete == false)

        // Mark completed
        subtask.markCompleted()
        #expect(subtask.isComplete == true)

        // Mark incomplete
        subtask.markIncomplete()
        #expect(subtask.isComplete == false)

        // Toggle completion
        subtask.toggle()
        #expect(subtask.isComplete == true)

        subtask.toggle()
        #expect(subtask.isComplete == false)
    }

    @Test func subtaskOrdering() async throws {
        let task = TaskFactory.create(title: "Parent Task")
        let subtasks = SubtaskFactory.createMultiple(count: 3, for: task)

        #expect(subtasks.count == 3)
        #expect(subtasks[0].order == 0)
        #expect(subtasks[1].order == 1)
        #expect(subtasks[2].order == 2)

        // All should have same parent
        for subtask in subtasks {
            #expect(subtask.parentTask === task)
        }
    }

    @Test func subtaskMixedCompletion() async throws {
        let task = TaskFactory.create(title: "Parent Task")
        let subtasks = SubtaskFactory.createMixed(totalCount: 5, completedCount: 3, for: task)

        #expect(subtasks.count == 5)

        let completedCount = subtasks.filter { $0.isComplete }.count
        let incompleteCount = subtasks.filter { !$0.isComplete }.count

        #expect(completedCount == 3)
        #expect(incompleteCount == 2)
    }

    @Test func subtaskComparable() async throws {
        let task = TaskFactory.create(title: "Parent Task")
        let incompleteSubtask1 = SubtaskFactory.create(title: "Incomplete 1", order: 1, parentTask: task)
        let incompleteSubtask2 = SubtaskFactory.create(title: "Incomplete 2", order: 2, parentTask: task)
        let completedSubtask = SubtaskFactory.create(title: "Completed", order: 0, isComplete: true, parentTask: task)

        // Incomplete tasks should come before completed tasks
        #expect(incompleteSubtask1 < completedSubtask)
        #expect(incompleteSubtask2 < completedSubtask)

        // Among incomplete tasks, order matters
        #expect(incompleteSubtask1 < incompleteSubtask2)
    }

    @Test func subtaskModifiedDateUpdate() async throws {
        let subtask = SubtaskFactory.create()
        let originalModifiedDate = subtask.modifiedDate

        // Test with explicit date advancement
        let newDate = originalModifiedDate.addingTimeInterval(1.0) // 1 second later
        subtask.modifiedDate = newDate
        subtask.updateModifiedDate()

        #expect(subtask.modifiedDate > originalModifiedDate)
    }
}

// MARK: - Attachment Model Tests

struct AttachmentModelTests {

    @Test func attachmentCreation() async throws {
        let task = TaskFactory.create(title: "Task with Attachment")
        let attachment = AttachmentFactory.create(
            fileName: "report.pdf",
            fileExtension: "pdf",
            mimeType: "application/pdf",
            fileSize: 1024000,
            localURL: "/tmp/report.pdf",
            parentTask: task
        )

        #expect(attachment.fileName == "report.pdf")
        #expect(attachment.fileExtension == "pdf")
        #expect(attachment.mimeType == "application/pdf")
        #expect(attachment.fileSize == 1024000)
        #expect(attachment.localURL == "/tmp/report.pdf")
        #expect(attachment.parentTask === task)
        #expect(attachment.cloudURL == nil)
        #expect(attachment.thumbnailData == nil)
    }

    @Test func attachmentTypes() async throws {
        let imageAttachment = AttachmentFactory.createImage()
        #expect(imageAttachment.attachmentType == .image)
        #expect(imageAttachment.isImage == true)
        #expect(imageAttachment.isDocument == false)

        let documentAttachment = AttachmentFactory.createDocument()
        #expect(documentAttachment.attachmentType == .document)
        #expect(documentAttachment.isImage == false)
        #expect(documentAttachment.isDocument == true)

        let audioAttachment = AttachmentFactory.createAudio()
        #expect(audioAttachment.attachmentType == .audio)

        let videoAttachment = AttachmentFactory.createVideo()
        #expect(videoAttachment.attachmentType == .video)
    }

    @Test func attachmentTypeClassification() async throws {
        // Test image types
        let jpegAttachment = AttachmentFactory.create(fileExtension: "jpg", mimeType: "image/jpeg")
        #expect(jpegAttachment.attachmentType == .image)

        let pngAttachment = AttachmentFactory.create(fileExtension: "png", mimeType: "image/png")
        #expect(pngAttachment.attachmentType == .image)

        // Test document types
        let pdfAttachment = AttachmentFactory.create(fileExtension: "pdf", mimeType: "application/pdf")
        #expect(pdfAttachment.attachmentType == .document)

        let textAttachment = AttachmentFactory.create(fileExtension: "txt", mimeType: "text/plain")
        #expect(textAttachment.attachmentType == .document)

        // Test audio types
        let mp3Attachment = AttachmentFactory.create(fileExtension: "mp3", mimeType: "audio/mpeg")
        #expect(mp3Attachment.attachmentType == .audio)

        // Test video types
        let mp4Attachment = AttachmentFactory.create(fileExtension: "mp4", mimeType: "video/mp4")
        #expect(mp4Attachment.attachmentType == .video)

        // Test unknown types
        let unknownAttachment = AttachmentFactory.create(fileExtension: "xyz", mimeType: "application/unknown")
        #expect(unknownAttachment.attachmentType == .other)
    }

    @Test func attachmentDisplayProperties() async throws {
        let attachment = AttachmentFactory.create(
            fileName: "My Document.pdf",
            fileSize: 2048576 // 2MB
        )

        #expect(attachment.displayName == "My Document.pdf")
        #expect(attachment.formattedFileSize.contains("2"))
        #expect(attachment.formattedFileSize.contains("MB"))

        // Test empty filename
        let emptyNameAttachment = AttachmentFactory.create(fileName: "")
        #expect(emptyNameAttachment.displayName == "Untitled")
    }

    @Test func attachmentTypeIcons() async throws {
        #expect(AttachmentType.image.iconName == "photo")
        #expect(AttachmentType.document.iconName == "doc.text")
        #expect(AttachmentType.audio.iconName == "music.note")
        #expect(AttachmentType.video.iconName == "video")
        #expect(AttachmentType.other.iconName == "paperclip")
    }

    @Test func attachmentTypeDisplayNames() async throws {
        #expect(AttachmentType.image.displayName == "Image")
        #expect(AttachmentType.document.displayName == "Document")
        #expect(AttachmentType.audio.displayName == "Audio")
        #expect(AttachmentType.video.displayName == "Video")
        #expect(AttachmentType.other.displayName == "File")
    }

    @Test func attachmentMultipleForTask() async throws {
        let task = TaskFactory.create(title: "Task with Multiple Attachments")
        let attachments = AttachmentFactory.createMultiple(count: 3, for: task)

        #expect(attachments.count == 3)

        for (index, attachment) in attachments.enumerated() {
            #expect(attachment.fileName == "file-\(index + 1).txt")
            #expect(attachment.parentTask === task)
        }
    }

    @Test func attachmentModifiedDateUpdate() async throws {
        let attachment = AttachmentFactory.create()
        let originalModifiedDate = attachment.modifiedDate

        // Test with explicit date advancement
        let newDate = originalModifiedDate.addingTimeInterval(1.0) // 1 second later
        attachment.modifiedDate = newDate
        attachment.updateModifiedDate()

        #expect(attachment.modifiedDate > originalModifiedDate)
    }
}

// MARK: - CRUD Operations Tests

struct CRUDOperationsTests {

    @Test func taskCRUDOperations() async throws {
        try await TestHelpers.withTestContext { context in
            // Create
            let task = TaskFactory.create(title: "CRUD Test Task", priority: .high)
            context.insert(task)
            try context.save()

            // Read
            let predicate = #Predicate<ToDoozies.Task> { $0.title == "CRUD Test Task" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let fetchedTasks = try context.fetch(descriptor)

            #expect(fetchedTasks.count == 1)
            #expect(fetchedTasks.first?.title == "CRUD Test Task")
            #expect(fetchedTasks.first?.priority == .high)

            // Update
            let fetchedTask = fetchedTasks.first!
            fetchedTask.title = "Updated CRUD Task"
            fetchedTask.priority = .low
            try context.save()

            let updatedTasks = try context.fetch(descriptor)
            #expect(updatedTasks.isEmpty) // Old predicate should find nothing

            let updatedPredicate = #Predicate<ToDoozies.Task> { $0.title == "Updated CRUD Task" }
            let updatedDescriptor = FetchDescriptor(predicate: updatedPredicate)
            let updatedResults = try context.fetch(updatedDescriptor)

            #expect(updatedResults.count == 1)
            #expect(updatedResults.first?.priority == .low)

            // Delete
            context.delete(fetchedTask)
            try context.save()

            let deletedResults = try context.fetch(updatedDescriptor)
            #expect(deletedResults.isEmpty)
        }
    }

    @Test func categoryCRUDOperations() async throws {
        try await TestHelpers.withTestContext { context in
            // Create category with tasks
            let category = CategoryFactory.createWork()
            let task1 = TaskFactory.create(title: "Task 1")
            let task2 = TaskFactory.create(title: "Task 2")

            task1.category = category
            task2.category = category

            context.insert(category)
            context.insert(task1)
            context.insert(task2)
            try context.save()

            // Read and verify relationships
            let categoryPredicate = #Predicate<ToDoozies.Category> { $0.name == "Work" }
            let categoryDescriptor = FetchDescriptor(predicate: categoryPredicate)
            let fetchedCategories = try context.fetch(categoryDescriptor)

            #expect(fetchedCategories.count == 1)
            let fetchedCategory = fetchedCategories.first!
            #expect(fetchedCategory.tasks.count == 2)

            // Update category
            fetchedCategory.name = "Updated Work"
            fetchedCategory.color = "#FF0000"
            try context.save()

            // Verify update
            let updatedPredicate = #Predicate<ToDoozies.Category> { $0.name == "Updated Work" }
            let updatedDescriptor = FetchDescriptor(predicate: updatedPredicate)
            let updatedCategories = try context.fetch(updatedDescriptor)

            #expect(updatedCategories.count == 1)
            #expect(updatedCategories.first?.color == "#FF0000")

            // Delete category (should nullify task relationships)
            context.delete(fetchedCategory)
            try context.save()

            // Verify tasks still exist but category is null
            let taskDescriptor = FetchDescriptor<ToDoozies.Task>()
            let remainingTasks = try context.fetch(taskDescriptor)
            #expect(remainingTasks.count == 2)
            #expect(remainingTasks.allSatisfy { $0.category == nil })
        }
    }

    @Test func habitCRUDOperations() async throws {
        try await TestHelpers.withTestContext { context in
            // Create habit with base task
            let baseTask = TaskFactory.create(title: "Meditation", isRecurring: true)
            let habit = HabitFactory.create(baseTask: baseTask, targetCompletionsPerPeriod: 30)

            context.insert(baseTask)
            context.insert(habit)
            try context.save()

            // Read
            let habitDescriptor = FetchDescriptor<Habit>()
            let fetchedHabits = try context.fetch(habitDescriptor)

            #expect(fetchedHabits.count == 1)
            #expect(fetchedHabits.first?.baseTask?.title == "Meditation")
            #expect(fetchedHabits.first?.targetCompletionsPerPeriod == 30)

            // Update habit
            let fetchedHabit = fetchedHabits.first!
            fetchedHabit.currentStreak = 5
            fetchedHabit.bestStreak = 10
            fetchedHabit.totalCompletions = 25
            try context.save()

            // Verify update
            let updatedHabits = try context.fetch(habitDescriptor)
            #expect(updatedHabits.first?.currentStreak == 5)
            #expect(updatedHabits.first?.bestStreak == 10)
            #expect(updatedHabits.first?.totalCompletions == 25)

            // Delete habit (should cascade delete base task)
            context.delete(fetchedHabit)
            try context.save()

            // Verify deletion
            let deletedHabits = try context.fetch(habitDescriptor)
            #expect(deletedHabits.isEmpty)

            // Base task should also be deleted due to cascade relationship
            let taskDescriptor = FetchDescriptor<ToDoozies.Task>()
            let remainingTasks = try context.fetch(taskDescriptor)
            #expect(remainingTasks.isEmpty)
        }
    }

    @Test func bulkOperations() async throws {
        try await TestHelpers.withTestContext { context in
            // Create multiple tasks
            let taskCount = 100
            var tasks: [ToDoozies.Task] = []

            for i in 0..<taskCount {
                let task = TaskFactory.create(title: "Bulk Task \(i)", priority: i % 2 == 0 ? .high : .low)
                tasks.append(task)
                context.insert(task)
            }

            try context.save()

            // Verify all tasks were created
            let allTasksDescriptor = FetchDescriptor<ToDoozies.Task>()
            let allTasks = try context.fetch(allTasksDescriptor)
            #expect(allTasks.count == taskCount)

            // Bulk update - mark all high priority tasks as completed
            let highPriorityPredicate = #Predicate<ToDoozies.Task> { $0.priority == Priority.high }
            let highPriorityDescriptor = FetchDescriptor(predicate: highPriorityPredicate)
            let highPriorityTasks = try context.fetch(highPriorityDescriptor)

            for task in highPriorityTasks {
                task.markCompleted()
            }
            try context.save()

            // Verify updates
            let completedPredicate = #Predicate<ToDoozies.Task> { $0.status == TaskStatus.complete }
            let completedDescriptor = FetchDescriptor(predicate: completedPredicate)
            let completedTasks = try context.fetch(completedDescriptor)

            #expect(completedTasks.count == taskCount / 2) // Half should be completed

            // Bulk delete - remove all completed tasks
            for task in completedTasks {
                context.delete(task)
            }
            try context.save()

            // Verify deletion
            let remainingTasks = try context.fetch(allTasksDescriptor)
            #expect(remainingTasks.count == taskCount / 2)
            #expect(remainingTasks.allSatisfy { $0.status != .complete })
        }
    }
}

// MARK: - Relationship Integrity Tests

struct RelationshipTests {

    @Test func taskCategoryRelationship() async throws {
        try await TestHelpers.withTestContext { context in
            let category = CategoryFactory.createWork()
            let task1 = TaskFactory.create(title: "Task 1")
            let task2 = TaskFactory.create(title: "Task 2")

            context.insert(category)
            context.insert(task1)
            context.insert(task2)

            // Establish relationships
            task1.category = category
            task2.category = category
            try context.save()

            // Verify bidirectional relationship
            #expect(category.tasks.count == 2)
            #expect(category.tasks.contains { $0.id == task1.id })
            #expect(category.tasks.contains { $0.id == task2.id })
            #expect(task1.category?.id == category.id)
            #expect(task2.category?.id == category.id)

            // Test category deletion (nullify relationship)
            context.delete(category)
            try context.save()

            #expect(task1.category == nil)
            #expect(task2.category == nil)
        }
    }

    @Test func taskSubtaskCascadeDelete() async throws {
        try await TestHelpers.withTestContext { context in
            let task = TaskFactory.create(title: "Parent Task")
            let subtask1 = SubtaskFactory.create(title: "Subtask 1", parentTask: task)
            let subtask2 = SubtaskFactory.create(title: "Subtask 2", parentTask: task)

            task.subtasks = [subtask1, subtask2]

            context.insert(task)
            context.insert(subtask1)
            context.insert(subtask2)
            try context.save()

            // Verify relationship
            #expect(task.subtasks.count == 2)
            #expect(subtask1.parentTask?.id == task.id)
            #expect(subtask2.parentTask?.id == task.id)

            // Delete parent task
            context.delete(task)
            try context.save()

            // Verify cascade deletion
            let subtaskDescriptor = FetchDescriptor<Subtask>()
            let remainingSubtasks = try context.fetch(subtaskDescriptor)
            #expect(remainingSubtasks.isEmpty, "Subtasks should be cascade deleted with parent task")
        }
    }

    @Test func taskAttachmentCascadeDelete() async throws {
        try await TestHelpers.withTestContext { context in
            let task = TaskFactory.create(title: "Task with Attachments")
            let attachment1 = AttachmentFactory.createImage()
            let attachment2 = AttachmentFactory.createDocument()

            task.addAttachment(attachment1)
            task.addAttachment(attachment2)

            context.insert(task)
            context.insert(attachment1)
            context.insert(attachment2)
            try context.save()

            // Verify relationship
            #expect(task.attachments.count == 2)
            #expect(attachment1.parentTask?.id == task.id)
            #expect(attachment2.parentTask?.id == task.id)

            // Delete parent task
            context.delete(task)
            try context.save()

            // Verify cascade deletion
            let attachmentDescriptor = FetchDescriptor<Attachment>()
            let remainingAttachments = try context.fetch(attachmentDescriptor)
            #expect(remainingAttachments.isEmpty, "Attachments should be cascade deleted with parent task")
        }
    }

    @Test func habitTaskRelationship() async throws {
        try await TestHelpers.withTestContext { context in
            let baseTask = TaskFactory.create(title: "Exercise", isRecurring: true)
            let habit = HabitFactory.create(baseTask: baseTask)

            context.insert(baseTask)
            context.insert(habit)
            try context.save()

            // Verify relationship
            #expect(habit.baseTask?.id == baseTask.id)
            #expect(baseTask.isRecurring == true)

            // Test habit completion affects base task
            habit.markCompleted()
            #expect(habit.baseTask?.isCompleted == true)

            // Test habit deletion cascades to base task
            context.delete(habit)
            try context.save()

            let taskDescriptor = FetchDescriptor<ToDoozies.Task>()
            let remainingTasks = try context.fetch(taskDescriptor)
            #expect(remainingTasks.isEmpty, "Base task should be cascade deleted with habit")
        }
    }

    @Test func complexRelationshipIntegrity() async throws {
        try await TestHelpers.withTestContext { context in
            // Create complex object graph
            let category = CategoryFactory.createHealth()
            let baseTask = TaskFactory.create(title: "Daily Workout", isRecurring: true)
            let habit = HabitFactory.create(baseTask: baseTask)
            let subtask1 = SubtaskFactory.create(title: "Warm up", parentTask: baseTask)
            let subtask2 = SubtaskFactory.create(title: "Main exercise", parentTask: baseTask)
            let attachment = AttachmentFactory.createVideo()

            // Establish all relationships
            baseTask.category = category
            baseTask.addAttachment(attachment)
            baseTask.subtasks = [subtask1, subtask2]

            // Insert all objects
            context.insert(category)
            context.insert(baseTask)
            context.insert(habit)
            context.insert(subtask1)
            context.insert(subtask2)
            context.insert(attachment)
            try context.save()

            // Verify complete relationship graph
            #expect(category.tasks.count == 1)
            #expect(baseTask.category?.id == category.id)
            #expect(baseTask.subtasks.count == 2)
            #expect(baseTask.attachments.count == 1)
            #expect(habit.baseTask?.id == baseTask.id)
            #expect(subtask1.parentTask?.id == baseTask.id)
            #expect(subtask2.parentTask?.id == baseTask.id)
            #expect(attachment.parentTask?.id == baseTask.id)

            // Test complex deletion behavior
            context.delete(baseTask) // Should cascade to habit, subtasks, attachments but nullify category
            try context.save()

            // Verify cascades and nullifications
            let categoryDescriptor = FetchDescriptor<ToDoozies.Category>()
            let categories = try context.fetch(categoryDescriptor)
            #expect(categories.count == 1) // Category should remain
            #expect(categories.first?.tasks.isEmpty == true) // But with no tasks

            let habitDescriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(habitDescriptor)
            #expect(habits.isEmpty) // Habit should be deleted

            let subtaskDescriptor = FetchDescriptor<Subtask>()
            let subtasks = try context.fetch(subtaskDescriptor)
            #expect(subtasks.isEmpty) // Subtasks should be deleted

            let attachmentDescriptor = FetchDescriptor<Attachment>()
            let attachments = try context.fetch(attachmentDescriptor)
            #expect(attachments.isEmpty) // Attachments should be deleted
        }
    }
}
