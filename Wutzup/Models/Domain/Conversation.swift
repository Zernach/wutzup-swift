//
//  Conversation.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable, Hashable, Sendable {
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
         unreadCount: Int = 0) {
        self.id = id
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
    
    // Initialize from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let participantIds = data["participantIds"] as? [String],
              let isGroup = data["isGroup"] as? Bool,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.participantIds = participantIds
        self.participantNames = data["participantNames"] as? [String: String] ?? [:]
        self.isGroup = isGroup
        self.groupName = data["groupName"] as? String
        self.groupImageUrl = data["groupImageUrl"] as? String
        self.lastMessage = data["lastMessage"] as? String
        
        if let lastMessageTimestamp = data["lastMessageTimestamp"] as? Timestamp {
            self.lastMessageTimestamp = lastMessageTimestamp.dateValue()
        }
        
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
        self.unreadCount = data["unreadCount"] as? Int ?? 0
    }
    
    // Convert to Firestore data
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "participantIds": participantIds,
            "participantNames": participantNames,
            "isGroup": isGroup,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "unreadCount": unreadCount
        ]
        
        if let groupName = groupName {
            data["groupName"] = groupName
        }
        if let groupImageUrl = groupImageUrl {
            data["groupImageUrl"] = groupImageUrl
        }
        if let lastMessage = lastMessage {
            data["lastMessage"] = lastMessage
        }
        if let lastMessageTimestamp = lastMessageTimestamp {
            data["lastMessageTimestamp"] = Timestamp(date: lastMessageTimestamp)
        }
        
        return data
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

