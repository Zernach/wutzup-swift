//
//  User.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
    var fcmToken: String?
    var createdAt: Date
    var lastSeen: Date?
    
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
              let displayName = data["displayName"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = data["profileImageUrl"] as? String
        self.fcmToken = data["fcmToken"] as? String
        self.createdAt = createdAtTimestamp.dateValue()
        
        if let lastSeenTimestamp = data["lastSeen"] as? Timestamp {
            self.lastSeen = lastSeenTimestamp.dateValue()
        }
    }
    
    // Convert to Firestore data
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
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

