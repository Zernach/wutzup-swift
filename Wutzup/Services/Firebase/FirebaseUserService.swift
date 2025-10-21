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

        print("🔍 [DEBUG] FirebaseUserService.fetchAllUsers - fetched \(snapshot.documents.count) documents")

        let users = snapshot.documents.compactMap { document -> User? in
            let user = User(from: document)
            if let user = user {
                print("✅ [DEBUG] Successfully parsed user: id=\(user.id), displayName=\(user.displayName)")
                if user.id.isEmpty {
                    print("⚠️ [WARNING] User has EMPTY ID! displayName=\(user.displayName), email=\(user.email)")
                }
            } else {
                print("❌ [ERROR] Failed to parse user from document: \(document.documentID)")
            }
            return user
        }

        print("🔍 [DEBUG] FirebaseUserService.fetchAllUsers - returning \(users.count) valid users")
        return users
    }
}
