# Firestore Quick Reference Card

Quick reference for Wutzup Firestore database operations.

---

## 🚀 Essential Commands

```bash
# Deploy
firebase deploy                              # Deploy everything
firebase deploy --only firestore:rules       # Rules only
firebase deploy --only firestore:indexes     # Indexes only
firebase deploy --only functions             # Functions only

# Emulator
firebase emulators:start                     # Start all emulators
firebase emulators:start --only firestore    # Firestore only

# Seed Data
python seed_database.py --emulator --clear   # Seed emulator
python seed_database.py --project-id ID      # Seed production

# Logs
firebase functions:log                       # View logs
firebase functions:log --tail               # Follow logs
firebase functions:log --only FUNCTION_NAME  # Specific function

# Project
firebase use PROJECT_ID                      # Switch project
firebase projects:list                       # List projects
```

---

## 📊 Collection Paths

```
/users/{userId}
/conversations/{conversationId}
/conversations/{conversationId}/messages/{messageId}
/presence/{userId}
/typing/{conversationId}
```

---

## 🔑 Common Queries

### Get User's Conversations
```swift
db.collection("conversations")
  .whereField("participantIds", arrayContains: userId)
  .order(by: "lastMessageTimestamp", descending: true)
  .limit(50)
```

### Get Messages in Conversation
```swift
db.collection("conversations")
  .document(conversationId)
  .collection("messages")
  .order(by: "timestamp")
  .limit(50)
```

### Get User Profile
```swift
db.collection("users")
  .document(userId)
  .getDocument()
```

### Listen to Presence
```swift
db.collection("presence")
  .document(userId)
  .addSnapshotListener { snapshot, error in
    // Handle presence updates
  }
```

### Get Typing Indicators
```swift
db.collection("typing")
  .document(conversationId)
  .addSnapshotListener { snapshot, error in
    // Handle typing updates
  }
```

---

## 💾 Create Operations

### Create User
```swift
let user: [String: Any] = [
  "id": userId,
  "email": email,
  "displayName": displayName,
  "createdAt": FieldValue.serverTimestamp()
]
try await db.collection("users").document(userId).setData(user)
```

### Create Conversation
```swift
let conversation: [String: Any] = [
  "id": conversationId,
  "participantIds": [user1Id, user2Id],
  "isGroup": false,
  "createdAt": FieldValue.serverTimestamp(),
  "updatedAt": FieldValue.serverTimestamp()
]
try await db.collection("conversations").document(conversationId).setData(conversation)
```

### Send Message
```swift
let message: [String: Any] = [
  "id": messageId,
  "senderId": currentUserId,
  "content": content,
  "timestamp": FieldValue.serverTimestamp(),
  "readBy": [currentUserId],
  "deliveredTo": [currentUserId]
]
try await db.collection("conversations")
  .document(conversationId)
  .collection("messages")
  .document(messageId)
  .setData(message)
```

---

## 📝 Update Operations

### Update Conversation
```swift
try await db.collection("conversations")
  .document(conversationId)
  .updateData([
    "lastMessage": content,
    "lastMessageTimestamp": FieldValue.serverTimestamp(),
    "updatedAt": FieldValue.serverTimestamp()
  ])
```

### Mark Message as Read
```swift
try await db.collection("conversations")
  .document(conversationId)
  .collection("messages")
  .document(messageId)
  .updateData([
    "readBy": FieldValue.arrayUnion([userId])
  ])
```

### Update Presence
```swift
try await db.collection("presence")
  .document(userId)
  .setData([
    "status": "online",
    "lastSeen": FieldValue.serverTimestamp()
  ], merge: true)
```

### Set Typing Indicator
```swift
try await db.collection("typing")
  .document(conversationId)
  .setData([
    "users.\(userId)": FieldValue.serverTimestamp()
  ], merge: true)
```

---

## 🔒 Security Rules Quick Check

```javascript
// Users: Read all, write own only
allow read: if isAuthenticated();
allow create/update: if isOwner(userId);

// Conversations: Participants only
allow read/write: if request.auth.uid in resource.data.participantIds;

// Messages: Participants only, must be sender to create
allow read: if isParticipant();
allow create: if isParticipant() && request.resource.data.senderId == request.auth.uid;

// Presence: Read all, write own only
allow read: if isAuthenticated();
allow write: if isOwner(userId);

// Typing: All authenticated users
allow read/write: if isAuthenticated();
```

---

## 🎯 Field Types

### User
```typescript
{
  id: string
  email: string
  displayName: string
  profileImageUrl?: string
  fcmToken?: string
  createdAt: timestamp
  lastSeen?: timestamp
}
```

### Conversation
```typescript
{
  id: string
  participantIds: string[]
  isGroup: boolean
  groupName?: string
  lastMessage?: string
  lastMessageTimestamp?: timestamp
  createdAt: timestamp
  updatedAt: timestamp
}
```

### Message
```typescript
{
  id: string
  senderId: string
  content: string
  timestamp: timestamp
  mediaUrl?: string
  mediaType?: 'image' | 'video'
  readBy: string[]
  deliveredTo: string[]
}
```

### Presence
```typescript
{
  status: 'online' | 'offline'
  lastSeen: timestamp
  typing: { [conversationId: string]: boolean }
}
```

---

## 🚨 Common Errors

### Permission Denied
```
Cause: Security rules blocking access
Fix: Check user is authenticated and is participant
```

### Index Required
```
Cause: Complex query needs index
Fix: Click URL in error or add to firestore.indexes.json
```

### Function Not Triggering
```
Cause: Function not deployed or trigger path wrong
Fix: firebase functions:list, check trigger path
```

### Emulator Connection Failed
```
Cause: Emulator not running or wrong host
Fix: firebase emulators:start, check iOS config
```

---

## 📱 iOS Emulator Config

```swift
#if DEBUG
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings

Auth.auth().useEmulator(withHost: "localhost", port: 9099)
#endif
```

---

## 🧪 Test Data

### Users
- user_alice (Alice Smith)
- user_bob (Bob Jones)
- user_charlie (Charlie Brown)
- user_diana (Diana Prince)

### Conversations
- conv_alice_bob (Alice & Bob)
- conv_alice_charlie (Alice & Charlie)
- conv_group_tech (Tech Team group)

---

## 🔍 Debug Checklist

- [ ] User authenticated?
- [ ] User is participant in conversation?
- [ ] Firestore rules deployed?
- [ ] Indexes built?
- [ ] Emulator running? (if testing locally)
- [ ] Function deployed? (if testing triggers)
- [ ] Check logs: `firebase functions:log`
- [ ] Check Firebase Console

---

## 💡 Best Practices

✅ **DO:**
- Use `FieldValue.serverTimestamp()` for timestamps
- Check authentication before operations
- Use batched writes for atomic operations
- Listen to real-time updates
- Handle offline scenarios
- Cache data locally with SwiftData
- Use pagination for large collections

❌ **DON'T:**
- Use client-side timestamps
- Skip authentication checks
- Ignore security rules
- Fetch all documents at once
- Ignore offline errors
- Trust client data without validation
- Create infinite listeners

---

## 📚 Documentation Links

- [SCHEMA.md](./SCHEMA.md) - Complete schema
- [SWIFT_TYPES.md](./SWIFT_TYPES.md) - iOS types
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment
- [README.md](./README.md) - Setup guide

---

## 🆘 Quick Help

```bash
# Stuck? Try these:
firebase functions:log --tail        # Check what's happening
firebase emulators:start             # Test locally first
python seed_database.py --emulator   # Fresh test data
firebase deploy --only firestore     # Redeploy rules
```

---

**Last Updated:** October 21, 2025  
**Print this for quick reference during development!** 📋

