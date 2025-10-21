//
//  ChatService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

protocol ChatService: AnyObject {
    func createConversation(withUserIds userIds: [String], isGroup: Bool, groupName: String?, participantNames: [String: String]) async throws -> Conversation
    func fetchConversations(userId: String) async throws -> [Conversation]
    func observeConversations(userId: String) -> AsyncStream<Conversation>
    func fetchOrCreateDirectConversation(userId: String, otherUserId: String, participantNames: [String: String]) async throws -> Conversation
    func updateConversation(_ conversation: Conversation) async throws
}
