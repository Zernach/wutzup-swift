//
//  Conversation.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

nonisolated struct Conversation: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var participantIds: [String]
    var participantNames: [String: String] // userId -> displayName
    var isGroup: Bool
    var groupName: String?
    var groupImageUrl: String?
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var createdAt: Date
    var updatedAt: Date
    var revision: Int = 1
    var unreadCount: Int = 0
    
    init(id: String = UUID().uuidString,
         participantIds: [String],
         participantNames: [String: String] = [:],
         isGroup: Bool = false,
         groupName: String? = nil,
         groupImageUrl: String? = nil,
         lastMessage: String? = nil,
         lastMessageTimestamp: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         unreadCount: Int = 0, revision: Int = 1) {
        self.id = id
        self.revision = revision
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupImageUrl = groupImageUrl
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
    }
    
    // Helper to get display name for conversation
    func displayName(currentUserId: String) -> String {
        if isGroup {
            return groupName ?? "Group Chat"
        } else {
            // For 1-on-1, find the other participant
            let otherParticipantId = participantIds.first { $0 != currentUserId }
            if let otherParticipantId = otherParticipantId {
                return participantNames[otherParticipantId] ?? "Unknown User"
            }
            return "Unknown User"
        }
    }
}

