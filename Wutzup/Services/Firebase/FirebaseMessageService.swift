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
    private let languageDetectionService: LanguageDetectionService
    
    init(languageDetectionService: LanguageDetectionService = NaturalLanguageDetectionService()) {
        self.languageDetectionService = languageDetectionService
    }
    
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?, messageId: String?) async throws -> Message {
        
        guard let currentUserId = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseMessageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        
        // Fetch current user for display name
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        let senderName = userDoc.data()?["displayName"] as? String
        
        // Detect language for text content
        let detectedLanguage = await languageDetectionService.detectLanguage(for: content)
        
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
            language: detectedLanguage,
            isFromCurrentUser: true
        )
        
        
        // Write to Firestore with .sent status (SDK handles offline queue)
        
        // Create a sent version of the message for Firestore
        var sentMessage = message
        sentMessage.status = .sent  // Mark as sent in Firestore
        
        do {
            try await db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(message.id)
                .setData(sentMessage.firestoreData)
            
            // Update local message to sent
            message.status = .sent
        } catch {
            throw error
        }
        
        // Update conversation's last message
        
        // Fetch conversation to check if it's a group chat
        let conversationDoc = try await db.collection("conversations").document(conversationId).getDocument()
        let isGroup = conversationDoc.data()?["isGroup"] as? Bool ?? false
        
        // For group chats, prefix message with sender name
        var lastMessageText = content
        if isGroup, let senderName = senderName {
            lastMessageText = "\(senderName): \(content)"
        }
        
        do {
            try await db.collection("conversations")
                .document(conversationId)
                .updateData([
                    "lastMessage": lastMessageText,
                    "lastMessageTimestamp": Timestamp(date: message.timestamp),
                    "updatedAt": Timestamp(date: Date())
                ])
        } catch {
            // Don't throw here - message was already written successfully
        }
        
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
                    if let error = error {
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        return
                    }
                    
                    
                    for change in snapshot.documentChanges {
                        switch change.type {
                        case .added, .modified:
                            if let message = Message(from: change.document, currentUserId: currentUserId) {
                                continuation.yield(message)
                            } else {
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
                "readBy": FieldValue.arrayUnion([userId]),
                "status": MessageStatus.read.rawValue  // Update status to read
            ])
    }
    
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws {
        
        // Get current message to check if we should update status
        let messageDoc = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .getDocument()
        
        guard let data = messageDoc.data(),
              let currentStatus = data["status"] as? String else {
            return
        }
        
        // Only update status to delivered if it's currently sent (not if it's already read)
        var updateData: [String: Any] = [
            "deliveredTo": FieldValue.arrayUnion([userId])
        ]
        
        if currentStatus == MessageStatus.sent.rawValue {
            updateData["status"] = MessageStatus.delivered.rawValue
        } else {
        }
        
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData(updateData)
        
    }
    
    // MARK: - Batch Operations
    
    func batchMarkAsRead(conversationId: String, messageIds: [String], userId: String) async throws {
        guard !messageIds.isEmpty else { return }
        
        
        let batch = db.batch()
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        for messageId in messageIds {
            let messageRef = messagesRef.document(messageId)
            batch.updateData([
                "readBy": FieldValue.arrayUnion([userId])
            ], forDocument: messageRef)
        }
        
        try await batch.commit()
    }
    
    func batchMarkAsDelivered(conversationId: String, messageIds: [String], userId: String) async throws {
        guard !messageIds.isEmpty else { return }
        
        
        let batch = db.batch()
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        for messageId in messageIds {
            let messageRef = messagesRef.document(messageId)
            batch.updateData([
                "deliveredTo": FieldValue.arrayUnion([userId])
            ], forDocument: messageRef)
        }
        
        try await batch.commit()
    }
}

