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
    
    func createConversation(
        withUserIds userIds: [String],
        isGroup: Bool = false,
        groupName: String? = nil,
        participantNames: [String: String] = [:]
    ) async throws -> Conversation {
        guard let currentUserId = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var allParticipantIds = Set(userIds)
        allParticipantIds.insert(currentUserId)
        
        var resolvedParticipantNames = participantNames
        
        // Ensure current user name is included
        if resolvedParticipantNames[currentUserId] == nil {
            let userDoc = try await db.collection("users").document(currentUserId).getDocument()
            if let displayName = userDoc.data()?["displayName"] as? String {
                resolvedParticipantNames[currentUserId] = displayName
            }
        }
        
        // Fetch any missing participant names in batches of 10 (Firestore limitation for "in" queries)
        let missingIds = allParticipantIds.filter { resolvedParticipantNames[$0] == nil }
        if !missingIds.isEmpty {
            for chunk in Array(missingIds).chunked(into: 10) {
                let snapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                for document in snapshot.documents {
                    if let displayName = document.data()["displayName"] as? String {
                        resolvedParticipantNames[document.documentID] = displayName
                    }
                }
            }
        }
        
        let participantIdList = Array(allParticipantIds).sorted()
        
        let conversation = Conversation(
            participantIds: participantIdList,
            participantNames: resolvedParticipantNames,
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
    
    func fetchOrCreateDirectConversation(
        userId: String,
        otherUserId: String,
        participantNames: [String: String] = [:]
    ) async throws -> Conversation {
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
        return try await createConversation(
            withUserIds: [userId, otherUserId],
            isGroup: false,
            participantNames: participantNames
        )
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        try await db.collection("conversations")
            .document(conversation.id)
            .updateData(conversation.firestoreData)
    }
}

private extension Array where Element == String {
    func chunked(into size: Int) -> [[String]] {
        guard size > 0 else { return [self] }
        var result: [[String]] = []
        var index = 0
        while index < count {
            let chunk = Array(self[index..<Swift.min(index + size, count)])
            result.append(chunk)
            index += size
        }
        return result
    }
}
