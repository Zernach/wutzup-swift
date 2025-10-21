# Wutzup - Technical Architecture (Firebase)

## Architecture Overview

Wutzup follows a **Firebase-first architecture** with offline-first principles. The iOS app uses Firebase SDK for backend services and SwiftData for local persistence.

```
┌─────────────────────────────────────────────────────┐
│                iOS App (Swift + SwiftUI)            │
│  ┌───────────────────────────────────────────────┐  │
│  │              UI Layer (SwiftUI)               │  │
│  └───────────────────────┬───────────────────────┘  │
│  ┌───────────────────────▼───────────────────────┐  │
│  │         View Models / State Management        │  │
│  └───────────────────────┬───────────────────────┘  │
│  ┌───────────────────────▼───────────────────────┐  │
│  │            Business Logic Layer               │  │
│  │  • Message Service  • Presence Service        │  │
│  │  • Chat Service     • Notification Service    │  │
│  └────────────┬──────────────────┬────────────────┘  │
│  ┌────────────▼────────┐  ┌──────▼──────────────┐  │
│  │  Local Persistence  │  │   Firebase Layer    │  │
│  │    (SwiftData)      │  │  • Firestore SDK    │  │
│  │                     │  │  • Auth SDK         │  │
│  │                     │  │  • Storage SDK      │  │
│  │                     │  │  • FCM SDK          │  │
│  └─────────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────┐
│                   Firebase Services                 │
│  ┌─────────────────────────────────────────────┐   │
│  │              Firebase Auth                  │   │
│  │         (User Authentication)               │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │            Cloud Firestore                  │   │
│  │    (Real-time NoSQL Database)               │   │
│  │  • users collection                         │   │
│  │  • conversations collection                 │   │
│  │  • messages subcollection                   │   │
│  │  • presence collection                      │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │          Firebase Storage                   │   │
│  │        (File/Image Storage)                 │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │        Cloud Functions (Node.js)            │   │
│  │  • sendNotification                         │   │
│  │  • onMessageCreated (trigger)               │   │
│  │  • onUserPresenceChanged (trigger)          │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │   Firebase Cloud Messaging (FCM)            │   │
│  │      (Push Notifications via APNs)          │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## Why Firebase? 🚀

### Key Advantages
1. **No Backend to Build** - Firestore + Cloud Functions handles everything
2. **Real-Time by Default** - Built-in real-time listeners (no WebSocket code needed)
3. **Offline-First Native** - Firestore has automatic offline persistence
4. **Authentication Built-In** - Firebase Auth handles login/signup
5. **Scalable** - Google infrastructure, handles millions of users
6. **Push Notifications Integrated** - FCM → APNs automatically
7. **File Storage Included** - Firebase Storage for images
8. **Faster MVP** - Focus on iOS app, not backend infrastructure

### Trade-offs
- **Vendor Lock-in** - Tied to Google/Firebase ecosystem
- **Cost at Scale** - Can get expensive with high usage
- **Less Control** - Can't customize backend as much
- **NoSQL Learning Curve** - Different from SQL databases

**For MVP**: Benefits far outweigh drawbacks. Can migrate later if needed.

---

## iOS App Architecture

### Architectural Pattern: MVVM (Model-View-ViewModel)

Same pattern as before, but services now use Firebase SDK instead of custom API client.

#### 1. UI Layer (SwiftUI)
No changes from original design.

**Key Components:**
- `ChatListView` - Display all conversations
- `ConversationView` - Individual chat interface
- `MessageInputView` - Text input and send controls
- `ProfileView` - User profile display/editing
- `SettingsView` - App settings

#### 2. ViewModel Layer
No structural changes, but now observes Firestore real-time updates.

**Key ViewModels:**
- `ChatListViewModel` - Manages conversation list state
- `ConversationViewModel` - Handles single chat logic
- `MessageInputViewModel` - Message composition state
- `ProfileViewModel` - User profile management

#### 3. Business Logic Layer (Services)

##### MessageService
```swift
protocol MessageService {
    func sendMessage(_ message: Message) async throws
    func fetchMessages(for conversationId: String, limit: Int) async throws -> [Message]
    func observeMessages(for conversationId: String) -> AsyncStream<Message>
    func markAsRead(_ messageId: String) async throws
}

// Firebase Implementation
class FirebaseMessageService: MessageService {
    private let db = Firestore.firestore()
    
    func sendMessage(_ message: Message) async throws {
        // Write to Firestore
        let conversationRef = db.collection("conversations").document(message.conversationId)
        try await conversationRef.collection("messages").document(message.id).setData([
            "id": message.id,
            "senderId": message.senderId,
            "content": message.content,
            "timestamp": Timestamp(date: message.timestamp),
            "status": message.status.rawValue
        ])
        
        // Update conversation's lastMessage
        try await conversationRef.updateData([
            "lastMessage": message.content,
            "lastMessageTimestamp": Timestamp(date: message.timestamp)
        ])
    }
    
    func observeMessages(for conversationId: String) -> AsyncStream<Message> {
        AsyncStream { continuation in
            let listener = db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    
                    for change in snapshot!.documentChanges {
                        if change.type == .added {
                            let message = Message(from: change.document)
                            continuation.yield(message)
                        }
                    }
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
```

##### ChatService
```swift
protocol ChatService {
    func createConversation(with userIds: [String]) async throws -> Conversation
    func fetchConversations() async throws -> [Conversation]
    func observeConversations() -> AsyncStream<Conversation>
}

class FirebaseChatService: ChatService {
    private let db = Firestore.firestore()
    
    func createConversation(with userIds: [String]) async throws -> Conversation {
        let conversationRef = db.collection("conversations").document()
        
        let conversation = Conversation(
            id: conversationRef.documentID,
            participantIds: userIds,
            isGroup: userIds.count > 2,
            createdAt: Date()
        )
        
        try await conversationRef.setData([
            "id": conversation.id,
            "participantIds": userIds,
            "isGroup": conversation.isGroup,
            "createdAt": Timestamp(date: conversation.createdAt)
        ])
        
        return conversation
    }
    
    func observeConversations() -> AsyncStream<Conversation> {
        AsyncStream { continuation in
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let listener = db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .order(by: "lastMessageTimestamp", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    
                    let conversations = documents.compactMap { Conversation(from: $0) }
                    // Yield all conversations
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
```

##### PresenceService
```swift
protocol PresenceService {
    func setOnline() async throws
    func setOffline() async throws
    func observePresence(for userId: String) -> AsyncStream<UserStatus>
    func startTyping(in conversationId: String) async throws
    func stopTyping(in conversationId: String) async throws
}

class FirebasePresenceService: PresenceService {
    private let db = Firestore.firestore()
    
    func setOnline() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        try await db.collection("presence").document(userId).setData([
            "status": "online",
            "lastSeen": Timestamp(date: Date())
        ], merge: true)
    }
    
    func observePresence(for userId: String) -> AsyncStream<UserStatus> {
        AsyncStream { continuation in
            let listener = db.collection("presence")
                .document(userId)
                .addSnapshotListener { snapshot, error in
                    guard let data = snapshot?.data(),
                          let status = data["status"] as? String else { return }
                    
                    let userStatus = UserStatus(rawValue: status) ?? .offline
                    continuation.yield(userStatus)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
```

##### AuthenticationService
```swift
protocol AuthenticationService {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, displayName: String) async throws -> User
    func logout() async throws
    var currentUser: User? { get }
}

class FirebaseAuthenticationService: AuthenticationService {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    func register(email: String, password: String, displayName: String) async throws -> User {
        // Create Firebase Auth user
        let authResult = try await auth.createUser(withEmail: email, password: password)
        
        // Create user document in Firestore
        let user = User(
            id: authResult.user.uid,
            email: email,
            displayName: displayName
        )
        
        try await db.collection("users").document(user.id).setData([
            "id": user.id,
            "email": user.email,
            "displayName": user.displayName,
            "createdAt": Timestamp(date: Date())
        ])
        
        return user
    }
    
    func login(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        
        // Fetch user profile from Firestore
        let snapshot = try await db.collection("users").document(authResult.user.uid).getDocument()
        return User(from: snapshot)
    }
    
    func logout() async throws {
        try auth.signOut()
    }
    
    var currentUser: User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        // Fetch from cache or Firestore
        return nil // Implement caching
    }
}
```

##### NotificationService
```swift
protocol NotificationService {
    func requestPermission() async throws -> Bool
    func registerDeviceToken(_ token: Data) async throws
    func handleNotification(_ notification: UNNotification)
}

class FirebaseNotificationService: NotificationService {
    private let messaging = Messaging.messaging()
    private let db = Firestore.firestore()
    
    func registerDeviceToken(_ token: Data) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Firebase handles token registration automatically
        // Just store it in Firestore for reference
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        try await db.collection("users").document(userId).updateData([
            "fcmToken": tokenString,
            "lastTokenUpdate": Timestamp(date: Date())
        ])
    }
}
```

#### 4. Data Layer

##### Local Persistence (SwiftData)

**Why SwiftData over Core Data?**
- Modern Swift-first API (no Objective-C)
- Simpler to use with SwiftUI
- Better type safety
- Less boilerplate code
- iOS 16+ only (acceptable trade-off)

**Data Models:**

```swift
import SwiftData

@Model
class MessageModel {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var content: String
    var timestamp: Date
    var status: String // sending, sent, delivered, read
    var isFromCurrentUser: Bool
    var mediaUrl: String?
    
    init(id: String, conversationId: String, senderId: String, content: String, 
         timestamp: Date, status: String, isFromCurrentUser: Bool, mediaUrl: String? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.isFromCurrentUser = isFromCurrentUser
        self.mediaUrl = mediaUrl
    }
}

@Model
class ConversationModel {
    @Attribute(.unique) var id: String
    var participantIds: [String]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var unreadCount: Int
    var isGroup: Bool
    var groupName: String?
    
    init(id: String, participantIds: [String], lastMessage: String? = nil,
         lastMessageTimestamp: Date? = nil, unreadCount: Int = 0,
         isGroup: Bool = false, groupName: String? = nil) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
        self.isGroup = isGroup
        self.groupName = groupName
    }
}

@Model
class UserModel {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String
    var profileImageUrl: String?
    var status: String // online, offline
    var lastSeen: Date?
    
    init(id: String, email: String, displayName: String, profileImageUrl: String? = nil,
         status: String = "offline", lastSeen: Date? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.status = status
        self.lastSeen = lastSeen
    }
}
```

**SwiftData Container Setup:**

```swift
import SwiftData

@main
struct WutzupApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: MessageModel.self, ConversationModel.self, UserModel.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

##### Firebase Layer (Firestore SDK)

**Firestore Collections Structure:**

```
firestore/
├── users/                          # User profiles
│   └── {userId}/
│       ├── id: String
│       ├── email: String
│       ├── displayName: String
│       ├── profileImageUrl: String?
│       ├── fcmToken: String?
│       └── createdAt: Timestamp
│
├── conversations/                  # Conversations
│   └── {conversationId}/
│       ├── id: String
│       ├── participantIds: [String]
│       ├── isGroup: Boolean
│       ├── groupName: String?
│       ├── lastMessage: String?
│       ├── lastMessageTimestamp: Timestamp?
│       ├── createdAt: Timestamp
│       │
│       └── messages/               # Messages subcollection
│           └── {messageId}/
│               ├── id: String
│               ├── senderId: String
│               ├── content: String
│               ├── timestamp: Timestamp
│               ├── mediaUrl: String?
│               └── readBy: [String]  # Array of userIds
│
├── presence/                       # User presence/status
│   └── {userId}/
│       ├── status: String          # online, offline
│       ├── lastSeen: Timestamp
│       └── typing: Map             # conversationId -> Boolean
│
└── typing/                         # Typing indicators (ephemeral)
    └── {conversationId}/
        └── users: Map              # userId -> timestamp
```

**Firestore Security Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      allow create: if isAuthenticated() && 
        request.auth.uid in request.resource.data.participantIds;
      allow update: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isAuthenticated() && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        allow create: if isAuthenticated() && 
          request.auth.uid == request.resource.data.senderId;
      }
    }
    
    // Presence collection
    match /presence/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isOwner(userId);
    }
    
    // Typing indicators
    match /typing/{conversationId} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

---

## Data Flow Patterns

### 1. Sending a Message (Optimistic Update + Firestore)

```
User Types → MessageInputView → ConversationViewModel
                                        ↓
                              Create Local Message (UUID)
                                        ↓
                         ┌──────────────┴────────────────┐
                         ↓                               ↓
              Save to SwiftData             Firebase MessageService
              (status: .sending)             sendMessage(message)
                         ↓                               ↓
                   Update UI                    Firestore.setData()
                  (show message)                        ↓
                                              Firestore confirms write
                                                        ↓
                                         Real-time listener triggers
                                                        ↓
                                         Update SwiftData (status: .sent)
                                                        ↓
                                            Update UI (✓✓ indicator)
```

### 2. Receiving a Message (Real-Time via Firestore Listener)

```
Other User Sends → Firestore receives write
                            ↓
                   Firestore triggers snapshot listener
                            ↓
                   MessageService.observeMessages()
                            ↓
                   AsyncStream yields new message
                            ↓
                   ConversationViewModel receives
                            ↓
                   Save to SwiftData
                            ↓
                   Update @Published messages array
                            ↓
                   SwiftUI View automatically updates
```

### 3. Offline Message Queue (Firestore Handles This!)

**Good News**: Firestore has built-in offline persistence and queue!

```
No Network → MessageService.sendMessage()
                      ↓
           Firestore.setData() (write pending)
                      ↓
           Firestore SDK queues write locally
           (status: pending in Firestore SDK)
                      ↓
            Save to SwiftData (status: .pending)
                      ↓
            Network Becomes Available
                      ↓
         Firestore SDK auto-sends queued writes
                      ↓
         Firestore confirms, listener updates
                      ↓
        Update SwiftData (status: .sent)
```

**Enable Firestore Offline Persistence:**
```swift
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true // Default is true
settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
Firestore.firestore().settings = settings
```

---

## Firebase Cloud Functions

Cloud Functions handle server-side logic like sending push notifications.

### Structure

```
functions/
├── src/
│   ├── index.ts                    # Main entry point
│   ├── notifications.ts            # Push notification logic
│   └── triggers.ts                 # Firestore triggers
├── package.json
└── tsconfig.json
```

### Example: Send Push Notification on New Message

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onMessageCreated = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const conversationId = context.params.conversationId;
    
    // Get conversation to find recipients
    const conversationDoc = await admin.firestore()
      .collection('conversations')
      .doc(conversationId)
      .get();
    
    const conversation = conversationDoc.data();
    if (!conversation) return;
    
    // Get sender info
    const senderDoc = await admin.firestore()
      .collection('users')
      .doc(message.senderId)
      .get();
    const sender = senderDoc.data();
    
    // Send notification to each participant (except sender)
    const recipients = conversation.participantIds.filter(
      (id: string) => id !== message.senderId
    );
    
    for (const recipientId of recipients) {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(recipientId)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) continue;
      
      // Send push notification
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: sender?.displayName || 'New Message',
          body: message.content,
        },
        data: {
          conversationId: conversationId,
          messageId: message.id,
          type: 'new_message',
        },
        apns: {
          payload: {
            aps: {
              badge: 1, // Increment badge
              sound: 'default',
            },
          },
        },
      });
    }
  });

// Presence tracking on disconnect
export const onUserDisconnect = functions.auth.user().onDelete(async (user) => {
  await admin.firestore()
    .collection('presence')
    .doc(user.uid)
    .update({
      status: 'offline',
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    });
});
```

---

## Key Design Decisions

### 1. Firebase Instead of Custom Backend
**Decision**: Use Firebase for all backend services

**Rationale**:
- No backend code to write/maintain
- Real-time built-in (no WebSocket complexity)
- Offline support automatic
- Faster MVP development (weeks instead of months)
- Google infrastructure scales automatically

### 2. SwiftData Instead of Core Data
**Decision**: Use SwiftData for local persistence

**Rationale**:
- Modern Swift-first API
- Better SwiftUI integration
- Less boilerplate
- Type-safe
- Future-proof (Apple's new direction)

**Trade-off**: Requires iOS 16+ (acceptable for new app)

### 3. Firestore Real-Time Listeners Instead of WebSocket
**Decision**: Use Firestore's built-in real-time listeners

**Rationale**:
- No WebSocket server to build
- Automatic reconnection
- Offline queue built-in
- More reliable (Google's infrastructure)

### 4. Firebase Cloud Functions for Server Logic
**Decision**: Use Cloud Functions for notifications and triggers

**Rationale**:
- Serverless (no server management)
- Automatic scaling
- Pay only for what you use
- Easy deployment

### 5. Firebase Storage for Images
**Decision**: Use Firebase Storage instead of S3

**Rationale**:
- Integrated with Firebase ecosystem
- Simpler authentication (uses Firebase Auth tokens)
- Built-in CDN
- Easier to set up than S3

---

## Development Phases (Updated for Firebase)

### Phase 1: Firebase + iOS Setup (Week 1)
- Create Firebase project
- Setup Firestore database
- Configure Firebase Auth
- Setup FCM for push notifications
- Create iOS project with SwiftUI
- Add Firebase SDK via SPM
- Configure SwiftData models

### Phase 2: Authentication (Week 1-2)
- Firebase Auth integration
- Login/Register UI
- AuthenticationService implementation
- User profile creation in Firestore

### Phase 3: Core Messaging (Week 2-4)
- Firestore collections (conversations, messages)
- MessageService with Firestore
- ChatService with real-time listeners
- SwiftData local persistence
- Message list UI
- Send message flow (optimistic updates)

### Phase 4: Offline Support (Week 4-5)
- Enable Firestore offline persistence
- Test offline scenarios
- Handle network transitions
- SwiftData sync with Firestore

### Phase 5: Real-Time Features (Week 5-6)
- Presence tracking in Firestore
- Typing indicators
- Read receipts (readBy array)
- UI updates

### Phase 6: Media Support (Week 6)
- Firebase Storage integration
- Image upload/download
- Image picker
- Display images in messages

### Phase 7: Group Chat (Week 7)
- Multi-participant conversations
- Group creation UI
- Group message delivery
- Member management

### Phase 8: Push Notifications (Week 7-8)
- Cloud Functions for FCM
- iOS notification handling
- Badge counts
- Notification actions

### Phase 9-12: Polish, Testing, Deploy (Week 8-10)
- UI polish
- All test scenarios
- Performance optimization
- App Store submission

---

## Firebase Pricing Considerations

### Free Tier (Spark Plan)
- **Firestore**: 50K reads/day, 20K writes/day, 20K deletes/day
- **Authentication**: Unlimited
- **Cloud Functions**: 125K invocations/month
- **Cloud Storage**: 5GB storage, 1GB/day download
- **FCM**: Unlimited

**Sufficient for MVP and initial users (< 100 daily active users)**

### Paid Tier (Blaze Plan - Pay As You Go)
- **Firestore**: $0.06 per 100K reads, $0.18 per 100K writes
- **Cloud Functions**: $0.40 per million invocations
- **Storage**: $0.026 per GB/month
- **Bandwidth**: $0.12 per GB

**Required for production with many users**

---

## Testing Strategy

### Firebase Emulator Suite (Local Testing)
```bash
firebase emulators:start --only firestore,auth,functions
```

Benefits:
- Test locally without hitting production
- Faster development
- Free (no Firebase costs)
- Reliable test data

### iOS Testing
- Unit tests: Mock Firebase services
- Integration tests: Use Firebase emulator
- UI tests: Use test Firebase project

---

## Security Best Practices

### Firestore Security Rules
- Never allow open read/write access
- Always check authentication
- Validate user is participant in conversation
- Use server timestamps (can't be spoofed)

### Firebase Auth
- Email verification (optional but recommended)
- Password strength requirements
- Rate limiting on auth endpoints

### iOS Security
- Store Firebase config in secure location
- Use Keychain for sensitive data (if needed)
- Certificate pinning (optional)

---

## Conclusion

Firebase architecture dramatically simplifies the MVP:
- ✅ No backend to build
- ✅ Real-time by default
- ✅ Offline support built-in
- ✅ Authentication included
- ✅ Push notifications integrated
- ✅ File storage ready
- ✅ Scales automatically

**Result**: Focus 100% on iOS app, ship MVP in 6-8 weeks instead of 10-12 weeks.

---

**Last Updated**: October 21, 2025
