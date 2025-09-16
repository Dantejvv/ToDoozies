//
//  RecurrenceRule.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/14/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class RecurrenceRule: @unchecked Sendable {
    var id: UUID = UUID()
    var frequency: RecurrenceFrequency = RecurrenceFrequency.daily
    var interval: Int = 1
    var daysOfWeek: [Int]?
    var dayOfMonth: Int?
    var endDate: Date?
    var exceptions: [Date] = []
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()

    @Relationship
    var task: Task?

    init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endDate = endDate
        self.exceptions = []
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    func addException(date: Date) {
        exceptions.append(date)
        modifiedDate = Date()
    }

    func removeException(date: Date) {
        exceptions.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
        modifiedDate = Date()
    }

    func isValidOccurrence(date: Date) -> Bool {
        return !exceptions.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }

    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
                return nextWeeklyOccurrence(after: date, daysOfWeek: daysOfWeek)
            }
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
        case .monthly:
            if let dayOfMonth = dayOfMonth {
                return nextMonthlyOccurrence(after: date, dayOfMonth: dayOfMonth)
            }
            return calendar.date(byAdding: .month, value: interval, to: date)
        case .custom:
            return calendar.date(byAdding: .day, value: interval, to: date)
        }
    }

    private func nextWeeklyOccurrence(after date: Date, daysOfWeek: [Int]) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)

        for day in daysOfWeek.sorted() {
            if day > currentWeekday {
                let daysToAdd = day - currentWeekday
                return calendar.date(byAdding: .day, value: daysToAdd, to: date)
            }
        }

        let daysToNextWeek = (7 - currentWeekday) + daysOfWeek.min()! + ((interval - 1) * 7)
        return calendar.date(byAdding: .day, value: daysToNextWeek, to: date)
    }

    private func nextMonthlyOccurrence(after date: Date, dayOfMonth: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = dayOfMonth

        if let targetDate = calendar.date(from: components), targetDate > date {
            return targetDate
        }

        components.month! += interval
        return calendar.date(from: components)
    }
}

// MARK: - RecurrenceFrequency Enum
enum RecurrenceFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }
}