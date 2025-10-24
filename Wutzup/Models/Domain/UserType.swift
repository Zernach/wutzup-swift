//
//  User.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
    var fcmToken: String?
    var createdAt: Date
    var lastSeen: Date?
    var personality: String?
    var primaryLanguageCode: String?
    var learningLanguageCode: String?
    var isTutor: Bool

    // Explicit CodingKeys to ensure proper encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profileImageUrl
        case fcmToken
        case createdAt
        case lastSeen
        case personality
        case primaryLanguageCode
        case learningLanguageCode
        case isTutor
    }

    init(id: String, email: String, displayName: String, profileImageUrl: String? = nil, fcmToken: String? = nil, createdAt: Date = Date(), lastSeen: Date? = nil, personality: String? = nil, primaryLanguageCode: String? = nil, learningLanguageCode: String? = nil, isTutor: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.personality = personality
        self.primaryLanguageCode = primaryLanguageCode
        self.learningLanguageCode = learningLanguageCode
        self.isTutor = isTutor
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
        self.personality = data["personality"] as? String
        self.primaryLanguageCode = data["primaryLanguageCode"] as? String
        self.learningLanguageCode = data["learningLanguageCode"] as? String
        self.isTutor = data["isTutor"] as? Bool ?? false

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
        if let personality = personality {
            data["personality"] = personality
        }
        if let primaryLanguageCode = primaryLanguageCode {
            data["primaryLanguageCode"] = primaryLanguageCode
        }
        if let learningLanguageCode = learningLanguageCode {
            data["learningLanguageCode"] = learningLanguageCode
        }
        
        data["isTutor"] = isTutor

        return data
    }
}

// MARK: - Debug Description
extension User: CustomDebugStringConvertible {
    var debugDescription: String {
        return "User(id: \"\(id)\", displayName: \"\(displayName)\", email: \"\(email)\")"
    }
}
