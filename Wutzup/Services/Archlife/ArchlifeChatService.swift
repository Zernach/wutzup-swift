import Foundation

final class ArchlifeChatService: ChatService {
    func createConversation(withUserIds userIds: [String], isGroup: Bool = false, groupName: String? = nil, participantNames: [String: String] = [:]) async throws -> Conversation {
        guard let actor = ArchlifeWutzupAPI.currentUserID else { throw WutzupAPIError(status: 401, code: "unauthorized") }
        let input: [String: Any] = ["id": UUID().uuidString, "participantIds": Array(Set(userIds + [actor])).sorted(), "isGroup": isGroup, "groupName": groupName as Any? ?? NSNull()]
        let result: WutzupConversationResult = try await ArchlifeWutzupAPI.data("create_conversation", input)
        return result.conversation
    }
    func fetchConversations(userId: String) async throws -> [Conversation] {
        try ArchlifeWutzupAPI.requireActor(userId)
        var conversations: [Conversation] = [], after: String?
        repeat {
            var input: [String: Any] = ["limit": 200]
            if let after { input["after"] = after }
            let result: WutzupConversationsResult = try await ArchlifeWutzupAPI.data("conversations", input)
            conversations += result.conversations
            after = result.next
        } while after != nil
        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }
    func observeConversations(userId: String) -> AsyncStream<Conversation> {
        WutzupPolling.stream { try await self.fetchConversations(userId: userId) }
    }
    func fetchOrCreateDirectConversation(userId: String, otherUserId: String, participantNames: [String: String]) async throws -> Conversation {
        try ArchlifeWutzupAPI.requireActor(userId)
        return try await createConversation(withUserIds: [otherUserId], participantNames: participantNames)
    }
    func addMembers(conversationId: String, userIds: [String]) async throws {
        let _: WutzupConversationResult = try await ArchlifeWutzupAPI.data("add_members", ["conversationId": conversationId, "participantIds": Array(Set(userIds)).sorted()])
    }
    func updateConversation(_ conversation: Conversation) async throws {
        let _: WutzupConversationResult = try await ArchlifeWutzupAPI.data("update_conversation", ["conversationId": conversation.id, "revision": conversation.revision,
            "participantIds": conversation.participantIds, "groupName": conversation.groupName as Any? ?? NSNull(), "groupImageUrl": conversation.groupImageUrl as Any? ?? NSNull()])
    }
}
