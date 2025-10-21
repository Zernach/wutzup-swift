//
//  MessageService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

protocol MessageService: AnyObject {
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?) async throws -> Message
    func fetchMessages(conversationId: String, limit: Int) async throws -> [Message]
    func observeMessages(conversationId: String) -> AsyncStream<Message>
    func markAsRead(conversationId: String, messageId: String, userId: String) async throws
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws
}

