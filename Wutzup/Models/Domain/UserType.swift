//
//  User.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

nonisolated struct User: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
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
        case createdAt
        case lastSeen
        case personality
        case primaryLanguageCode
        case learningLanguageCode
        case isTutor
    }

    init(id: String, email: String, displayName: String, profileImageUrl: String? = nil, createdAt: Date = Date(), lastSeen: Date? = nil, personality: String? = nil, primaryLanguageCode: String? = nil, learningLanguageCode: String? = nil, isTutor: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.personality = personality
        self.primaryLanguageCode = primaryLanguageCode
        self.learningLanguageCode = learningLanguageCode
        self.isTutor = isTutor
    }


}

// MARK: - Debug Description
extension User: CustomDebugStringConvertible {
    var debugDescription: String {
        return "User(id: \"\(id)\", displayName: \"\(displayName)\", email: \"\(email)\")"
    }
}
