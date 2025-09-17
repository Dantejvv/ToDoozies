//
//  RecurrencePickerView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/17/25.
//

import SwiftUI

// MARK: - Recurrence Picker View

struct RecurrencePickerView: View {
    @Binding var recurrenceRule: RecurrenceRule?
    @Environment(\.dismiss) private var dismiss

    @State private var frequency: RecurrenceFrequency = .daily
    @State private var interval: Int = 1
    @State private var selectedWeekdays: Set<Int> = []
    @State private var dayOfMonth: Int = 1
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var validationErrors: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                frequencySection
                intervalSection

                if frequency == .weekly {
                    weekdaysSection
                }

                if frequency == .monthly {
                    monthDaySection
                }

                endDateSection

                if !validationErrors.isEmpty {
                    validationErrorsSection
                }

                recurrencePreviewSection
            }
            .navigationTitle("Recurrence Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveRecurrenceRule()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentRule()
            }
        }
    }

    // MARK: - Form Sections

    private var frequencySection: some View {
        Section("Frequency") {
            Picker("Frequency", selection: $frequency) {
                ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                    Text(freq.displayName)
                        .tag(freq)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: frequency) { _, newValue in
                handleFrequencyChange(newValue)
            }
        }
    }

    private var intervalSection: some View {
        Section("Interval") {
            HStack {
                Text("Every")
                    .foregroundColor(.secondary)

                Stepper(
                    value: $interval,
                    in: 1...99,
                    step: 1
                ) {
                    Text("\(interval)")
                        .fontWeight(.medium)
                        .frame(minWidth: 30)
                }

                Text(intervalDisplayText)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Every \(interval) \(intervalDisplayText)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    if interval < 99 { interval += 1 }
                case .decrement:
                    if interval > 1 { interval -= 1 }
                @unknown default:
                    break
                }
            }
        }
        .onChange(of: interval) { _, _ in
            validateForm()
        }
    }

    private var weekdaysSection: some View {
        Section("Days of the Week") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...7, id: \.self) { dayNumber in
                    WeekdayButton(
                        dayNumber: dayNumber,
                        isSelected: selectedWeekdays.contains(dayNumber),
                        onToggle: {
                            toggleWeekday(dayNumber)
                        }
                    )
                }
            }
            .padding(.vertical, 8)

            if selectedWeekdays.isEmpty {
                Text("Select at least one day")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }

    private var monthDaySection: some View {
        Section("Day of Month") {
            Picker("Day", selection: $dayOfMonth) {
                ForEach(1...31, id: \.self) { day in
                    Text(day == 31 ? "Last day" : "\(day)")
                        .tag(day)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        }
        .onChange(of: dayOfMonth) { _, _ in
            validateForm()
        }
    }

    private var endDateSection: some View {
        Section("End Date") {
            Toggle("Set end date", isOn: $hasEndDate)
                .toggleStyle(.switch)

            if hasEndDate {
                DatePicker(
                    "End Date",
                    selection: $endDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
            }
        }
        .onChange(of: hasEndDate) { _, _ in
            validateForm()
        }
        .onChange(of: endDate) { _, _ in
            validateForm()
        }
    }

    private var validationErrorsSection: some View {
        Section {
            ForEach(validationErrors, id: \.self) { error in
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private var recurrencePreviewSection: some View {
        Section("Preview") {
            VStack(alignment: .leading, spacing: 8) {
                Text(recurrenceDescription)
                    .font(.body)
                    .foregroundColor(.primary)

                if let nextOccurrences = generatePreviewDates() {
                    Text("Next occurrences:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(nextOccurrences.prefix(3), id: \.self) { date in
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var intervalDisplayText: String {
        let baseText: String
        switch frequency {
        case .daily:
            baseText = interval == 1 ? "day" : "days"
        case .weekly:
            baseText = interval == 1 ? "week" : "weeks"
        case .monthly:
            baseText = interval == 1 ? "month" : "months"
        case .custom:
            baseText = interval == 1 ? "day" : "days"
        }
        return baseText
    }

    private var recurrenceDescription: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "Every day" : "Every \(interval) days"
        case .weekly:
            if selectedWeekdays.isEmpty {
                return interval == 1 ? "Every week" : "Every \(interval) weeks"
            } else {
                let dayNames = selectedWeekdays.sorted().map { dayNumber in
                    DateFormatter().weekdaySymbols[dayNumber - 1]
                }
                let daysText = dayNames.joined(separator: ", ")
                return interval == 1 ? "Every week on \(daysText)" : "Every \(interval) weeks on \(daysText)"
            }
        case .monthly:
            let dayText = dayOfMonth == 31 ? "the last day" : "day \(dayOfMonth)"
            return interval == 1 ? "Every month on \(dayText)" : "Every \(interval) months on \(dayText)"
        case .custom:
            return interval == 1 ? "Every day (custom)" : "Every \(interval) days (custom)"
        }
    }

    private var isFormValid: Bool {
        validateForm()
        return validationErrors.isEmpty
    }

    // MARK: - Actions

    private func handleFrequencyChange(_ newFrequency: RecurrenceFrequency) {
        // Reset relevant properties when frequency changes
        switch newFrequency {
        case .weekly:
            if selectedWeekdays.isEmpty {
                // Default to current day of week
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                selectedWeekdays.insert(currentWeekday)
            }
        case .monthly:
            // Default to current day of month
            dayOfMonth = Calendar.current.component(.day, from: Date())
        case .daily, .custom:
            selectedWeekdays.removeAll()
        }
        validateForm()
    }

    private func toggleWeekday(_ dayNumber: Int) {
        if selectedWeekdays.contains(dayNumber) {
            selectedWeekdays.remove(dayNumber)
        } else {
            selectedWeekdays.insert(dayNumber)
        }
        validateForm()
    }

    @discardableResult
    private func validateForm() -> Bool {
        validationErrors.removeAll()

        // Validate interval
        if interval < 1 {
            validationErrors.append("Interval must be at least 1")
        }

        // Validate weekly selection
        if frequency == .weekly && selectedWeekdays.isEmpty {
            validationErrors.append("Select at least one day of the week")
        }

        // Validate end date
        if hasEndDate && endDate <= Date() {
            validationErrors.append("End date must be in the future")
        }

        return validationErrors.isEmpty
    }

    private func loadCurrentRule() {
        if let rule = recurrenceRule {
            frequency = rule.frequency
            interval = rule.interval
            selectedWeekdays = Set(rule.daysOfWeek ?? [])
            dayOfMonth = rule.dayOfMonth ?? Calendar.current.component(.day, from: Date())
            hasEndDate = rule.endDate != nil
            if let ruleEndDate = rule.endDate {
                endDate = ruleEndDate
            }
        } else {
            // Set defaults based on current date
            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: Date())
            selectedWeekdays.insert(currentWeekday)
            dayOfMonth = calendar.component(.day, from: Date())
        }
    }

    private func saveRecurrenceRule() {
        guard isFormValid else { return }

        let rule = RecurrenceRule(
            frequency: frequency,
            interval: interval,
            daysOfWeek: frequency == .weekly ? Array(selectedWeekdays) : nil,
            dayOfMonth: frequency == .monthly ? dayOfMonth : nil,
            endDate: hasEndDate ? endDate : nil
        )

        recurrenceRule = rule
        dismiss()
    }

    private func generatePreviewDates() -> [Date]? {
        guard isFormValid else { return nil }

        var dates: [Date] = []
        var currentDate = Date()

        // Generate next 5 occurrences for preview
        for _ in 0..<5 {
            if let nextDate = getNextOccurrence(after: currentDate) {
                dates.append(nextDate)
                currentDate = nextDate
            } else {
                break
            }
        }

        return dates.isEmpty ? nil : dates
    }

    private func getNextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current

        switch frequency {
        case .daily, .custom:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            if selectedWeekdays.isEmpty { return nil }
            return getNextWeeklyOccurrence(after: date)
        case .monthly:
            return getNextMonthlyOccurrence(after: date)
        }
    }

    private func getNextWeeklyOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let sortedWeekdays = selectedWeekdays.sorted()

        // Try to find next day in current week
        for day in sortedWeekdays {
            if day > currentWeekday {
                let daysToAdd = day - currentWeekday
                return calendar.date(byAdding: .day, value: daysToAdd, to: date)
            }
        }

        // Move to next interval week and use first selected day
        let daysToNextWeek = (8 - currentWeekday) + (sortedWeekdays.first! - 1) + ((interval - 1) * 7)
        return calendar.date(byAdding: .day, value: daysToNextWeek, to: date)
    }

    private func getNextMonthlyOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        if dayOfMonth == 31 {
            // Handle "last day of month"
            components.month! += interval
            components.day = 1
            if let firstOfMonth = calendar.date(from: components),
               let lastOfMonth = calendar.dateInterval(of: .month, for: firstOfMonth)?.end {
                return calendar.date(byAdding: .day, value: -1, to: lastOfMonth)
            }
        } else {
            components.day = dayOfMonth
            // If current day hasn't passed yet this month
            if let targetDate = calendar.date(from: components), targetDate > date {
                return targetDate
            }
            // Move to next interval month
            components.month! += interval
        }

        return calendar.date(from: components)
    }
}

// MARK: - Weekday Button

private struct WeekdayButton: View {
    let dayNumber: Int
    let isSelected: Bool
    let onToggle: () -> Void

    private var dayAbbreviation: String {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols[dayNumber - 1]
    }

    var body: some View {
        Button(action: onToggle) {
            Text(dayAbbreviation)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(DateFormatter().weekdaySymbols[dayNumber - 1])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to toggle selection")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecurrencePickerView(recurrenceRule: .constant(nil))
    }
}

#Preview("With Existing Rule") {
    let sampleRule = RecurrenceRule(
        frequency: .weekly,
        interval: 1,
        daysOfWeek: [2, 4, 6], // Monday, Wednesday, Friday
        dayOfMonth: nil,
        endDate: nil
    )

    return NavigationStack {
        RecurrencePickerView(recurrenceRule: .constant(sampleRule))
    }
}