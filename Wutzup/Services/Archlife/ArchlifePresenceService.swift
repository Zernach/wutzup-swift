import Foundation

final class ArchlifePresenceService: PresenceService {
    private var heartbeat: Task<Void, Never>?
    private func set(_ userId: String, status: String) async throws {
        try ArchlifeWutzupAPI.requireActor(userId)
        let _: WutzupOK = try await ArchlifeWutzupAPI.data("presence_set", ["status": status])
    }
    func setOnline(userId: String) async throws {
        heartbeat?.cancel()
        try await set(userId, status: "online")
        heartbeat = Task { [weak self] in
            while !Task.isCancelled && ArchlifeWutzupAPI.currentUserID == userId {
                do { try await Task.sleep(nanoseconds: 45_000_000_000) } catch { return }
                guard !Task.isCancelled else { return }
                try? await self?.set(userId, status: "online")
            }
        }
    }
    func setOffline(userId: String) async throws { heartbeat?.cancel(); heartbeat = nil; try await set(userId, status: "offline") }
    func setAway(userId: String) async throws { heartbeat?.cancel(); heartbeat = nil; try await set(userId, status: "away") }
    func observePresence(userId: String) -> AsyncStream<Presence> {
        WutzupPolling.stream { let result: WutzupPresenceResult = try await ArchlifeWutzupAPI.data("presence", ["id": userId]); return [result.presence] }
    }
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws {
        try ArchlifeWutzupAPI.requireActor(userId)
        let _: WutzupOK = try await ArchlifeWutzupAPI.data("typing_set", ["conversationId": conversationId, "isTyping": isTyping])
    }
    func observeTyping(conversationId: String) -> AsyncStream<[String: Bool]> {
        WutzupPolling.stream { let result: WutzupTypingResult = try await ArchlifeWutzupAPI.data("typing", ["conversationId": conversationId]); return [result.typing] }
    }
    deinit { heartbeat?.cancel() }
}
