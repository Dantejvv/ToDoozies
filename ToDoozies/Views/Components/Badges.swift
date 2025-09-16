//
//  Badges.swift
//  ToDoozies
//
//  Created by Claude Code on 9/15/25.
//

import SwiftUI

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: Priority
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium

        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            case .medium: return EdgeInsets(top: .spacing1, leading: .spacing2, bottom: .spacing1, trailing: .spacing2)
            }
        }
    }

    init(priority: Priority, size: BadgeSize = .medium) {
        self.priority = priority
        self.size = size
    }

    var body: some View {
        Text(priority.displayName)
            .font(size.font)
            .fontWeight(.medium)
            .padding(size.padding)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
            .accessibilityLabel("\(priority.displayName) priority")
    }

    private var backgroundColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private var foregroundColor: Color {
        backgroundColor
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: TaskStatus
    let size: PriorityBadge.BadgeSize

    init(status: TaskStatus, size: PriorityBadge.BadgeSize = .medium) {
        self.status = status
        self.size = size
    }

    var body: some View {
        HStack(spacing: .spacing1) {
            Image(systemName: iconName)
                .font(.caption2)

            Text(status.displayName)
                .font(size.font)
                .fontWeight(.medium)
        }
        .padding(size.padding)
        .background(backgroundColor.opacity(0.2))
        .foregroundColor(foregroundColor)
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(status.displayName)")
    }

    private var iconName: String {
        switch status {
        case .notStarted: return "circle"
        case .inProgress: return "clock"
        case .complete: return "checkmark.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .orange
        case .complete: return .green
        }
    }

    private var foregroundColor: Color {
        backgroundColor
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: Category
    let showIcon: Bool
    let size: PriorityBadge.BadgeSize

    init(category: Category, showIcon: Bool = true, size: PriorityBadge.BadgeSize = .medium) {
        self.category = category
        self.showIcon = showIcon
        self.size = size
    }

    var body: some View {
        HStack(spacing: .spacing1) {
            if showIcon {
                Image(systemName: category.icon)
                    .font(.caption2)
            }

            Text(category.name)
                .font(size.font)
                .fontWeight(.medium)
        }
        .padding(size.padding)
        .background(categoryColor.opacity(0.2))
        .foregroundColor(categoryColor)
        .clipShape(Capsule())
        .accessibilityLabel("Category: \(category.name)")
    }

    private var categoryColor: Color {
        Color(hex: category.color) ?? .blue
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streakCount: Int
    let type: StreakType
    let size: PriorityBadge.BadgeSize

    enum StreakType {
        case current
        case best

        var iconName: String {
            switch self {
            case .current: return "flame.fill"
            case .best: return "crown.fill"
            }
        }

        var color: Color {
            switch self {
            case .current: return .orange
            case .best: return .yellow
            }
        }

        var accessibilityPrefix: String {
            switch self {
            case .current: return "Current streak"
            case .best: return "Best streak"
            }
        }
    }

    init(streakCount: Int, type: StreakType, size: PriorityBadge.BadgeSize = .medium) {
        self.streakCount = streakCount
        self.type = type
        self.size = size
    }

    var body: some View {
        HStack(spacing: .spacing1) {
            Image(systemName: type.iconName)
                .font(.caption2)

            Text("\(streakCount)")
                .font(size.font)
                .fontWeight(.medium)
        }
        .padding(size.padding)
        .background(type.color.opacity(0.2))
        .foregroundColor(type.color)
        .clipShape(Capsule())
        .accessibilityLabel("\(type.accessibilityPrefix): \(streakCount) days")
    }
}

// MARK: - Count Badge

struct CountBadge: View {
    let count: Int
    let title: String
    let systemImage: String
    let color: Color
    let size: PriorityBadge.BadgeSize

    init(
        count: Int,
        title: String,
        systemImage: String,
        color: Color = .blue,
        size: PriorityBadge.BadgeSize = .medium
    ) {
        self.count = count
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.size = size
    }

    var body: some View {
        HStack(spacing: .spacing1) {
            Image(systemName: systemImage)
                .font(.caption2)

            Text("\(count)")
                .font(size.font)
                .fontWeight(.medium)
        }
        .padding(size.padding)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .clipShape(Capsule())
        .accessibilityLabel("\(count) \(title)")
    }
}

// MARK: - Filter Badge (Removable)

struct FilterBadge: View {
    let title: String
    let systemImage: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: .spacing1) {
            Image(systemName: systemImage)
                .font(.caption2)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.vertical, .spacing1)
        .padding(.horizontal, .spacing2)
        .background(Color.accentColor.opacity(0.1))
        .foregroundColor(.accentColor)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Filter: \(title)")
        .accessibilityHint("Double tap to remove filter")
        .accessibilityAction(named: "Remove") {
            onRemove()
        }
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let color: Color

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        color: Color = .yellow
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        VStack(spacing: .spacing1) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.spacing3)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement: \(title)")
        .accessibilityValue(subtitle ?? "")
    }
}

// MARK: - Progress Badge

struct ProgressBadge: View {
    let completed: Int
    let total: Int
    let showPercentage: Bool

    init(completed: Int, total: Int, showPercentage: Bool = false) {
        self.completed = completed
        self.total = total
        self.showPercentage = showPercentage
    }

    var body: some View {
        HStack(spacing: .spacing1) {
            Image(systemName: "checklist")
                .font(.caption2)

            if showPercentage && total > 0 {
                Text("\(Int((Double(completed) / Double(total)) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            } else {
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, .spacing1)
        .padding(.horizontal, .spacing2)
        .background(progressColor.opacity(0.2))
        .foregroundColor(progressColor)
        .clipShape(Capsule())
        .accessibilityLabel("Progress: \(completed) of \(total) completed")
        .accessibilityValue(showPercentage && total > 0 ? "\(Int((Double(completed) / Double(total)) * 100)) percent" : "")
    }

    private var progressColor: Color {
        if total == 0 { return .gray }
        let percentage = Double(completed) / Double(total)

        if percentage == 1.0 {
            return .green
        } else if percentage >= 0.7 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        guard hexString.count == 6 else { return nil }

        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else { return nil }

        let r = Double((hexNumber & 0xff0000) >> 16) / 255
        let g = Double((hexNumber & 0x00ff00) >> 8) / 255
        let b = Double(hexNumber & 0x0000ff) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: .spacing4) {
        Text("Priority Badges")
            .font(.headline)

        HStack(spacing: .spacing2) {
            PriorityBadge(priority: .high, size: .small)
            PriorityBadge(priority: .medium)
            PriorityBadge(priority: .low)
        }

        Text("Status Badges")
            .font(.headline)

        HStack(spacing: .spacing2) {
            StatusBadge(status: .notStarted, size: .small)
            StatusBadge(status: .inProgress)
            StatusBadge(status: .complete)
        }

        Text("Streak Badges")
            .font(.headline)

        HStack(spacing: .spacing2) {
            StreakBadge(streakCount: 7, type: .current, size: .small)
            StreakBadge(streakCount: 30, type: .best)
        }

        Text("Count Badges")
            .font(.headline)

        HStack(spacing: .spacing2) {
            CountBadge(count: 3, title: "subtasks", systemImage: "checklist", color: .blue)
            CountBadge(count: 2, title: "attachments", systemImage: "paperclip", color: .purple)
        }

        Text("Progress Badge")
            .font(.headline)

        HStack(spacing: .spacing2) {
            ProgressBadge(completed: 2, total: 5)
            ProgressBadge(completed: 4, total: 5, showPercentage: true)
        }

        Text("Filter Badge")
            .font(.headline)

        FilterBadge(title: "High Priority", systemImage: "exclamationmark.triangle") { }

        Text("Achievement Badge")
            .font(.headline)

        AchievementBadge(
            title: "Week Warrior",
            subtitle: "7 day streak",
            systemImage: "star.fill",
            color: .yellow
        )
    }
    .spacingPadding(.spacing4)
}