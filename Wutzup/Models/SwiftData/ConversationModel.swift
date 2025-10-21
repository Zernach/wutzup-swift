//
//  ConversationModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftData

@Model
final class ConversationModel {
    @Attribute(.unique) var id: String
    var participantIdsData: Data? // Encoded [String]
    var participantNamesData: Data? // Encoded [String: String]
    var isGroup: Bool
    var groupName: String?
    var groupImageUrl: String?
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var createdAt: Date
    var updatedAt: Date
    var unreadCount: Int
    
    init(id: String, participantIds: [String], participantNames: [String: String] = [:], isGroup: Bool = false, groupName: String? = nil, groupImageUrl: String? = nil, lastMessage: String? = nil, lastMessageTimestamp: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), unreadCount: Int = 0) {
        self.id = id
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupImageUrl = groupImageUrl
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
        
        // Encode to Data
        self.participantIdsData = try? JSONEncoder().encode(participantIds)
        self.participantNamesData = try? JSONEncoder().encode(participantNames)
    }
    
    // Helper computed properties
    var participantIds: [String] {
        get {
            guard let data = participantIdsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            participantIdsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var participantNames: [String: String] {
        get {
            guard let data = participantNamesData else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        set {
            participantNamesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Convert from domain model
    convenience init(from conversation: Conversation) {
        self.init(
            id: conversation.id,
            participantIds: conversation.participantIds,
            participantNames: conversation.participantNames,
            isGroup: conversation.isGroup,
            groupName: conversation.groupName,
            groupImageUrl: conversation.groupImageUrl,
            lastMessage: conversation.lastMessage,
            lastMessageTimestamp: conversation.lastMessageTimestamp,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
            unreadCount: conversation.unreadCount
        )
    }
    
    // Convert to domain model
    func toDomainModel() -> Conversation {
        Conversation(
            id: id,
            participantIds: participantIds,
            participantNames: participantNames,
            isGroup: isGroup,
            groupName: groupName,
            groupImageUrl: groupImageUrl,
            lastMessage: lastMessage,
            lastMessageTimestamp: lastMessageTimestamp,
            createdAt: createdAt,
            updatedAt: updatedAt,
            unreadCount: unreadCount
        )
    }
}

