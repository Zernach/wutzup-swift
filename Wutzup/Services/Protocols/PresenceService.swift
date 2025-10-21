//
//  PresenceService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

enum PresenceStatus: String, Codable {
    case online
    case offline
}

struct Presence: Codable {
    let userId: String
    var status: PresenceStatus
    var lastSeen: Date
    var typing: [String: Bool] // conversationId -> isTyping
    
    init(userId: String, status: PresenceStatus = .offline, lastSeen: Date = Date(), typing: [String: Bool] = [:]) {
        self.userId = userId
        self.status = status
        self.lastSeen = lastSeen
        self.typing = typing
    }
}

protocol PresenceService: AnyObject {
    func setOnline(userId: String) async throws
    func setOffline(userId: String) async throws
    func observePresence(userId: String) -> AsyncStream<Presence>
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws
    func observeTyping(conversationId: String) -> AsyncStream<[String: Bool]> // userId -> isTyping
}

