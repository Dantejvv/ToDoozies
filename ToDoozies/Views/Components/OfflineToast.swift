//
//  OfflineToast.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

struct OfflineToast: View {
    let mode: OfflineMode
    let isVisible: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled

    var body: some View {
        if isVisible {
            VStack {
                toastContent
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Auto-dismiss after 5 seconds unless VoiceOver is active
                        if !isVoiceOverEnabled {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                onDismiss()
                            }
                        }
                    }

                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        }
    }

    private var toastContent: some View {
        HStack(spacing: CGFloat.spacing3) {
            // Status icon
            Image(systemName: mode.systemImage)
                .foregroundColor(mode.color)
                .font(.body)
                .symbolEffect(.pulse, isActive: mode == .reconnecting && !reduceMotion)

            // Message text
            VStack(alignment: .leading, spacing: 2) {
                Text(toastTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let subtitle = toastSubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Dismiss notification")
        }
        .padding(CGFloat.spacing4)
        .background(toastBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, CGFloat.spacing4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("This notification will auto-dismiss in 5 seconds, or double tap dismiss button")
        .accessibilityAction(named: "Dismiss") {
            onDismiss()
        }
    }

    // MARK: - Content Helpers

    private var toastTitle: String {
        switch mode {
        case .online:
            return "Back Online"
        case .offline:
            return "No Internet Connection"
        case .reconnecting:
            return "Reconnecting..."
        }
    }

    private var toastSubtitle: String? {
        switch mode {
        case .online:
            return "Syncing your changes"
        case .offline:
            return "Changes saved locally"
        case .reconnecting:
            return "Attempting to reconnect"
        }
    }

    private var toastBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(mode.color.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = toastTitle
        if let subtitle = toastSubtitle {
            label += ". \(subtitle)"
        }
        return label
    }
}

// MARK: - Toast Manager

@MainActor
class ToastManager: ObservableObject {
    @Published var currentToast: ToastItem?

    func show(_ toast: ToastItem) {
        currentToast = toast

        // Auto-dismiss after duration if not persistent
        if !toast.isPersistent {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                if self.currentToast?.id == toast.id {
                    self.dismiss()
                }
            }
        }
    }

    func dismiss() {
        currentToast = nil
    }
}

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let mode: OfflineMode
    let duration: TimeInterval
    let isPersistent: Bool

    init(mode: OfflineMode, duration: TimeInterval = 5.0, isPersistent: Bool = false) {
        self.mode = mode
        self.duration = duration
        self.isPersistent = isPersistent
    }
}

// MARK: - Toast View Modifier

struct ToastModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager()
    @Binding var toast: ToastItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let currentToast = toastManager.currentToast {
                    OfflineToast(
                        mode: currentToast.mode,
                        isVisible: true,
                        onDismiss: {
                            toastManager.dismiss()
                        }
                    )
                    .zIndex(1000)
                }
            }
            .onChange(of: toast) { _, newToast in
                if let newToast = newToast {
                    toastManager.show(newToast)
                    // Clear the binding after showing
                    self.toast = nil
                }
            }
    }
}

extension View {
    func toast(_ toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Preview

#Preview("Offline Toast") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
            .padding()

        Spacer()
    }
    .overlay(alignment: .top) {
        OfflineToast(
            mode: .offline,
            isVisible: true,
            onDismiss: {}
        )
        .padding(.top, 60)
    }
}

#Preview("Reconnecting Toast") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
            .padding()

        Spacer()
    }
    .overlay(alignment: .top) {
        OfflineToast(
            mode: .reconnecting,
            isVisible: true,
            onDismiss: {}
        )
        .padding(.top, 60)
    }
}

#Preview("Online Toast") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
            .padding()

        Spacer()
    }
    .overlay(alignment: .top) {
        OfflineToast(
            mode: .online,
            isVisible: true,
            onDismiss: {}
        )
        .padding(.top, 60)
    }
}