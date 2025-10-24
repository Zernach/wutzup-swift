# Swift Types for Firestore Schema

This document provides Swift struct definitions that match the Firestore database schema for use in the iOS app.

## Domain Models (Codable)

### User

```swift
import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String
    let profileImageUrl: String?
    let fcmToken: String?
    let createdAt: Date
    let lastSeen: Date?
    let personality: String?
    let primaryLanguageCode: String?
    let learningLanguageCode: String?
    let isTutor: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email, displayName, profileImageUrl, fcmToken, createdAt, lastSeen
        case personality, primaryLanguageCode, learningLanguageCode, isTutor
    }
}

extension User {
    /// Initialize from Firestore document snapshot
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let id = data["id"] as? String,
              let email = data["email"] as? String,
              let displayName = data["displayName"] as? String else {
            return nil
        }
        
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = data["profileImageUrl"] as? String
        self.fcmToken = data["fcmToken"] as? String
        self.personality = data["personality"] as? String
        self.primaryLanguageCode = data["primaryLanguageCode"] as? String
        self.learningLanguageCode = data["learningLanguageCode"] as? String
        self.isTutor = data["isTutor"] as? Bool ?? false
        
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        if let timestamp = data["lastSeen"] as? Timestamp {
            self.lastSeen = timestamp.dateValue()
        } else {
            self.lastSeen = nil
        }
    }
    
    /// Convert to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "displayName": displayName,
            "createdAt": Timestamp(date: createdAt),
            "isTutor": isTutor
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
        
        return data
    }
}
```

### Conversation

```swift
import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    let id: String
    let participantIds: [String]
    let isGroup: Bool
    let groupName: String?
    let groupImageUrl: String?
    let lastMessage: String?
    let lastMessageTimestamp: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, participantIds, isGroup, groupName, groupImageUrl
        case lastMessage, lastMessageTimestamp, createdAt, updatedAt
    }
}

extension Conversation {
    /// Initialize from Firestore document snapshot
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let id = data["id"] as? String,
              let participantIds = data["participantIds"] as? [String],
              let isGroup = data["isGroup"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.participantIds = participantIds
        self.isGroup = isGroup
        self.groupName = data["groupName"] as? String
        self.groupImageUrl = data["groupImageUrl"] as? String
        self.lastMessage = data["lastMessage"] as? String
        
        if let timestamp = data["lastMessageTimestamp"] as? Timestamp {
            self.lastMessageTimestamp = timestamp.dateValue()
        } else {
            self.lastMessageTimestamp = nil
        }
        
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        if let timestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
    
    /// Convert to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "participantIds": participantIds,
            "isGroup": isGroup,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let groupName = groupName {
            data["groupName"] = groupName
        }
        
        if let groupImageUrl = groupImageUrl {
            data["groupImageUrl"] = groupImageUrl
        }
        
        if let lastMessage = lastMessage {
            data["lastMessage"] = lastMessage
        }
        
        if let lastMessageTimestamp = lastMessageTimestamp {
            data["lastMessageTimestamp"] = Timestamp(date: lastMessageTimestamp)
        }
        
        return data
    }
    
    /// Get display name for conversation
    func displayName(currentUserId: String, users: [String: User]) -> String {
        if isGroup {
            return groupName ?? "Group Chat"
        } else {
            // One-on-one: show other user's name
            let otherUserId = participantIds.first { $0 != currentUserId }
            return users[otherUserId ?? ""]?.displayName ?? "Unknown"
        }
    }
}
```

### Message

```swift
import Foundation
import FirebaseFirestore

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

enum MediaType: String, Codable {
    case image
    case video
}

struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let content: String
    let timestamp: Date
    let mediaUrl: String?
    let mediaType: MediaType?
    let readBy: [String]
    let deliveredTo: [String]
    
    // Local-only properties (not stored in Firestore)
    var status: MessageStatus = .sent
    
    enum CodingKeys: String, CodingKey {
        case id, senderId, content, timestamp, mediaUrl, mediaType, readBy, deliveredTo
    }
}

extension Message {
    /// Initialize from Firestore document snapshot
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        
        self.id = id
        self.senderId = senderId
        self.content = content
        
        if let timestamp = data["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = Date()
        }
        
        self.mediaUrl = data["mediaUrl"] as? String
        
        if let mediaTypeString = data["mediaType"] as? String {
            self.mediaType = MediaType(rawValue: mediaTypeString)
        } else {
            self.mediaType = nil
        }
        
        self.readBy = data["readBy"] as? [String] ?? []
        self.deliveredTo = data["deliveredTo"] as? [String] ?? []
        
        // Determine status based on readBy/deliveredTo
        if !self.readBy.isEmpty {
            self.status = .read
        } else if !self.deliveredTo.isEmpty {
            self.status = .delivered
        } else {
            self.status = .sent
        }
    }
    
    /// Convert to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "senderId": senderId,
            "content": content,
            "timestamp": Timestamp(date: timestamp),
            "readBy": readBy,
            "deliveredTo": deliveredTo
        ]
        
        if let mediaUrl = mediaUrl {
            data["mediaUrl"] = mediaUrl
        }
        
        if let mediaType = mediaType {
            data["mediaType"] = mediaType.rawValue
        }
        
        return data
    }
    
    /// Check if message is read by specific user
    func isReadBy(userId: String) -> Bool {
        return readBy.contains(userId)
    }
    
    /// Check if message is delivered to specific user
    func isDeliveredTo(userId: String) -> Bool {
        return deliveredTo.contains(userId)
    }
}
```

### Presence

```swift
import Foundation
import FirebaseFirestore

enum UserStatus: String, Codable {
    case online
    case offline
}

struct Presence: Codable {
    let status: UserStatus
    let lastSeen: Date
    let typing: [String: Bool]  // conversationId -> isTyping
    
    enum CodingKeys: String, CodingKey {
        case status, lastSeen, typing
    }
}

extension Presence {
    /// Initialize from Firestore document snapshot
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let statusString = data["status"] as? String,
              let status = UserStatus(rawValue: statusString) else {
            return nil
        }
        
        self.status = status
        
        if let timestamp = data["lastSeen"] as? Timestamp {
            self.lastSeen = timestamp.dateValue()
        } else {
            self.lastSeen = Date()
        }
        
        self.typing = data["typing"] as? [String: Bool] ?? [:]
    }
    
    /// Convert to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        return [
            "status": status.rawValue,
            "lastSeen": Timestamp(date: lastSeen),
            "typing": typing
        ]
    }
    
    /// Check if user is typing in a specific conversation
    func isTyping(in conversationId: String) -> Bool {
        return typing[conversationId] ?? false
    }
}
```

### TypingIndicator

```swift
import Foundation
import FirebaseFirestore

struct TypingIndicator: Codable {
    let users: [String: Date]  // userId -> timestamp
    
    enum CodingKeys: String, CodingKey {
        case users
    }
}

extension TypingIndicator {
    /// Initialize from Firestore document snapshot
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else {
            return nil
        }
        
        let usersData = data["users"] as? [String: Timestamp] ?? [:]
        self.users = usersData.mapValues { $0.dateValue() }
    }
    
    /// Convert to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        let usersData = users.mapValues { Timestamp(date: $0) }
        return ["users": usersData]
    }
    
    /// Get list of user IDs currently typing
    func typingUserIds() -> [String] {
        let fiveSecondsAgo = Date().addingTimeInterval(-5)
        return users.filter { $0.value > fiveSecondsAgo }.map { $0.key }
    }
}
```

## SwiftData Models (for Local Persistence)

### MessageModel

```swift
import Foundation
import SwiftData

@Model
final class MessageModel {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var content: String
    var timestamp: Date
    var status: String  // "sending", "sent", "delivered", "read", "failed"
    var isFromCurrentUser: Bool
    var mediaUrl: String?
    var mediaType: String?  // "image", "video"
    
    init(id: String, conversationId: String, senderId: String, content: String,
         timestamp: Date, status: String, isFromCurrentUser: Bool,
         mediaUrl: String? = nil, mediaType: String? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.isFromCurrentUser = isFromCurrentUser
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
    }
    
    /// Create from domain Message model
    convenience init(from message: Message, currentUserId: String) {
        self.init(
            id: message.id,
            conversationId: "",  // Set from context
            senderId: message.senderId,
            content: message.content,
            timestamp: message.timestamp,
            status: message.status.rawValue,
            isFromCurrentUser: message.senderId == currentUserId,
            mediaUrl: message.mediaUrl,
            mediaType: message.mediaType?.rawValue
        )
    }
}
```

### ConversationModel

```swift
import Foundation
import SwiftData

@Model
final class ConversationModel {
    @Attribute(.unique) var id: String
    var participantIds: [String]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var unreadCount: Int
    var isGroup: Bool
    var groupName: String?
    var groupImageUrl: String?
    
    init(id: String, participantIds: [String], lastMessage: String? = nil,
         lastMessageTimestamp: Date? = nil, unreadCount: Int = 0,
         isGroup: Bool = false, groupName: String? = nil, groupImageUrl: String? = nil) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupImageUrl = groupImageUrl
    }
    
    /// Create from domain Conversation model
    convenience init(from conversation: Conversation, unreadCount: Int = 0) {
        self.init(
            id: conversation.id,
            participantIds: conversation.participantIds,
            lastMessage: conversation.lastMessage,
            lastMessageTimestamp: conversation.lastMessageTimestamp,
            unreadCount: unreadCount,
            isGroup: conversation.isGroup,
            groupName: conversation.groupName,
            groupImageUrl: conversation.groupImageUrl
        )
    }
}
```

### UserModel

```swift
import Foundation
import SwiftData

@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
    var status: String  // "online", "offline"
    var lastSeen: Date?
    
    init(id: String, email: String, displayName: String,
         profileImageUrl: String? = nil, status: String = "offline",
         lastSeen: Date? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.status = status
        self.lastSeen = lastSeen
    }
    
    /// Create from domain User model
    convenience init(from user: User, status: String = "offline") {
        self.init(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            status: status,
            lastSeen: user.lastSeen
        )
    }
}
```

## Usage Examples

### Creating a User

```swift
import FirebaseAuth
import FirebaseFirestore

func createUser(email: String, password: String, displayName: String) async throws -> User {
    let db = Firestore.firestore()
    
    // 1. Create Firebase Auth user
    let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
    
    // 2. Create Firestore user document
    let user = User(
        id: authResult.user.uid,
        email: email,
        displayName: displayName,
        profileImageUrl: nil,
        fcmToken: nil,
        createdAt: Date(),
        lastSeen: nil,
        personality: nil,
        primaryLanguageCode: nil,
        learningLanguageCode: nil,
        isTutor: false
    )
    
    try await db.collection("users").document(user.id).setData(user.toFirestoreData())
    
    return user
}
```

### Sending a Message

```swift
import FirebaseFirestore

func sendMessage(conversationId: String, content: String, currentUserId: String) async throws -> Message {
    let db = Firestore.firestore()
    
    // 1. Create message
    let messageRef = db.collection("conversations")
        .document(conversationId)
        .collection("messages")
        .document()
    
    let message = Message(
        id: messageRef.documentID,
        senderId: currentUserId,
        content: content,
        timestamp: Date(),
        mediaUrl: nil,
        mediaType: nil,
        readBy: [currentUserId],
        deliveredTo: [currentUserId]
    )
    
    // 2. Write to Firestore
    try await messageRef.setData(message.toFirestoreData())
    
    // 3. Update conversation
    try await db.collection("conversations").document(conversationId).updateData([
        "lastMessage": content,
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    return message
}
```

### Observing Messages

```swift
import FirebaseFirestore

func observeMessages(conversationId: String) -> AsyncStream<Message> {
    let db = Firestore.firestore()
    
    return AsyncStream { continuation in
        let listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                
                for change in snapshot.documentChanges {
                    if change.type == .added, let message = Message(from: change.document) {
                        continuation.yield(message)
                    }
                }
            }
        
        continuation.onTermination = { _ in
            listener.remove()
        }
    }
}
```

### Updating Presence

```swift
import FirebaseFirestore

func setOnlineStatus(userId: String, isOnline: Bool) async throws {
    let db = Firestore.firestore()
    
    let presence = Presence(
        status: isOnline ? .online : .offline,
        lastSeen: Date(),
        typing: [:]
    )
    
    try await db.collection("presence").document(userId).setData(
        presence.toFirestoreData(),
        merge: true
    )
}
```

---

**Last Updated:** October 24, 2025

