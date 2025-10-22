//
//  FirebaseUserService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

class FirebaseUserService: UserService {
    private let db = Firestore.firestore()

    func fetchAllUsers() async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        let users = snapshot.documents.compactMap { User(from: $0) }
        return users
    }
    
    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = User(from: document) else {
            throw NSError(
                domain: "FirebaseUserService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"]
            )
        }
        
        return user
    }
    
    func updatePersonality(userId: String, personality: String?) async throws {
        var updateData: [String: Any] = [:]
        
        if let personality = personality {
            updateData["personality"] = personality
        } else {
            updateData["personality"] = FieldValue.delete()
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
    }
}
