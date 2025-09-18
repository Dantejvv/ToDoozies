//
//  CloudKitSyncService.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/15/25.
//

import Foundation
import CloudKit
import SwiftData
import Observation

@MainActor
final class CloudKitSyncService: ObservableObject {
    private let container: CKContainer
    private let appState: AppState
    private var syncTimer: Timer?

    init(appState: AppState, containerIdentifier: String = "iCloud.dante.ToDoozies") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.appState = appState

        setupNotifications()
        checkAccountStatus()
    }

    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func startMonitoring() {
        checkAccountStatus()
        startSyncTimer()
    }

    func stopMonitoring() {
        stopSyncTimer()
        appState.setSyncStatus(.disabled)
    }

    func forcSync() async {
        await performSync()
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        // Listen for CloudKit account changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accountChanged),
            name: .CKAccountChanged,
            object: nil
        )

        // Listen for remote data changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteDataChanged),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    @objc private func accountChanged() {
        ConcurrentTask { @MainActor in
            checkAccountStatus()
        }
    }

    @objc private func remoteDataChanged() {
        ConcurrentTask { @MainActor in
            await handleRemoteDataChange()
        }
    }

    private func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            ConcurrentTask { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.handleCloudKitError(error)
                    return
                }

                switch status {
                case .couldNotDetermine:
                    self.appState.setSyncStatus(.unknown)
                    self.appState.setSyncEnabled(false)
                    print("CloudKit: Could not determine account status. Using local storage only.")

                case .available:
                    self.appState.setSyncEnabled(true)
                    print("CloudKit: iCloud account available. Syncing enabled.")
                    await self.performSync()

                case .restricted:
                    self.appState.setSyncEnabled(false)
                    self.appState.setSyncStatus(.disabled)
                    print("CloudKit: iCloud account is restricted. Using local storage only.")

                case .noAccount:
                    self.appState.setSyncEnabled(false)
                    self.appState.setSyncStatus(.disabled)
                    print("CloudKit: No iCloud account available. Using local storage only.")

                case .temporarilyUnavailable:
                    self.appState.setSyncStatus(.failed("Account temporarily unavailable"))
                    self.appState.setSyncEnabled(false)

                @unknown default:
                    self.appState.setSyncStatus(.unknown)
                    self.appState.setSyncEnabled(false)
                }
            }
        }
    }

    private func performSync() async {
        guard appState.isSyncEnabled else { return }

        appState.setSyncStatus(.syncing)

        do {
            // Check for any pending operations
            try await checkSyncStatus()
            appState.setSyncStatus(.synced)

        } catch {
            handleCloudKitError(error)
        }
    }

    private func checkSyncStatus() async throws {
        // This is a simplified sync check
        // In a real implementation, you would:
        // 1. Check for any pending CloudKit operations
        // 2. Verify data consistency
        // 3. Handle any sync conflicts

        // For now, we'll just simulate a sync delay
        try await ConcurrentTask.sleep(nanoseconds: 1_000_000_000) // 1 second
    }

    private func handleRemoteDataChange() async {
        // Handle incoming CloudKit changes
        await performSync()
    }

    private func handleCloudKitError(_ error: Error) {
        let ckError = error as? CKError

        switch ckError?.code {
        case .notAuthenticated:
            appState.setError(.cloudKitAccountError)
            appState.setSyncStatus(.failed("Authentication failed"))

        case .quotaExceeded:
            appState.setError(.cloudKitQuotaExceeded)
            appState.setSyncStatus(.failed("Quota exceeded"))

        case .networkUnavailable, .networkFailure:
            appState.setError(.cloudKitNetworkUnavailable)
            appState.setSyncStatus(.failed("Network unavailable"))

        case .serviceUnavailable:
            appState.setSyncStatus(.failed("CloudKit service unavailable"))

        case .requestRateLimited:
            appState.setSyncStatus(.failed("Rate limited"))
            // Retry after a delay
            scheduleRetry()

        default:
            let message = ckError?.localizedDescription ?? error.localizedDescription
            appState.setError(.cloudKitUnknownError(message))
            appState.setSyncStatus(.failed(message))
        }
    }

    private func scheduleRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            ConcurrentTask { @MainActor [weak self] in
                await self?.performSync()
            }
        }
    }

    private func startSyncTimer() {
        stopSyncTimer()

        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            ConcurrentTask { @MainActor [weak self] in
                await self?.performSync()
            }
        }
    }

    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
}

// MARK: - Extensions

extension CloudKitSyncService {
    var syncStatusDescription: String {
        appState.syncStatusMessage
    }

    var isSyncAvailable: Bool {
        appState.isSyncEnabled
    }
}