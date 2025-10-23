//
//  NetworkMonitor.swift
//  Wutzup
//
//  Network connectivity monitoring service
//  Tracks online/offline status and provides reactive updates
//

import Foundation
import Network
import Combine

/// Monitors network connectivity and provides real-time status updates
@MainActor
class NetworkMonitor: ObservableObject {
    /// Shared singleton instance
    static let shared = NetworkMonitor()
    
    /// Current connection status
    @Published private(set) var isConnected: Bool = true
    
    /// Connection type (wifi, cellular, ethernet, none)
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    /// Whether the connection is expensive (cellular data)
    @Published private(set) var isExpensive: Bool = false
    
    /// Whether the connection is constrained (low data mode)
    @Published private(set) var isConstrained: Bool = false
    
    /// Last disconnection time (for calculating downtime)
    @Published private(set) var lastDisconnectionTime: Date?
    
    /// Last connection time (for tracking reconnections)
    @Published private(set) var lastConnectionTime: Date?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.wutzup.networkmonitor")
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case other = "Other"
        case unknown = "Unknown"
        case none = "No Connection"
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// Start monitoring network status
    func startMonitoring() {
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let wasConnected = self.isConnected
                let newConnectionStatus = path.status == .satisfied
                
                // Update connection status
                self.isConnected = newConnectionStatus
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else if path.status == .satisfied {
                    self.connectionType = .other
                } else {
                    self.connectionType = .none
                }
                
                // Track state changes
                if !wasConnected && newConnectionStatus {
                    // Reconnected
                    self.lastConnectionTime = Date()
                    let downtime = self.lastDisconnectionTime.map { Date().timeIntervalSince($0) }
                    
                    if let downtime = downtime {
                    }
                    
                    // Post reconnection notification
                    NotificationCenter.default.post(
                        name: .networkDidReconnect,
                        object: nil,
                        userInfo: ["downtime": downtime ?? 0]
                    )
                    
                } else if wasConnected && !newConnectionStatus {
                    // Disconnected
                    self.lastDisconnectionTime = Date()
                    
                    
                    // Post disconnection notification
                    NotificationCenter.default.post(name: .networkDidDisconnect, object: nil)
                    
                } else if newConnectionStatus {
                    // Still connected, but type may have changed
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// Stop monitoring network status
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Get a human-readable status string
    var statusDescription: String {
        if !isConnected {
            return "No Connection"
        }
        
        var desc = connectionType.rawValue
        if isExpensive {
            desc += " (Cellular)"
        }
        if isConstrained {
            desc += " (Low Data Mode)"
        }
        return desc
    }
    
    /// Check if connection quality is good for syncing
    var canSyncReliably: Bool {
        return isConnected && !isConstrained
    }
    
    /// Get downtime duration in seconds (if currently disconnected)
    var currentDowntimeDuration: TimeInterval? {
        guard !isConnected, let lastDisconnectionTime = lastDisconnectionTime else {
            return nil
        }
        return Date().timeIntervalSince(lastDisconnectionTime)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkDidReconnect = Notification.Name("networkDidReconnect")
    static let networkDidDisconnect = Notification.Name("networkDidDisconnect")
    static let networkConnectionTypeChanged = Notification.Name("networkConnectionTypeChanged")
}

