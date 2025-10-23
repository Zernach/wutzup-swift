//
//  OfflineMessageQueue.swift
//  Wutzup
//
//  Manages offline message queue with persistence and automatic retry
//

import Foundation
import SwiftData
import Combine

/// Manages messages that failed to send due to network issues
@MainActor
class OfflineMessageQueue: ObservableObject {
    /// Shared singleton instance
    static let shared = OfflineMessageQueue()
    
    /// Published count of pending messages
    @Published private(set) var pendingCount: Int = 0
    
    /// Published list of pending messages (for UI display)
    @Published private(set) var pendingMessages: [QueuedMessage] = []
    
    private let queue = DispatchQueue(label: "com.wutzup.offlinequeue", qos: .userInitiated)
    private var isSyncing = false
    
    struct QueuedMessage: Codable, Identifiable {
        let id: String
        let conversationId: String
        let content: String
        let mediaUrl: String?
        let mediaType: String?
        let timestamp: Date
        var retryCount: Int
        var lastRetryAt: Date?
        var status: String // "pending", "retrying", "failed"
        
        init(message: Message, retryCount: Int = 0) {
            self.id = message.id
            self.conversationId = message.conversationId
            self.content = message.content
            self.mediaUrl = message.mediaUrl
            self.mediaType = message.mediaType
            self.timestamp = message.timestamp
            self.retryCount = retryCount
            self.status = "pending"
        }
    }
    
    private init() {
        loadQueue()
    }
    
    // MARK: - Queue Management
    
    /// Add a message to the offline queue
    func enqueue(_ message: Message) {
        let queuedMessage = QueuedMessage(message: message)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Check if message already exists
                guard !self.pendingMessages.contains(where: { $0.id == message.id }) else {
                    return
                }
                
                self.pendingMessages.append(queuedMessage)
                self.pendingCount = self.pendingMessages.count
                self.saveQueue()
                
            }
        }
    }
    
    /// Remove a message from the queue (after successful send)
    func dequeue(_ messageId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.pendingMessages.removeAll { $0.id == messageId }
                self.pendingCount = self.pendingMessages.count
                self.saveQueue()
                
            }
        }
    }
    
    /// Mark a message as failed after max retries
    func markAsFailed(_ messageId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let index = self.pendingMessages.firstIndex(where: { $0.id == messageId }) {
                    self.pendingMessages[index].status = "failed"
                    self.saveQueue()
                    
                }
            }
        }
    }
    
    /// Clear all failed messages
    func clearFailedMessages() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                let failedCount = self.pendingMessages.filter { $0.status == "failed" }.count
                self.pendingMessages.removeAll { $0.status == "failed" }
                self.pendingCount = self.pendingMessages.count
                self.saveQueue()
                
            }
        }
    }
    
    // MARK: - Sync
    
    /// Attempt to sync all pending messages
    func syncPendingMessages(messageService: MessageService) async {
        guard !isSyncing else {
            return
        }
        
        guard !pendingMessages.isEmpty else {
            return
        }
        
        guard NetworkMonitor.shared.isConnected else {
            return
        }
        
        isSyncing = true
        
        let startTime = Date()
        
        var successCount = 0
        var failedCount = 0
        
        // Create a copy to iterate over
        let messagesToSync = pendingMessages.filter { $0.status != "failed" }
        
        for var queuedMessage in messagesToSync {
            // Update retry info
            queuedMessage.retryCount += 1
            queuedMessage.lastRetryAt = Date()
            queuedMessage.status = "retrying"
            
            // Update in array
            if let index = pendingMessages.firstIndex(where: { $0.id == queuedMessage.id }) {
                pendingMessages[index] = queuedMessage
            }
            
            do {
                
                _ = try await messageService.sendMessage(
                    conversationId: queuedMessage.conversationId,
                    content: queuedMessage.content,
                    mediaUrl: queuedMessage.mediaUrl,
                    mediaType: queuedMessage.mediaType,
                    messageId: queuedMessage.id
                )
                
                // Success - remove from queue
                dequeue(queuedMessage.id)
                successCount += 1
                
                
            } catch {
                
                // Check if we've exceeded max retries
                if queuedMessage.retryCount >= 5 {
                    markAsFailed(queuedMessage.id)
                } else {
                    // Update status back to pending
                    if let index = pendingMessages.firstIndex(where: { $0.id == queuedMessage.id }) {
                        pendingMessages[index].status = "pending"
                    }
                }
                
                failedCount += 1
            }
            
            // Small delay between retries to avoid overwhelming the server
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        
        saveQueue()
        isSyncing = false
    }
    
    // MARK: - Persistence
    
    private func saveQueue() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(pendingMessages) {
            UserDefaults.standard.set(data, forKey: "offlineMessageQueue")
        }
    }
    
    private func loadQueue() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let data = UserDefaults.standard.data(forKey: "offlineMessageQueue"),
           let messages = try? decoder.decode([QueuedMessage].self, from: data) {
            pendingMessages = messages
            pendingCount = messages.count
        }
    }
    
    // MARK: - Queue Info
    
    /// Get the oldest pending message timestamp
    var oldestPendingTimestamp: Date? {
        pendingMessages.filter { $0.status == "pending" }.map { $0.timestamp }.min()
    }
    
    /// Get count of messages by status
    var statusCounts: (pending: Int, retrying: Int, failed: Int) {
        let pending = pendingMessages.filter { $0.status == "pending" }.count
        let retrying = pendingMessages.filter { $0.status == "retrying" }.count
        let failed = pendingMessages.filter { $0.status == "failed" }.count
        return (pending, retrying, failed)
    }
}

