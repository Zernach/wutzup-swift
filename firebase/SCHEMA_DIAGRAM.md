# Firestore Schema Visual Diagrams

This document provides visual representations of the Firestore database schema.

## Collection Hierarchy

```mermaid
graph TD
    A[Firestore Database] --> B[users/]
    A --> C[conversations/]
    A --> D[presence/]
    A --> E[typing/]
    
    C --> F[messages/ subcollection]
    
    B --> B1["{userId}"]
    C --> C1["{conversationId}"]
    D --> D1["{userId}"]
    E --> E1["{conversationId}"]
    
    F --> F1["{messageId}"]
    
    style A fill:#ff6b6b
    style B fill:#4ecdc4
    style C fill:#4ecdc4
    style D fill:#4ecdc4
    style E fill:#4ecdc4
    style F fill:#95e1d3
```

## Users Collection Structure

```mermaid
erDiagram
    USERS {
        string id PK
        string email
        string displayName
        string profileImageUrl
        string fcmToken
        timestamp createdAt
        timestamp lastSeen
    }
```

## Conversations & Messages Structure

```mermaid
erDiagram
    CONVERSATIONS {
        string id PK
        array participantIds
        boolean isGroup
        string groupName
        string groupImageUrl
        string lastMessage
        timestamp lastMessageTimestamp
        timestamp createdAt
        timestamp updatedAt
    }
    
    MESSAGES {
        string id PK
        string senderId FK
        string content
        timestamp timestamp
        string mediaUrl
        string mediaType
        array readBy
        array deliveredTo
    }
    
    CONVERSATIONS ||--o{ MESSAGES : "has many"
```

## Presence & Typing Structure

```mermaid
erDiagram
    PRESENCE {
        string userId PK
        string status
        timestamp lastSeen
        map typing
    }
    
    TYPING {
        string conversationId PK
        map users
    }
```

## Data Flow: Sending a Message

```mermaid
sequenceDiagram
    participant iOS as iOS App
    participant FS as Firestore
    participant CF as Cloud Functions
    participant FCM as Firebase Cloud Messaging
    participant Recipient as Recipient Device
    
    iOS->>FS: 1. Write message to /conversations/{id}/messages/{id}
    FS->>iOS: 2. Confirm write
    iOS->>FS: 3. Update conversation.lastMessage
    FS-->>CF: 4. Trigger on_message_created
    CF->>FS: 5. Get recipient FCM tokens
    CF->>FCM: 6. Send push notification
    FCM->>Recipient: 7. Deliver notification
    FS-->>iOS: 8. Real-time listener updates (sender)
    FS-->>Recipient: 9. Real-time listener updates (recipient)
```

## Data Flow: Real-Time Messaging

```mermaid
sequenceDiagram
    participant User1 as User 1 (iOS)
    participant FS as Firestore
    participant User2 as User 2 (iOS)
    
    Note over User1,User2: Both users have active listeners
    
    User1->>FS: 1. sendMessage()
    FS->>User1: 2. Optimistic update
    FS-->>User1: 3. Listener: message confirmed
    FS-->>User2: 4. Listener: new message
    User2->>User2: 5. Display message
    User2->>FS: 6. Mark as read
    FS-->>User1: 7. Listener: read receipt
```

## Data Flow: Offline Support

```mermaid
sequenceDiagram
    participant iOS as iOS App
    participant SD as SwiftData
    participant FS as Firestore SDK
    participant Server as Firestore Server
    
    Note over iOS,Server: User goes offline
    
    iOS->>SD: 1. Save message locally
    iOS->>FS: 2. Write to Firestore (queued)
    FS->>FS: 3. Queue write in offline cache
    iOS->>iOS: 4. Show message (status: pending)
    
    Note over iOS,Server: Network returns
    
    FS->>Server: 5. Send queued writes
    Server->>FS: 6. Confirm writes
    FS-->>iOS: 7. Listener triggers update
    iOS->>SD: 8. Update local status
    iOS->>iOS: 9. Update UI (status: sent)
```

## Security Rules Structure

```mermaid
graph TD
    A[Security Rules] --> B[Users]
    A --> C[Conversations]
    A --> D[Messages]
    A --> E[Presence]
    A --> F[Typing]
    
    B --> B1[Read: Any authenticated]
    B --> B2[Write: Owner only]
    
    C --> C1[Read: Participants only]
    C --> C2[Write: Participants only]
    
    D --> D1[Read: Participants only]
    D --> D2[Create: Must be sender]
    D --> D3[Update: For read receipts]
    
    E --> E1[Read: Any authenticated]
    E --> E2[Write: Owner only]
    
    F --> F1[Read: Any authenticated]
    F --> F2[Write: Any authenticated]
    
    style A fill:#ff6b6b
    style B fill:#4ecdc4
    style C fill:#4ecdc4
    style D fill:#4ecdc4
    style E fill:#4ecdc4
    style F fill:#4ecdc4
```

## Indexes Structure

```mermaid
graph LR
    A[Firestore Indexes] --> B[Conversations Index]
    A --> C[Messages Indexes]
    
    B --> B1["participantIds (array-contains)"]
    B --> B2["lastMessageTimestamp (desc)"]
    
    C --> C1["timestamp (asc)"]
    C --> C2["timestamp (desc)"]
    C --> C3["senderId + timestamp"]
    
    style A fill:#ff6b6b
    style B fill:#4ecdc4
    style C fill:#4ecdc4
```

## Conversation Types

```mermaid
graph TD
    A[Conversation] --> B{isGroup?}
    
    B -->|false| C[One-on-One Chat]
    B -->|true| D[Group Chat]
    
    C --> C1["participantIds: 2 users"]
    C --> C2["No groupName"]
    C --> C3["Display: Other user's name"]
    
    D --> D1["participantIds: 3+ users"]
    D --> D2["Has groupName"]
    D --> D3["Display: Group name"]
    
    style A fill:#ff6b6b
    style B fill:#ffe66d
    style C fill:#4ecdc4
    style D fill:#4ecdc4
```

## Message Status Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Sending: User taps Send
    Sending --> Sent: Firestore confirms
    Sending --> Failed: Network error
    Sent --> Delivered: Recipient receives
    Delivered --> Read: Recipient opens chat
    Failed --> Sending: User retries
    Read --> [*]
```

## User Presence States

```mermaid
stateDiagram-v2
    [*] --> Offline: App closed
    Offline --> Online: App opens
    Online --> Offline: App closes
    Online --> Online: App active
    
    note right of Online
        Update lastSeen timestamp
        Set status = "online"
    end note
    
    note right of Offline
        Set status = "offline"
        Store lastSeen timestamp
    end note
```

## Complete Entity Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ CONVERSATION : participates
    USER ||--o{ MESSAGE : sends
    USER ||--|| PRESENCE : has
    CONVERSATION ||--o{ MESSAGE : contains
    CONVERSATION ||--o| TYPING : has
    
    USER {
        string id PK
        string email
        string displayName
        string profileImageUrl
        string fcmToken
        timestamp createdAt
        timestamp lastSeen
    }
    
    CONVERSATION {
        string id PK
        array participantIds FK
        boolean isGroup
        string groupName
        string groupImageUrl
        string lastMessage
        timestamp lastMessageTimestamp
        timestamp createdAt
        timestamp updatedAt
    }
    
    MESSAGE {
        string id PK
        string senderId FK
        string content
        timestamp timestamp
        string mediaUrl
        string mediaType
        array readBy
        array deliveredTo
    }
    
    PRESENCE {
        string userId PK
        string status
        timestamp lastSeen
        map typing
    }
    
    TYPING {
        string conversationId PK
        map users
    }
```

## Cloud Functions Triggers

```mermaid
graph LR
    A[Firestore Events] --> B[on_message_created]
    A --> C[on_conversation_created]
    A --> D[on_presence_updated]
    
    B --> B1[Get conversation]
    B --> B2[Get sender info]
    B --> B3[Get recipients]
    B --> B4[Send FCM notifications]
    
    C --> C1[Log creation]
    
    D --> D1[Log presence change]
    
    style A fill:#ff6b6b
    style B fill:#4ecdc4
    style C fill:#4ecdc4
    style D fill:#4ecdc4
```

## Data Synchronization Pattern

```mermaid
graph TD
    A[iOS App] --> B{Network Available?}
    
    B -->|Yes| C[Write to Firestore]
    B -->|No| D[Write to SwiftData]
    
    C --> E[Firestore SDK]
    D --> F[Offline Queue]
    
    E --> G[Firestore Server]
    F --> H{Network Restored?}
    
    H -->|Yes| E
    H -->|No| F
    
    G --> I[Real-time Listener]
    I --> J[Update SwiftData]
    J --> K[Update UI]
    
    style A fill:#ff6b6b
    style B fill:#ffe66d
    style E fill:#4ecdc4
    style G fill:#95e1d3
```

## Query Patterns

```mermaid
graph TD
    A[Common Queries] --> B[Get User Conversations]
    A --> C[Get Messages]
    A --> D[Get User Profile]
    A --> E[Check Presence]
    
    B --> B1["Query: participantIds array-contains userId"]
    B --> B2["Order: lastMessageTimestamp desc"]
    B --> B3["Limit: 50"]
    
    C --> C1["Path: conversations/{id}/messages"]
    C --> C2["Order: timestamp asc"]
    C --> C3["Limit: 50"]
    
    D --> D1["Get: users/{userId}"]
    
    E --> E1["Get: presence/{userId}"]
    E --> E2["Listen: Real-time updates"]
    
    style A fill:#ff6b6b
    style B fill:#4ecdc4
    style C fill:#4ecdc4
    style D fill:#4ecdc4
    style E fill:#4ecdc4
```

---

## Legend

- 🔴 Red: Main entities/systems
- 🔵 Blue: Collections/sub-systems
- 🟢 Green: Subcollections/nested data
- 🟡 Yellow: Decision points

---

**Last Updated:** October 21, 2025

