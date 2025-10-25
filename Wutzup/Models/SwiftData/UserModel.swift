//
//  UserModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftData

@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
    var fcmToken: String?
    var createdAt: Date
    var lastSeen: Date?
    var isTutor: Bool
    var personality: String?
    
    init(id: String, email: String, displayName: String, profileImageUrl: String? = nil, fcmToken: String? = nil, createdAt: Date = Date(), lastSeen: Date? = nil, isTutor: Bool = false, personality: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.isTutor = isTutor
        self.personality = personality
    }
    
    // Convert from domain model
    convenience init(from user: User) {
        self.init(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            fcmToken: user.fcmToken,
            createdAt: user.createdAt,
            lastSeen: user.lastSeen,
            isTutor: user.isTutor,
            personality: user.personality
        )
    }
    
    // Convert to domain model
    func toDomainModel() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            profileImageUrl: profileImageUrl,
            fcmToken: fcmToken,
            createdAt: createdAt,
            lastSeen: lastSeen,
            personality: personality,
            isTutor: isTutor
        )
    }
}

