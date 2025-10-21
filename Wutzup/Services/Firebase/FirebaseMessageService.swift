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
    
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?, messageId: String?) async throws -> Message {
        print("🔥 [FirebaseMessageService] sendMessage() - ENTRY")
        print("🔥 [FirebaseMessageService] conversationId: \(conversationId)")
        print("🔥 [FirebaseMessageService] content: '\(content)'")
        print("🔥 [FirebaseMessageService] messageId: \(messageId ?? "nil (will generate)")")
        
        guard let currentUserId = auth.currentUser?.uid else {
            print("❌ [FirebaseMessageService] ERROR: User not authenticated")
            throw NSError(domain: "FirebaseMessageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔥 [FirebaseMessageService] currentUserId: \(currentUserId)")
        
        // Fetch current user for display name
        print("🔥 [FirebaseMessageService] Fetching user document for display name...")
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        let senderName = userDoc.data()?["displayName"] as? String
        print("🔥 [FirebaseMessageService] senderName: \(senderName ?? "nil")")
        
        // Create message with provided ID or generate new one
        // Use .sending status initially, will update to .sent after successful write
        var message = Message(
            id: messageId ?? UUID().uuidString,  // Use provided ID for optimistic updates
            conversationId: conversationId,
            senderId: currentUserId,
            senderName: senderName,
            content: content,
            timestamp: Date(),
            status: .sending,  // Start with sending status
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            isFromCurrentUser: true
        )
        
        print("🔥 [FirebaseMessageService] Created message object:")
        print("🔥 [FirebaseMessageService]   messageId: \(message.id)")
        print("🔥 [FirebaseMessageService]   timestamp: \(message.timestamp)")
        
        // Write to Firestore with .sent status (SDK handles offline queue)
        print("🔥 [FirebaseMessageService] Writing message to Firestore...")
        print("🔥 [FirebaseMessageService]   Path: conversations/\(conversationId)/messages/\(message.id)")
        
        // Create a sent version of the message for Firestore
        var sentMessage = message
        sentMessage.status = .sent  // Mark as sent in Firestore
        
        do {
            try await db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(message.id)
                .setData(sentMessage.firestoreData)
            print("✅ [FirebaseMessageService] Message written to Firestore successfully with status: sent")
            
            // Update local message to sent
            message.status = .sent
        } catch {
            print("❌ [FirebaseMessageService] ERROR writing message: \(error)")
            throw error
        }
        
        // Update conversation's last message
        print("🔥 [FirebaseMessageService] Updating conversation document...")
        print("🔥 [FirebaseMessageService]   Path: conversations/\(conversationId)")
        do {
            try await db.collection("conversations")
                .document(conversationId)
                .updateData([
                    "lastMessage": content,
                    "lastMessageTimestamp": Timestamp(date: message.timestamp),
                    "updatedAt": Timestamp(date: Date())
                ])
            print("✅ [FirebaseMessageService] Conversation updated successfully")
        } catch {
            print("❌ [FirebaseMessageService] ERROR updating conversation: \(error)")
            // Don't throw here - message was already written successfully
            print("⚠️ [FirebaseMessageService] Continuing despite conversation update error")
        }
        
        print("✅ [FirebaseMessageService] sendMessage() - SUCCESS, returning message")
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
        print("🔥 [FirebaseMessageService] observeMessages() - Setting up listener for conversation: \(conversationId)")
        
        return AsyncStream { continuation in
            let listener = db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("❌ [FirebaseMessageService] Error observing messages: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        print("❌ [FirebaseMessageService] Snapshot is nil")
                        return
                    }
                    
                    print("🔥 [FirebaseMessageService] Received snapshot with \(snapshot.documentChanges.count) changes")
                    
                    for change in snapshot.documentChanges {
                        print("🔥 [FirebaseMessageService] Change type: \(change.type.rawValue), doc: \(change.document.documentID)")
                        switch change.type {
                        case .added, .modified:
                            if let message = Message(from: change.document, currentUserId: currentUserId) {
                                print("✅ [FirebaseMessageService] Yielding message: \(message.id), status: \(message.status), content: '\(message.content)'")
                                continuation.yield(message)
                            } else {
                                print("⚠️ [FirebaseMessageService] Failed to parse message from document: \(change.document.documentID)")
                            }
                        case .removed:
                            print("🔥 [FirebaseMessageService] Message removed: \(change.document.documentID)")
                            break
                        }
                    }
                }
            
            continuation.onTermination = { _ in
                print("🔥 [FirebaseMessageService] Listener terminated for conversation: \(conversationId)")
                listener.remove()
            }
        }
    }
    
    func markAsRead(conversationId: String, messageId: String, userId: String) async throws {
        print("🔥 [FirebaseMessageService] Marking message \(messageId) as read by \(userId)")
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "readBy": FieldValue.arrayUnion([userId]),
                "status": MessageStatus.read.rawValue  // Update status to read
            ])
        print("✅ [FirebaseMessageService] Message marked as read")
    }
    
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws {
        print("🔥 [FirebaseMessageService] Marking message \(messageId) as delivered to \(userId)")
        
        // Get current message to check if we should update status
        let messageDoc = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .getDocument()
        
        guard let data = messageDoc.data(),
              let currentStatus = data["status"] as? String else {
            print("⚠️ [FirebaseMessageService] Could not get current message status")
            return
        }
        
        // Only update status to delivered if it's currently sent (not if it's already read)
        var updateData: [String: Any] = [
            "deliveredTo": FieldValue.arrayUnion([userId])
        ]
        
        if currentStatus == MessageStatus.sent.rawValue {
            updateData["status"] = MessageStatus.delivered.rawValue
            print("🔥 [FirebaseMessageService] Updating status from sent → delivered")
        } else {
            print("🔥 [FirebaseMessageService] Status is \(currentStatus), not updating")
        }
        
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData(updateData)
        
        print("✅ [FirebaseMessageService] Message marked as delivered")
    }
    
    // MARK: - Batch Operations
    
    func batchMarkAsRead(conversationId: String, messageIds: [String], userId: String) async throws {
        guard !messageIds.isEmpty else { return }
        
        print("🔥 [FirebaseMessageService] Batch marking \(messageIds.count) messages as read")
        
        let batch = db.batch()
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        for messageId in messageIds {
            let messageRef = messagesRef.document(messageId)
            batch.updateData([
                "readBy": FieldValue.arrayUnion([userId])
            ], forDocument: messageRef)
        }
        
        try await batch.commit()
        print("✅ [FirebaseMessageService] Batch marked \(messageIds.count) messages as read")
    }
    
    func batchMarkAsDelivered(conversationId: String, messageIds: [String], userId: String) async throws {
        guard !messageIds.isEmpty else { return }
        
        print("🔥 [FirebaseMessageService] Batch marking \(messageIds.count) messages as delivered")
        
        let batch = db.batch()
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        for messageId in messageIds {
            let messageRef = messagesRef.document(messageId)
            batch.updateData([
                "deliveredTo": FieldValue.arrayUnion([userId])
            ], forDocument: messageRef)
        }
        
        try await batch.commit()
        print("✅ [FirebaseMessageService] Batch marked \(messageIds.count) messages as delivered")
    }
}

