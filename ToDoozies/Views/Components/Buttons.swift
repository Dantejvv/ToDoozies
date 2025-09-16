//
//  Buttons.swift
//  ToDoozies
//
//  Created by Claude Code on 9/15/25.
//

import SwiftUI

// MARK: - Primary Action Button

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool

    init(
        _ title: String,
        systemImage: String? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing2) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                }

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(height: DesignSystem.ButtonHeight.medium)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color.accentColor : Color.gray)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "Double tap to \(title.lowercased())")
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let isEnabled: Bool

    init(
        _ title: String,
        systemImage: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing2) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                }

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.accentColor)
            .frame(height: DesignSystem.ButtonHeight.medium)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

// MARK: - Compact Button

struct CompactButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let style: CompactButtonStyle

    enum CompactButtonStyle {
        case primary
        case secondary
        case destructive
    }

    init(
        _ title: String,
        systemImage: String? = nil,
        style: CompactButtonStyle = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing1) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .verticalSpacingPadding(.spacing1)
            .horizontalSpacingPadding(.spacing2)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .accentColor
        case .destructive:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .accentColor
        case .secondary:
            return Color.accentColor.opacity(0.1)
        case .destructive:
            return Color.red.opacity(0.1)
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let systemImage: String
    let action: () -> Void
    let style: IconButtonStyle
    let size: IconButtonSize
    let accessibilityLabel: String

    enum IconButtonStyle {
        case plain
        case filled
        case outlined
    }

    enum IconButtonSize {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return DesignSystem.IconSize.small
            case .medium: return DesignSystem.IconSize.medium
            case .large: return DesignSystem.IconSize.large
            }
        }

        var frameSize: CGFloat {
            switch self {
            case .small: return DesignSystem.ButtonHeight.small
            case .medium: return DesignSystem.ButtonHeight.medium
            case .large: return DesignSystem.ButtonHeight.large
            }
        }
    }

    init(
        systemImage: String,
        style: IconButtonStyle = .plain,
        size: IconButtonSize = .medium,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.style = style
        self.size = size
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size.frameSize, height: size.frameSize)
                .background(backgroundColor)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .overlay(overlayContent)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to activate")
    }

    private var foregroundColor: Color {
        switch style {
        case .plain:
            return .primary
        case .filled:
            return .white
        case .outlined:
            return .accentColor
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .plain:
            return .clear
        case .filled:
            return .accentColor
        case .outlined:
            return .clear
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Completion Button

struct CompletionButton: View {
    let isCompleted: Bool
    let action: () -> Void
    let style: CompletionButtonStyle
    let accessibilityLabel: String

    enum CompletionButtonStyle {
        case task
        case habit
    }

    init(
        isCompleted: Bool,
        style: CompletionButtonStyle = .task,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.isCompleted = isCompleted
        self.style = style
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            iconContent
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: DesignSystem.IconSize.large, height: DesignSystem.IconSize.large)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint(isCompleted ? "Double tap to mark incomplete" : "Double tap to mark complete")
    }

    @ViewBuilder
    private var iconContent: some View {
        switch style {
        case .task:
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")

        case .habit:
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 28, height: 28)

                Image(systemName: isCompleted ? "flame.fill" : "flame")
                    .font(.caption)
                    .foregroundColor(isCompleted ? .white : .gray)
            }
        }
    }

    private var iconColor: Color {
        switch style {
        case .task:
            return isCompleted ? .green : .gray
        case .habit:
            return .clear // Color is handled in iconContent for habit style
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let systemImage: String
    let action: () -> Void
    let accessibilityLabel: String

    init(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: DesignSystem.IconSize.medium, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .cornerRadius(28)
                .shadow(color: DesignSystem.Shadow.medium.color,
                       radius: DesignSystem.Shadow.medium.radius,
                       x: DesignSystem.Shadow.medium.x,
                       y: DesignSystem.Shadow.medium.y)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to activate")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: .spacing4) {
        PrimaryButton("Save Task", systemImage: "checkmark") { }

        SecondaryButton("Cancel", systemImage: "xmark") { }

        HStack(spacing: .spacing4) {
            CompactButton("Edit", systemImage: "pencil", style: .secondary) { }
            CompactButton("Delete", systemImage: "trash", style: .destructive) { }
        }

        HStack(spacing: .spacing4) {
            IconButton(
                systemImage: "plus",
                style: .filled,
                size: .medium,
                accessibilityLabel: "Add"
            ) { }

            IconButton(
                systemImage: "ellipsis",
                style: .outlined,
                size: .medium,
                accessibilityLabel: "More options"
            ) { }

            IconButton(
                systemImage: "gear",
                style: .plain,
                size: .medium,
                accessibilityLabel: "Settings"
            ) { }
        }

        HStack(spacing: .spacing4) {
            CompletionButton(
                isCompleted: false,
                style: .task,
                accessibilityLabel: "Task completion"
            ) { }

            CompletionButton(
                isCompleted: true,
                style: .task,
                accessibilityLabel: "Task completion"
            ) { }

            CompletionButton(
                isCompleted: false,
                style: .habit,
                accessibilityLabel: "Habit completion"
            ) { }

            CompletionButton(
                isCompleted: true,
                style: .habit,
                accessibilityLabel: "Habit completion"
            ) { }
        }

        FloatingActionButton(
            systemImage: "plus",
            accessibilityLabel: "Add new task"
        ) { }
    }
    .spacingPadding(.spacing4)
}