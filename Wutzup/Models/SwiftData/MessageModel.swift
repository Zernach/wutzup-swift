//
//  MessageModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftData

@Model
final class MessageModel {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var senderName: String?
    var content: String
    var timestamp: Date
    var status: String
    var mediaUrl: String?
    var mediaType: String?
    var readByData: Data? // Encoded [String]
    var deliveredToData: Data? // Encoded [String]
    var language: String?
    var isFromCurrentUser: Bool
    
    init(id: String, conversationId: String, senderId: String, senderName: String? = nil, content: String, timestamp: Date, status: String, mediaUrl: String? = nil, mediaType: String? = nil, readBy: [String] = [], deliveredTo: [String] = [], language: String? = nil, isFromCurrentUser: Bool = false) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.language = language
        self.isFromCurrentUser = isFromCurrentUser
        
        // Encode arrays to Data
        self.readByData = try? JSONEncoder().encode(readBy)
        self.deliveredToData = try? JSONEncoder().encode(deliveredTo)
    }
    
    // Helper computed properties
    var readBy: [String] {
        get {
            guard let data = readByData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            readByData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var deliveredTo: [String] {
        get {
            guard let data = deliveredToData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            deliveredToData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Convert from domain model
    convenience init(from message: Message) {
        self.init(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            senderName: message.senderName,
            content: message.content,
            timestamp: message.timestamp,
            status: message.status.rawValue,
            mediaUrl: message.mediaUrl,
            mediaType: message.mediaType,
            readBy: message.readBy,
            deliveredTo: message.deliveredTo,
            language: message.language,
            isFromCurrentUser: message.isFromCurrentUser
        )
    }
    
    // Convert to domain model
    func toDomainModel() -> Message {
        Message(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            content: content,
            timestamp: timestamp,
            status: MessageStatus(rawValue: status) ?? .sent,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            readBy: readBy,
            deliveredTo: deliveredTo,
            language: language,
            isFromCurrentUser: isFromCurrentUser
        )
    }
}

