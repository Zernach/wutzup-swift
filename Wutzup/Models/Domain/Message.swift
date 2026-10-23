//
//  Message.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

nonisolated enum MessageStatus: String, Codable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

nonisolated struct Message: Identifiable, Codable, Hashable, Sendable {
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
    var language: String?
    
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
         language: String? = nil,
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
        self.language = language
        self.isFromCurrentUser = isFromCurrentUser
    }
    

}

