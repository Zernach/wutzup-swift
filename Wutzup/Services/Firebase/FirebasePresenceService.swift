//
//  FirebasePresenceService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

class FirebasePresenceService: PresenceService {
    private let db = Firestore.firestore()
    
    func setOnline(userId: String) async throws {
        try await db.collection("presence")
            .document(userId)
            .setData([
                "status": "online",
                "lastSeen": Timestamp(date: Date()),
                "typing": [:]
            ], merge: true)
    }
    
    func setOffline(userId: String) async throws {
        try await db.collection("presence")
            .document(userId)
            .setData([
                "status": "offline",
                "lastSeen": Timestamp(date: Date())
            ], merge: true)
    }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        return AsyncStream { continuation in
            let listener = db.collection("presence")
                .document(userId)
                .addSnapshotListener { snapshot, error in
                    guard let snapshot = snapshot,
                          let data = snapshot.data(),
                          let statusString = data["status"] as? String,
                          let status = PresenceStatus(rawValue: statusString),
                          let lastSeenTimestamp = data["lastSeen"] as? Timestamp else {
                        return
                    }
                    
                    let typing = data["typing"] as? [String: Bool] ?? [:]
                    
                    let presence = Presence(
                        userId: userId,
                        status: status,
                        lastSeen: lastSeenTimestamp.dateValue(),
                        typing: typing
                    )
                    
                    continuation.yield(presence)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws {
        try await db.collection("presence")
            .document(userId)
            .setData([
                "typing": [conversationId: isTyping]
            ], merge: true)
    }
    
    func observeTyping(conversationId: String) -> AsyncStream<[String: Bool]> {
        return AsyncStream { continuation in
            // Observe all presence documents for typing in this conversation
            let listener = db.collection("presence")
                .addSnapshotListener { snapshot, error in
                    guard let snapshot = snapshot else {
                        return
                    }
                    
                    var typingUsers: [String: Bool] = [:]
                    
                    for document in snapshot.documents {
                        if let typing = document.data()["typing"] as? [String: Bool],
                           let isTypingInConversation = typing[conversationId],
                           isTypingInConversation {
                            typingUsers[document.documentID] = true
                        }
                    }
                    
                    continuation.yield(typingUsers)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}

