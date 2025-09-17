//
//  NetworkMonitor.swift
//  ToDoozies
//
//  Created by Claude Code on 9/16/25.
//

import Network
import Foundation
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false

    init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateConnectionStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        connectionType = path.availableInterfaces.first?.type
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Log connection changes for debugging
        print("Network status changed: isConnected=\(isConnected), type=\(connectionType?.debugDescription ?? "unknown")")
    }

    nonisolated func stopMonitoring() {
        monitor.cancel()
    }

    var connectionDescription: String {
        guard isConnected else { return "No Connection" }

        switch connectionType {
        case .wifi:
            return isExpensive ? "WiFi (Limited)" : "WiFi"
        case .cellular:
            return isExpensive ? "Cellular (Limited)" : "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        case .none:
            return "Connected"
        @unknown default:
            return "Connected"
        }
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - NWInterface.InterfaceType Extension

extension NWInterface.InterfaceType {
    var debugDescription: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .wiredEthernet: return "ethernet"
        case .loopback: return "loopback"
        case .other: return "other"
        @unknown default: return "unknown"
        }
    }
}