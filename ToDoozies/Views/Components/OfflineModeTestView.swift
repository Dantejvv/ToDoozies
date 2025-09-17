//
//  OfflineModeTestView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import SwiftUI

#if DEBUG
struct OfflineModeTestView: View {
    @State private var currentMode: OfflineMode = .online
    @State private var pendingChanges: Int = 0
    @State private var showToast: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Offline Mode UI Testing")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    Text("Current Mode: \(currentMode.message)")
                        .font(.headline)

                    HStack {
                        Button("Online") {
                            currentMode = .online
                            pendingChanges = 0
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Offline") {
                            currentMode = .offline
                            pendingChanges = 5
                        }
                        .buttonStyle(.bordered)

                        Button("Reconnecting") {
                            currentMode = .reconnecting
                            pendingChanges = 3
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Show Toast") {
                        showToast = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Add Pending Change") {
                        pendingChanges += 1
                    }
                    .buttonStyle(.bordered)

                    Button("Clear Pending") {
                        pendingChanges = 0
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // Test components
                VStack(spacing: 16) {
                    Text("Banner Component:")
                        .font(.headline)

                    OfflineBanner(
                        mode: currentMode,
                        pendingChanges: pendingChanges,
                        connectionType: currentMode == .online ? "WiFi" : nil,
                        onRetry: {
                            print("Retry tapped")
                        }
                    )

                    Text("Sync Status Component:")
                        .font(.headline)

                    SyncStatusView(
                        status: .syncing,
                        message: "Syncing your changes...",
                        offlineMode: currentMode,
                        pendingChanges: pendingChanges,
                        connectionType: currentMode == .online ? "WiFi" : nil,
                        onRetry: {
                            print("Sync retry tapped")
                        }
                    )
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Offline UI Test")
            .overlay(alignment: .top) {
                if showToast {
                    OfflineToast(
                        mode: currentMode,
                        isVisible: showToast,
                        onDismiss: {
                            showToast = false
                        }
                    )
                    .padding(.top, 60)
                }
            }
        }
    }
}

#Preview {
    OfflineModeTestView()
}
#endif