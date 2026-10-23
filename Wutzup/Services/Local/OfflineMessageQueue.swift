import Foundation
import Combine

/// Durable, account-owned retries. The legacy unowned queue is retained but never
/// attributed to a newly signed-in account: its sender cannot be established safely.
@MainActor
final class OfflineMessageQueue: ObservableObject {
    static let shared = OfflineMessageQueue()
    @Published private(set) var pendingCount = 0
    @Published private(set) var pendingMessages: [QueuedMessage] = []
    private let defaults: UserDefaults
    private var actorID: String?
    private var generation = 0
    private var isSyncing = false

    struct QueuedMessage: Codable, Identifiable {
        let id: String
        let ownerID: String
        let conversationId: String
        let content: String
        let mediaUrl: String?
        let mediaType: String?
        let timestamp: Date
        var retryCount = 0
        var lastRetryAt: Date?
        var status = "pending"

        init(message: Message) {
            id = message.id
            ownerID = message.senderId
            conversationId = message.conversationId
            content = message.content
            mediaUrl = message.mediaUrl
            mediaType = message.mediaType
            timestamp = message.timestamp
        }
    }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func activate(userID: String?) {
        guard actorID != userID else { return }
        saveQueue()
        generation += 1
        actorID = userID
        pendingMessages = []
        if let key = storageKey, let data = defaults.data(forKey: key) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let messages = try? decoder.decode([QueuedMessage].self, from: data) {
                pendingMessages = messages.filter { $0.ownerID == userID }.map {
                    var message = $0
                    if message.status == "retrying" { message.status = "pending" }
                    return message
                }
            }
        }
        pendingCount = pendingMessages.count
    }

    func enqueue(_ message: Message) {
        guard message.senderId == actorID,
              !pendingMessages.contains(where: { $0.id == message.id && $0.conversationId == message.conversationId }) else { return }
        pendingMessages.append(QueuedMessage(message: message))
        persist()
    }

    func dequeue(_ messageId: String) {
        pendingMessages.removeAll { $0.id == messageId }
        persist()
    }

    func markAsFailed(_ messageId: String) {
        if let index = pendingMessages.firstIndex(where: { $0.id == messageId }) {
            pendingMessages[index].status = "failed"
            persist()
        }
    }

    func clearFailedMessages() {
        pendingMessages.removeAll { $0.status == "failed" }
        persist()
    }

    func syncPendingMessages(messageService: MessageService) async {
        guard !isSyncing, let actorID, !pendingMessages.isEmpty,
              NetworkMonitor.shared.isConnected else { return }
        isSyncing = true
        defer { isSyncing = false }
        let session = generation
        for var message in pendingMessages where message.status != "failed" {
            guard session == generation, self.actorID == actorID, !Task.isCancelled else { return }
            message.retryCount += 1
            message.lastRetryAt = Date()
            message.status = "retrying"
            if let index = pendingMessages.firstIndex(where: { $0.id == message.id && $0.conversationId == message.conversationId }) {
                pendingMessages[index] = message
            }
            persist()
            do {
                _ = try await messageService.sendMessage(
                    conversationId: message.conversationId, content: message.content,
                    mediaUrl: message.mediaUrl, mediaType: message.mediaType, messageId: message.id
                )
                guard session == generation, self.actorID == actorID else { return }
                pendingMessages.removeAll { $0.id == message.id && $0.conversationId == message.conversationId }
            } catch {
                guard session == generation, self.actorID == actorID else { return }
                if let index = pendingMessages.firstIndex(where: { $0.id == message.id && $0.conversationId == message.conversationId }) {
                    pendingMessages[index].status = message.retryCount >= 5 ? "failed" : "pending"
                }
            }
            persist()
            do { try await Task.sleep(nanoseconds: 200_000_000) } catch { return }
        }
    }

    private var storageKey: String? { actorID.map { "wutzup.offlineMessageQueue.v2." + $0 } }
    private func persist() { pendingCount = pendingMessages.count; saveQueue() }
    private func saveQueue() {
        guard let key = storageKey else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(pendingMessages) { defaults.set(data, forKey: key) }
    }

    var oldestPendingTimestamp: Date? { pendingMessages.filter { $0.status == "pending" }.map(\.timestamp).min() }
    var statusCounts: (pending: Int, retrying: Int, failed: Int) {
        (pendingMessages.filter { $0.status == "pending" }.count,
         pendingMessages.filter { $0.status == "retrying" }.count,
         pendingMessages.filter { $0.status == "failed" }.count)
    }
}
