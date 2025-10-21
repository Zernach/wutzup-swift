//
//  FirebaseChatService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseChatService: ChatService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func createConversation(withUserIds userIds: [String], isGroup: Bool = false, groupName: String? = nil) async throws -> Conversation {
        guard let currentUserId = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var allParticipantIds = userIds
        if !allParticipantIds.contains(currentUserId) {
            allParticipantIds.append(currentUserId)
        }
        
        // Fetch participant names
        var participantNames: [String: String] = [:]
        for userId in allParticipantIds {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let displayName = userDoc.data()?["displayName"] as? String {
                participantNames[userId] = displayName
            }
        }
        
        let conversation = Conversation(
            participantIds: allParticipantIds,
            participantNames: participantNames,
            isGroup: isGroup,
            groupName: groupName
        )
        
        try await db.collection("conversations")
            .document(conversation.id)
            .setData(conversation.firestoreData)
        
        return conversation
    }
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { Conversation(from: $0) }
    }
    
    func observeConversations(userId: String) -> AsyncStream<Conversation> {
        return AsyncStream { continuation in
            let listener = db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let snapshot = snapshot else {
                        print("Error observing conversations: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    for change in snapshot.documentChanges {
                        switch change.type {
                        case .added, .modified:
                            if let conversation = Conversation(from: change.document) {
                                continuation.yield(conversation)
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
    
    func fetchOrCreateDirectConversation(userId: String, otherUserId: String) async throws -> Conversation {
        // Check if conversation already exists
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .whereField("isGroup", isEqualTo: false)
            .getDocuments()
        
        // Find existing 1-on-1 conversation
        for document in snapshot.documents {
            if let conversation = Conversation(from: document),
               conversation.participantIds.contains(otherUserId) &&
               conversation.participantIds.count == 2 {
                return conversation
            }
        }
        
        // Create new conversation
        return try await createConversation(withUserIds: [userId, otherUserId], isGroup: false)
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        try await db.collection("conversations")
            .document(conversation.id)
            .updateData(conversation.firestoreData)
    }
}

