//
//  User.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Hashable {
    let id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
    var fcmToken: String?
    var createdAt: Date
    var lastSeen: Date?

    // Explicit CodingKeys to ensure proper encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profileImageUrl
        case fcmToken
        case createdAt
        case lastSeen
    }

    init(id: String, email: String, displayName: String, profileImageUrl: String? = nil, fcmToken: String? = nil, createdAt: Date = Date(), lastSeen: Date? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.lastSeen = lastSeen
    }

    // Initialize from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let email = data["email"] as? String,
              let displayName = data["displayName"] as? String else {
            return nil
        }

        // Determine the ID to use
        let finalId: String
        if let storedId = data["id"] as? String, !storedId.isEmpty {
            finalId = storedId
        } else {
            finalId = document.documentID
        }

        // Validate the ID is not empty
        guard !finalId.isEmpty else {
            return nil
        }

        self.id = finalId
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = data["profileImageUrl"] as? String
        self.fcmToken = data["fcmToken"] as? String

        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            self.createdAt = createdAtTimestamp.dateValue()
        } else if let createdAtDate = data["createdAt"] as? Date {
            self.createdAt = createdAtDate
        } else {
            self.createdAt = Date()
        }

        if let lastSeenTimestamp = data["lastSeen"] as? Timestamp {
            self.lastSeen = lastSeenTimestamp.dateValue()
        } else if let lastSeenDate = data["lastSeen"] as? Date {
            self.lastSeen = lastSeenDate
        }
    }

    // Convert to Firestore data
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "displayName": displayName,
            "createdAt": Timestamp(date: createdAt)
        ]

        if let profileImageUrl = profileImageUrl {
            data["profileImageUrl"] = profileImageUrl
        }
        if let fcmToken = fcmToken {
            data["fcmToken"] = fcmToken
        }
        if let lastSeen = lastSeen {
            data["lastSeen"] = Timestamp(date: lastSeen)
        }

        return data
    }
}

// MARK: - Debug Description
extension User: CustomDebugStringConvertible {
    var debugDescription: String {
        return "User(id: \"\(id)\", displayName: \"\(displayName)\", email: \"\(email)\")"
    }
}
