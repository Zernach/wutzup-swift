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
    
    nonisolated func createConversation(
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
        
        // Debug: Print conversation data before sending to Firestore
        print("🔍 Creating conversation with ID: \(conversation.id)")
        print("🔍 Participant IDs: \(conversation.participantIds)")
        print("🔍 Participant Names: \(conversation.participantNames)")
        print("🔍 Is Group: \(conversation.isGroup)")
        print("🔍 Firestore Data Keys: \(await conversation.firestoreData.keys.sorted())")
        print("🔍 Current User ID: \(currentUserId)")
        print("🔍 Current user in participants: \(conversation.participantIds.contains(currentUserId))")
        
        do {
            try await db.collection("conversations")
                .document(conversation.id)
                .setData(conversation.firestoreData)
            
            print("✅ Successfully created conversation: \(conversation.id)")
            return conversation
        } catch {
            print("❌ Failed to create conversation: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
            throw error
        }
    }
    
    nonisolated func fetchConversations(userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { Conversation(from: $0) }
    }
    
    nonisolated func observeConversations(userId: String) -> AsyncStream<Conversation> {
        print("🔥 [FirebaseChatService] Setting up conversation observer for user: \(userId)")
        
        return AsyncStream { continuation in
            let listener = db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("❌ [FirebaseChatService] Error observing conversations: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        print("❌ [FirebaseChatService] Snapshot is nil")
                        return
                    }
                    
                    print("🔥 [FirebaseChatService] Received snapshot with \(snapshot.documentChanges.count) changes")
                    
                    for change in snapshot.documentChanges {
                        let changeType = change.type == .added ? "added" : (change.type == .modified ? "modified" : "removed")
                        print("🔥 [FirebaseChatService] Change type: \(changeType), doc: \(change.document.documentID)")
                        
                        switch change.type {
                        case .added, .modified:
                            if let conversation = Conversation(from: change.document) {
                                print("✅ [FirebaseChatService] Yielding conversation: \(conversation.id)")
                                print("   lastMessage: \(conversation.lastMessage ?? "nil")")
                                print("   lastMessageTimestamp: \(conversation.lastMessageTimestamp?.description ?? "nil")")
                                continuation.yield(conversation)
                            } else {
                                print("⚠️ [FirebaseChatService] Failed to parse conversation from document: \(change.document.documentID)")
                            }
                        case .removed:
                            print("🗑️ [FirebaseChatService] Conversation removed: \(change.document.documentID)")
                            break
                        }
                    }
                }
            
            continuation.onTermination = { _ in
                print("🔥 [FirebaseChatService] Listener terminated for user: \(userId)")
                listener.remove()
            }
        }
    }
    
    nonisolated func fetchOrCreateDirectConversation(
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
    
    nonisolated func updateConversation(_ conversation: Conversation) async throws {
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
