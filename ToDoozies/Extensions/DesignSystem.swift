//
//  DesignSystem.swift
//  ToDoozies
//
//  Created by Claude Code on 9/15/25.
//

import SwiftUI

// MARK: - Spacing System (8pt Grid)

extension CGFloat {
    /// 8pt spacing grid system
    /// Use these values for consistent spacing throughout the app
    static let spacing1: CGFloat = 4    // 0.5x
    static let spacing2: CGFloat = 8    // 1x (base unit)
    static let spacing3: CGFloat = 12   // 1.5x
    static let spacing4: CGFloat = 16   // 2x
    static let spacing5: CGFloat = 20   // 2.5x
    static let spacing6: CGFloat = 24   // 3x
    static let spacing7: CGFloat = 28   // 3.5x
    static let spacing8: CGFloat = 32   // 4x
    static let spacing10: CGFloat = 40  // 5x
    static let spacing12: CGFloat = 48  // 6x
    static let spacing16: CGFloat = 64  // 8x
    static let spacing20: CGFloat = 80  // 10x
    static let spacing24: CGFloat = 96  // 12x
}

extension EdgeInsets {
    /// Spacing-based edge insets
    static let spacing2 = EdgeInsets(top: .spacing2, leading: .spacing2, bottom: .spacing2, trailing: .spacing2)
    static let spacing4 = EdgeInsets(top: .spacing4, leading: .spacing4, bottom: .spacing4, trailing: .spacing4)
    static let spacing6 = EdgeInsets(top: .spacing6, leading: .spacing6, bottom: .spacing6, trailing: .spacing6)

    /// Horizontal padding only
    static let horizontalSpacing4 = EdgeInsets(top: 0, leading: .spacing4, bottom: 0, trailing: .spacing4)
    static let horizontalSpacing6 = EdgeInsets(top: 0, leading: .spacing6, bottom: 0, trailing: .spacing6)

    /// Vertical padding only
    static let verticalSpacing2 = EdgeInsets(top: .spacing2, leading: 0, bottom: .spacing2, trailing: 0)
    static let verticalSpacing4 = EdgeInsets(top: .spacing4, leading: 0, bottom: .spacing4, trailing: 0)
}

// MARK: - Design System Components

struct DesignSystem {

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = .spacing2      // 8pt
        static let medium: CGFloat = .spacing3     // 12pt
        static let large: CGFloat = .spacing4      // 16pt
        static let extraLarge: CGFloat = .spacing6 // 24pt
    }

    // MARK: - Shadow

    enum Shadow {
        static let small = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )

        static let medium = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )

        static let large = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let small: CGFloat = .spacing4      // 16pt
        static let medium: CGFloat = .spacing6     // 24pt
        static let large: CGFloat = .spacing8      // 32pt
        static let extraLarge: CGFloat = .spacing10 // 40pt
    }

    // MARK: - Button Heights

    enum ButtonHeight {
        static let small: CGFloat = .spacing8      // 32pt
        static let medium: CGFloat = .spacing10    // 40pt
        static let large: CGFloat = .spacing12     // 48pt
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions for Design System

extension View {
    /// Apply consistent card styling with shadow
    func cardStyle(_ shadow: ShadowStyle = DesignSystem.Shadow.medium) -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply small card styling
    func smallCardStyle() -> some View {
        self
            .background(Color(.secondarySystemBackground))
            .cornerRadius(DesignSystem.CornerRadius.small)
    }

    /// Apply large card styling with prominent shadow
    func prominentCardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(color: DesignSystem.Shadow.large.color,
                   radius: DesignSystem.Shadow.large.radius,
                   x: DesignSystem.Shadow.large.x,
                   y: DesignSystem.Shadow.large.y)
    }

    /// Apply consistent spacing padding
    func spacingPadding(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }

    /// Apply horizontal spacing padding
    func horizontalSpacingPadding(_ spacing: CGFloat) -> some View {
        self.padding(.horizontal, spacing)
    }

    /// Apply vertical spacing padding
    func verticalSpacingPadding(_ spacing: CGFloat) -> some View {
        self.padding(.vertical, spacing)
    }
}