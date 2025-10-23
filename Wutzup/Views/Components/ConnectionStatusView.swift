//
//  ConnectionStatusView.swift
//  Wutzup
//
//  Connection status banner that appears when offline or reconnecting
//

import SwiftUI

struct ConnectionStatusView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @ObservedObject var offlineQueue = OfflineMessageQueue.shared
    
    @State private var showBanner = false
    @State private var isSyncing = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showBanner {
                banner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showBanner)
        .onChange(of: networkMonitor.isConnected) { _, newValue in
            withAnimation {
                showBanner = !newValue || offlineQueue.pendingCount > 0
            }
        }
        .onChange(of: offlineQueue.pendingCount) { _, newValue in
            withAnimation {
                showBanner = !networkMonitor.isConnected || newValue > 0
            }
        }
        .onAppear {
            showBanner = !networkMonitor.isConnected || offlineQueue.pendingCount > 0
        }
    }
    
    @ViewBuilder
    private var banner: some View {
        if !networkMonitor.isConnected {
            offlineBanner
        } else if offlineQueue.pendingCount > 0 {
            syncingBanner
        }
    }
    
    private var offlineBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No Connection")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                if let downtime = networkMonitor.currentDowntimeDuration, downtime > 30 {
                    Text("Offline for \(formatDuration(downtime))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Messages will send when online")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            if offlineQueue.pendingCount > 0 {
                Text("\(offlineQueue.pendingCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.gradient)
    }
    
    private var syncingBanner: some View {
        HStack(spacing: 12) {
            if isSyncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isSyncing ? "Syncing Messages..." : "Ready to Sync")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                let statusCounts = offlineQueue.statusCounts
                Text("\(statusCounts.pending) pending • \(statusCounts.failed) failed")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if !isSyncing {
                Button(action: syncNow) {
                    Text("Sync")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.gradient)
    }
    
    private func syncNow() {
        guard !isSyncing else { return }
        
        isSyncing = true
        
        Task {
            // This will be called from ConversationViewModel
            // For now, just show the syncing state
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSyncing = false
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return "\(Int(duration))s"
        } else if duration < 3600 {
            return "\(Int(duration / 60))m"
        } else {
            return "\(Int(duration / 3600))h"
        }
    }
}

// MARK: - Pending Messages Indicator

struct PendingMessagesIndicator: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 11, weight: .semibold))
            
            Text("\(count) pending")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Connection Quality Indicator

struct ConnectionQualityIndicator: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionColor)
                .frame(width: 6, height: 6)
            
            Text(connectionText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var connectionColor: Color {
        if !networkMonitor.isConnected {
            return .red
        } else if networkMonitor.isConstrained {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var connectionText: String {
        if !networkMonitor.isConnected {
            return "Offline"
        } else if networkMonitor.isConstrained {
            return "Limited"
        } else {
            return networkMonitor.connectionType.rawValue
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ConnectionStatusView()
        
        Spacer()
        
        HStack {
            PendingMessagesIndicator(count: 3)
            ConnectionQualityIndicator()
        }
        .padding()
    }
}

