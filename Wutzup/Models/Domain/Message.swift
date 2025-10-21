//
//  Message.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    var senderName: String?
    var content: String
    var timestamp: Date
    var status: MessageStatus
    var mediaUrl: String?
    var mediaType: String?
    var readBy: [String]
    var deliveredTo: [String]
    
    var isFromCurrentUser: Bool = false
    
    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: String,
         senderName: String? = nil,
         content: String,
         timestamp: Date = Date(),
         status: MessageStatus = .sending,
         mediaUrl: String? = nil,
         mediaType: String? = nil,
         readBy: [String] = [],
         deliveredTo: [String] = [],
         isFromCurrentUser: Bool = false) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.readBy = readBy
        self.deliveredTo = deliveredTo
        self.isFromCurrentUser = isFromCurrentUser
    }
    
    // Initialize from Firestore document
    init?(from document: DocumentSnapshot, currentUserId: String? = nil) {
        guard let data = document.data(),
              let conversationId = data["conversationId"] as? String,
              let senderId = data["senderId"] as? String,
              let content = data["content"] as? String,
              let timestampData = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = data["senderName"] as? String
        self.content = content
        self.timestamp = timestampData.dateValue()
        
        if let statusString = data["status"] as? String,
           let status = MessageStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .sent
        }
        
        self.mediaUrl = data["mediaUrl"] as? String
        self.mediaType = data["mediaType"] as? String
        self.readBy = data["readBy"] as? [String] ?? []
        self.deliveredTo = data["deliveredTo"] as? [String] ?? []
        
        if let currentUserId = currentUserId {
            self.isFromCurrentUser = senderId == currentUserId
        }
    }
    
    // Convert to Firestore data
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "conversationId": conversationId,
            "senderId": senderId,
            "content": content,
            "timestamp": Timestamp(date: timestamp),
            "status": status.rawValue,
            "readBy": readBy,
            "deliveredTo": deliveredTo
        ]
        
        if let senderName = senderName {
            data["senderName"] = senderName
        }
        if let mediaUrl = mediaUrl {
            data["mediaUrl"] = mediaUrl
        }
        if let mediaType = mediaType {
            data["mediaType"] = mediaType
        }
        
        return data
    }
}

