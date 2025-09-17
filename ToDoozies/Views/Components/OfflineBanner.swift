//
//  OfflineBanner.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct OfflineBanner: View {
    let mode: OfflineMode
    let pendingChanges: Int
    let connectionType: String?
    let onRetry: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: CGFloat.spacing3) {
            // Status icon with subtle animation
            Image(systemName: mode.systemImage)
                .foregroundColor(mode.color)
                .font(.caption)
                .symbolEffect(.pulse, isActive: mode == .reconnecting && !reduceMotion)

            // Status text and details
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.message)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: CGFloat.spacing1) {
                    // Connection type (when available)
                    if let connectionType = connectionType, mode == .online {
                        Text(connectionType)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Pending changes indicator
                    if pendingChanges > 0 {
                        if connectionType != nil && mode == .online {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Text("\(pendingChanges) pending")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Retry button for offline/reconnecting states
            if mode == .offline || mode == .reconnecting {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
                .disabled(mode == .reconnecting)
            }
        }
        .padding(.horizontal, CGFloat.spacing4)
        .padding(.vertical, CGFloat.spacing3)
        .background(bannerBackground)
        .overlay(bannerBorder)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(named: "Retry Connection") {
            if mode == .offline || mode == .reconnecting {
                onRetry()
            }
        }
    }

    // MARK: - UI Helpers

    private var bannerBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColorForMode)
    }

    private var bannerBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(mode.color.opacity(0.3), lineWidth: 1)
    }

    private var backgroundColorForMode: Color {
        switch mode {
        case .online:
            return Color(.secondarySystemBackground)
        case .offline:
            return Color.orange.opacity(0.1)
        case .reconnecting:
            return Color.yellow.opacity(0.1)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch mode {
        case .online:
            return "Network status: Online"
        case .offline:
            return "Network status: Offline"
        case .reconnecting:
            return "Network status: Reconnecting"
        }
    }

    private var accessibilityValue: String {
        var value = ""

        if let connectionType = connectionType, mode == .online {
            value += "Connected via \(connectionType). "
        }

        if pendingChanges > 0 {
            value += "\(pendingChanges) changes pending sync. "
        }

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var accessibilityHint: String {
        switch mode {
        case .online:
            return pendingChanges > 0 ? "Changes will sync automatically" : "All changes are synced"
        case .offline:
            return "Double tap retry to attempt reconnection. Changes are saved locally"
        case .reconnecting:
            return "Attempting to reconnect. Please wait"
        }
    }
}

// MARK: - Preview

#Preview("Online") {
    VStack(spacing: .spacing4) {
        OfflineBanner(
            mode: .online,
            pendingChanges: 0,
            connectionType: "WiFi",
            onRetry: {}
        )

        OfflineBanner(
            mode: .online,
            pendingChanges: 3,
            connectionType: "Cellular",
            onRetry: {}
        )
    }
    .padding()
}

#Preview("Offline") {
    VStack(spacing: .spacing4) {
        OfflineBanner(
            mode: .offline,
            pendingChanges: 5,
            connectionType: nil,
            onRetry: {}
        )

        OfflineBanner(
            mode: .reconnecting,
            pendingChanges: 2,
            connectionType: nil,
            onRetry: {}
        )
    }
    .padding()
}