import Foundation

final class ArchlifeMessageService: MessageService {
    private let languageDetectionService: LanguageDetectionService
    init(languageDetectionService: LanguageDetectionService = NaturalLanguageDetectionService()) { self.languageDetectionService = languageDetectionService }
    private func owned(_ messages: [Message]) -> [Message] {
        messages.map { value in var message = value; message.isFromCurrentUser = message.senderId == ArchlifeWutzupAPI.currentUserID; return message }
    }
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?, messageId: String?) async throws -> Message {
        guard let actor = ArchlifeWutzupAPI.currentUserID else { throw WutzupAPIError(status: 401, code: "identity_changed") }
        let id = messageId ?? UUID().uuidString
        var input: [String: Any] = ["conversationId": conversationId, "id": id, "content": content]
        if let mediaUrl { input["mediaUrl"] = mediaUrl }
        if let mediaType { input["mediaType"] = mediaType }
        if let language = await languageDetectionService.detectLanguage(for: content) { input["language"] = language }
        let result: WutzupMessageResult = try await ArchlifeWutzupAPI.data("send_message", input, requestId: id, expectedActor: actor)
        return owned([result.message])[0]
    }
    func fetchMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        let result: WutzupMessagesResult = try await ArchlifeWutzupAPI.data("messages", ["conversationId": conversationId, "limit": min(max(limit, 1), 200)])
        return owned(result.messages)
    }
    func observeMessages(conversationId: String) -> AsyncStream<Message> {
        var cursor: WutzupCursor?
        return WutzupPolling.stream {
            var input: [String: Any] = ["conversationId": conversationId, "limit": 200]
            if let cursor { input["cursor"] = ["at": cursor.at, "id": cursor.id] }
            let result: WutzupMessagesResult = try await ArchlifeWutzupAPI.data("sync_messages", input)
            cursor = result.cursor
            return self.owned(result.messages)
        }
    }
    private func receipts(conversationId: String, ids: [String], userId: String, kind: String) async throws {
        try ArchlifeWutzupAPI.requireActor(userId)
        for start in stride(from: 0, to: ids.count, by: 200) {
            let _: WutzupOK = try await ArchlifeWutzupAPI.data("receipts", ["conversationId": conversationId, "ids": Array(ids[start..<min(start + 200, ids.count)]), "kind": kind])
        }
    }
    func markAsRead(conversationId: String, messageId: String, userId: String) async throws { try await receipts(conversationId: conversationId, ids: [messageId], userId: userId, kind: "read") }
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws { try await receipts(conversationId: conversationId, ids: [messageId], userId: userId, kind: "delivered") }
    func batchMarkAsRead(conversationId: String, messageIds: [String], userId: String) async throws { try await receipts(conversationId: conversationId, ids: messageIds, userId: userId, kind: "read") }
    func batchMarkAsDelivered(conversationId: String, messageIds: [String], userId: String) async throws { try await receipts(conversationId: conversationId, ids: messageIds, userId: userId, kind: "delivered") }
}
