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
}
