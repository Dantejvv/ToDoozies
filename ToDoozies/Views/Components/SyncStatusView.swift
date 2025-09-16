//
//  SyncStatusView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import SwiftUI

struct SyncStatusView: View {
    let status: SyncStatus
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .foregroundColor(iconColor)

            // Status message
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            // Dismiss button for error states
            if case .failed = status {
                Button(action: {
                    // This could be handled by a closure passed in
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .unknown:
            Image(systemName: "questionmark.circle")

        case .syncing:
            ProgressView()
                .scaleEffect(0.8)

        case .synced:
            Image(systemName: "checkmark.circle.fill")

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")

        case .disabled:
            Image(systemName: "icloud.slash")
        }
    }

    private var iconColor: Color {
        switch status {
        case .unknown:
            return .orange
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .failed:
            return .red
        case .disabled:
            return .gray
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .unknown:
            return Color.orange.opacity(0.1)
        case .syncing:
            return Color.blue.opacity(0.1)
        case .synced:
            return Color.green.opacity(0.1)
        case .failed:
            return Color.red.opacity(0.1)
        case .disabled:
            return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Interactive Sync Status View

struct InteractiveSyncStatusView: View {
    let status: SyncStatus
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .foregroundColor(iconColor)

            // Status message
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                if case .failed = status {
                    Button("Retry", action: onRetry)
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .unknown:
            Image(systemName: "questionmark.circle")

        case .syncing:
            ProgressView()
                .scaleEffect(0.8)

        case .synced:
            Image(systemName: "checkmark.circle.fill")

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")

        case .disabled:
            Image(systemName: "icloud.slash")
        }
    }

    private var statusTitle: String {
        switch status {
        case .unknown:
            return "Sync Status Unknown"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .failed:
            return "Sync Failed"
        case .disabled:
            return "Sync Disabled"
        }
    }

    private var iconColor: Color {
        switch status {
        case .unknown:
            return .orange
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .failed:
            return .red
        case .disabled:
            return .gray
        }
    }

    private var backgroundColor: Color {
        Color(.systemBackground)
    }
}

// MARK: - Previews

#Preview("Sync Status View - Syncing") {
    VStack(spacing: 20) {
        SyncStatusView(
            status: .syncing,
            message: "Syncing your data..."
        )

        SyncStatusView(
            status: .synced,
            message: "Last synced 2 minutes ago"
        )

        SyncStatusView(
            status: .failed("Network error"),
            message: "Failed to sync: Network connection unavailable"
        )

        InteractiveSyncStatusView(
            status: .failed("Network error"),
            message: "Network connection is unavailable. Data will sync when connection is restored.",
            onRetry: {},
            onDismiss: {}
        )
    }
    .padding()
}