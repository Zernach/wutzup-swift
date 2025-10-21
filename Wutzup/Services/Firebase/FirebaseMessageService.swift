//
//  FirebaseMessageService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseMessageService: MessageService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?) async throws -> Message {
        guard let currentUserId = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseMessageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Fetch current user for display name
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        let senderName = userDoc.data()?["displayName"] as? String
        
        let message = Message(
            conversationId: conversationId,
            senderId: currentUserId,
            senderName: senderName,
            content: content,
            timestamp: Date(),
            status: .sending,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            isFromCurrentUser: true
        )
        
        // Write to Firestore (SDK handles offline queue)
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
            .setData(message.firestoreData)
        
        // Update conversation's last message
        try await db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessage": content,
                "lastMessageTimestamp": Timestamp(date: message.timestamp),
                "updatedAt": Timestamp(date: Date())
            ])
        
        return message
    }
    
    func fetchMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        let snapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        let currentUserId = auth.currentUser?.uid
        return snapshot.documents.compactMap { Message(from: $0, currentUserId: currentUserId) }
    }
    
    func observeMessages(conversationId: String) -> AsyncStream<Message> {
        let currentUserId = auth.currentUser?.uid
        
        return AsyncStream { continuation in
            let listener = db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    guard let snapshot = snapshot else {
                        print("Error observing messages: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    for change in snapshot.documentChanges {
                        switch change.type {
                        case .added, .modified:
                            if let message = Message(from: change.document, currentUserId: currentUserId) {
                                continuation.yield(message)
                            }
                        case .removed:
                            break
                        }
                    }
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    func markAsRead(conversationId: String, messageId: String, userId: String) async throws {
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "readBy": FieldValue.arrayUnion([userId])
            ])
    }
    
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws {
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "deliveredTo": FieldValue.arrayUnion([userId])
            ])
    }
}

