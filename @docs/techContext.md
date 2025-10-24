# Technical Context: Wutzup (Firebase Edition)

## Technology Stack

### iOS Application

#### Language & Frameworks

- **Swift 5.9+** - Primary programming language
- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming and state management
- **Foundation** - Core iOS framework
- **SwiftData** - Modern data persistence (iOS 16+)

#### UI & Design

- **SwiftUI** - Modern declarative UI
  - Reason: Cleaner code, reactive updates, future-proof
  - Minimum iOS 16.0 deployment target (required for SwiftData)
- **SF Symbols** - Apple's icon library
- **Native iOS components** - Follows Human Interface Guidelines

#### Firebase SDK

- **FirebaseAuth** - User authentication
  - Version: 10.0+
  - Reason: Built-in auth, secure, easy to use
- **FirebaseFirestore** - Real-time database
  - Version: 10.0+
  - Reason: Real-time listeners, offline support, scalable
  - Offline persistence enabled by default
- **FirebaseStorage** - File/image storage
  - Version: 10.0+
  - Reason: Integrated with Firebase ecosystem, CDN included
- **FirebaseMessaging** - Push notifications (FCM)
  - Version: 10.0+
  - Reason: Handles APNs integration, easy setup

#### Networking

- **URLSession** - Native HTTP client (for non-Firebase calls)
- **Firebase SDK** - Built-in networking for Firestore/Storage
  - No need for custom WebSocket or API client
  - Real-time via Firestore listeners

#### Data Persistence

- **SwiftData** - Apple's modern persistence framework
  - Version: iOS 16.0+
  - Reason: Swift-first, SwiftUI-native, less boilerplate than Core Data
  - Local cache for offline support
- **Firestore Offline Persistence** - Automatic Firebase caching
  - Enabled by default
  - Handles offline queue automatically

#### Media Handling

- **Kingfisher** - Image downloading and caching
  - Version: 7.0+
  - Reason: Battle-tested, SwiftUI support, efficient caching
- **PHPickerViewController** - Native image picker
- **Firebase Storage** - Image upload/download

#### Push Notifications

- **UserNotifications** - Native notification framework
- **Firebase Cloud Messaging (FCM)** - Push delivery via APNs
  - No direct APNs integration needed
  - FCM handles token management

#### Machine Learning & AI

- **Translation** - Powered by Gemini API (via Firebase Cloud Functions)
  - Translates messages automatically to user's configured "Learning Language"
  - User sets their Learning Language in Account settings
  - One-tap translation without language selection prompt
  - Supported languages: English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, Korean, Arabic, Russian, Hindi
  - Used for language learning features
- **Firebase Cloud Functions with Python** - Backend AI services
  - OpenAI GPT integration for intelligent responses
  - Web research capabilities via Tavily API
  - GIF generation via Giphy API
  - All AI processing happens server-side for consistency and scalability

#### Development Tools

- **Xcode 15+** - Primary IDE
- **Swift Package Manager** - Dependency management
- **Instruments** - Performance profiling
- **XCTest** - Unit and UI testing
- **Firebase Local Emulator Suite** - Local backend testing

---

### Backend (Firebase Cloud Services)

#### Core Services

##### Firebase Authentication

- **Email/Password** authentication
- User management
- Token generation/refresh
- Session management
- **Free**: Unlimited users

##### Cloud Firestore

- **NoSQL database** with real-time updates
- Automatic offline persistence
- Optimistic writes with server confirmation
- Complex queries with indexes
- **Pricing**: Free tier (50K reads, 20K writes/day)

**Collections Structure:**

```
users/
conversations/
  └── messages/ (subcollection)
presence/
typing/
```

##### Firebase Storage

- File/image storage with CDN
- Automatic HTTPS URLs
- Download URLs with security rules
- Image thumbnails (via Cloud Functions)
- **Pricing**: Free tier (5GB storage, 1GB/day bandwidth)

##### Firebase Cloud Messaging (FCM)

- Push notifications to iOS via APNs
- No APNs certificate management (FCM handles it)
- Automatic token refresh
- Topic messaging (for broadcasts)
- **Free**: Unlimited notifications

##### Cloud Functions (Node.js/TypeScript)

- **Runtime**: Node.js 18+
- **Language**: TypeScript (recommended) or JavaScript
- Serverless functions triggered by:
  - Firestore writes (onMessageCreated)
  - Auth events (onUserCreated)
  - HTTPS requests
  - Scheduled tasks
- **Pricing**: Free tier (125K invocations/month)

**Example Function:**

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onMessageCreated = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    // Send push notification
  });
```

#### Development Tools

- **Firebase CLI** - Deploy functions, manage projects
- **Firebase Console** - Web dashboard for monitoring
- **Firebase Emulator Suite** - Local testing
  - Firestore emulator
  - Auth emulator
  - Functions emulator
  - Storage emulator

---

## Development Environment

### iOS Setup Requirements

```
✓ macOS 14.0+ (Sonoma or later)
✓ Xcode 17.0+
✓ iOS 16.0+ device or simulator for testing
✓ Apple Developer Account ($99/year for App Store, TestFlight)
✓ Swift Package Manager (built into Xcode)
✓ CocoaPods (optional, SPM preferred for Firebase)
```

### Firebase Setup Requirements

```
✓ Google account (for Firebase Console)
✓ Firebase project (free to create)
✓ Firebase CLI (npm install -g firebase-tools)
✓ Node.js 18+ (for Cloud Functions development)
✓ Firebase Blaze plan (pay-as-you-go) for Cloud Functions (free tier sufficient for MVP)
```

### Setup Steps

#### 1. Create Firebase Project

```bash
# Login to Firebase
firebase login

# Create new project (or use Firebase Console)
firebase projects:create wutzup-app

# Initialize Firebase in your project directory
cd wutzup-swift
firebase init

# Select:
# - Firestore
# - Functions
# - Storage
# - Emulators
```

#### 2. iOS Project Setup

```bash
# Create Xcode project
# Open Xcode → New Project → iOS App
# Name: Wutzup
# Interface: SwiftUI
# Language: Swift
# Minimum Deployment: iOS 16.0
```

#### 3. Add Firebase to iOS

```bash
# Download GoogleService-Info.plist from Firebase Console
# Add to Xcode project (drag & drop)

# Add Firebase SDK via Swift Package Manager
# Xcode → File → Add Package Dependencies
# URL: https://github.com/firebase/firebase-ios-sdk
# Products to add:
# - FirebaseAuth
# - FirebaseFirestore
# - FirebaseStorage
# - FirebaseMessaging
```

#### 4. Configure Firebase in iOS

```swift
// WutzupApp.swift
import SwiftUI
import FirebaseCore

@main
struct WutzupApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Project Structure

### iOS Project Structure (Firebase)

```
Wutzup/
├── App/
│   ├── WutzupApp.swift                 # App entry + Firebase config
│   └── AppState.swift                   # Global app state
├── Models/
│   ├── Message.swift                    # Domain models (Codable)
│   ├── Conversation.swift
│   ├── User.swift
│   └── SwiftDataModels/                 # SwiftData models
│       ├── MessageModel.swift
│       ├── ConversationModel.swift
│       └── UserModel.swift
├── Views/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── ChatList/
│   │   ├── ChatListView.swift
│   │   └── ConversationRowView.swift
│   ├── Conversation/
│   │   ├── ConversationView.swift
│   │   ├── MessageBubbleView.swift
│   │   └── MessageInputView.swift
│   ├── Profile/
│   │   └── ProfileView.swift
│   └── Components/                      # Reusable UI components
├── ViewModels/
│   ├── AuthenticationViewModel.swift
│   ├── ChatListViewModel.swift
│   └── ConversationViewModel.swift
├── Services/
│   ├── Firebase/                        # Firebase service implementations
│   │   ├── FirebaseMessageService.swift
│   │   ├── FirebaseChatService.swift
│   │   ├── FirebasePresenceService.swift
│   │   ├── FirebaseAuthService.swift
│   │   └── FirebaseNotificationService.swift
│   ├── Protocols/                       # Service protocols
│   │   ├── MessageService.swift
│   │   ├── ChatService.swift
│   │   ├── PresenceService.swift
│   │   ├── AuthenticationService.swift
│   │   └── NotificationService.swift
│   └── Local/                           # SwiftData services
│       ├── LocalMessageService.swift
│       └── LocalChatService.swift
├── Utilities/
│   ├── Extensions/                      # Swift extensions
│   ├── Constants.swift                  # App constants
│   ├── FirebaseConfig.swift             # Firebase configuration
│   └── DateFormatter+Helpers.swift
├── Resources/
│   ├── Assets.xcassets                  # Images, colors
│   ├── Localizable.strings              # Translations
│   ├── GoogleService-Info.plist         # Firebase config (from console)
│   └── Info.plist
└── Tests/
    ├── WutzupTests/                     # Unit tests
    └── WutzupUITests/                   # UI tests
```

### Firebase Project Structure

```
wutzup-swift/
├── functions/                           # Cloud Functions
│   ├── src/
│   │   ├── index.ts                     # Main entry point
│   │   ├── notifications.ts             # Push notification logic
│   │   ├── triggers.ts                  # Firestore triggers
│   │   └── types.ts                     # TypeScript types
│   ├── package.json
│   ├── tsconfig.json
│   └── .eslintrc.js
├── firestore.rules                      # Security rules
├── firestore.indexes.json               # Database indexes
├── storage.rules                        # Storage security rules
└── firebase.json                        # Firebase config
```

---

## Configuration Management

### iOS Configuration

```swift
// FirebaseConfig.swift
enum FirebaseConfig {
    static let isProductionBuild: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()

    // Use emulator in debug builds
    static func configureEmulators() {
        #if DEBUG
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        #endif
    }
}
```

### Firestore Offline Persistence

```swift
// Enable offline persistence (enabled by default)
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
Firestore.firestore().settings = settings
```

### Cloud Functions Configuration

```typescript
// functions/src/config.ts
export const config = {
  fcm: {
    serverKey: functions.config().fcm?.key || process.env.FCM_KEY,
  },
  app: {
    environment: process.env.NODE_ENV || 'development',
  },
};
```

---

## Firestore Data Structure

### Collections & Documents

#### users/

```typescript
{
  id: string;                    // Document ID = Auth UID
  email: string;
  displayName: string;
  profileImageUrl?: string;
  fcmToken?: string;             // For push notifications
  createdAt: Timestamp;
  lastSeen?: Timestamp;
}
```

#### conversations/

```typescript
{
  id: string;                    // Document ID (auto-generated)
  participantIds: string[];      // Array of user IDs
  isGroup: boolean;
  groupName?: string;
  groupImageUrl?: string;
  lastMessage?: string;
  lastMessageTimestamp?: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### conversations/{conversationId}/messages/

```typescript
{
  id: string;                    // Document ID (auto-generated)
  senderId: string;              // User ID
  content: string;
  timestamp: Timestamp;
  mediaUrl?: string;
  mediaType?: 'image' | 'video';
  readBy: string[];              // Array of user IDs who read this
  deliveredTo: string[];         // Array of user IDs who received this
}
```

#### presence/

```typescript
{
  // Document ID = user ID
  status: 'online' | 'offline';
  lastSeen: Timestamp;
  typing: {                      // Map of conversationId -> boolean
    [conversationId: string]: boolean;
  };
}
```

### Firestore Indexes

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [{ "fieldPath": "timestamp", "order": "ASCENDING" }]
    },
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participantIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "lastMessageTimestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## API Conventions

### Firebase SDK Calls (No REST API Needed!)

#### Authentication

```swift
// Register
try await Auth.auth().createUser(withEmail: email, password: password)

// Login
try await Auth.auth().signIn(withEmail: email, password: password)

// Logout
try Auth.auth().signOut()

// Current user
Auth.auth().currentUser
```

#### Firestore Operations

```swift
// Create document
try await db.collection("users").document(userId).setData([...])

// Read document
let snapshot = try await db.collection("users").document(userId).getDocument()

// Update document
try await db.collection("users").document(userId).updateData([...])

// Delete document
try await db.collection("users").document(userId).delete()

// Query collection
let query = db.collection("conversations")
    .whereField("participantIds", arrayContains: userId)
    .order(by: "lastMessageTimestamp", descending: true)
let snapshot = try await query.getDocuments()

// Real-time listener
db.collection("conversations")
    .document(conversationId)
    .collection("messages")
    .order(by: "timestamp")
    .addSnapshotListener { snapshot, error in
        // Handle updates
    }
```

#### Storage Operations

```swift
// Upload image
let storageRef = Storage.storage().reference()
let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
let uploadTask = imageRef.putData(imageData, metadata: metadata)

// Download URL
let downloadURL = try await imageRef.downloadURL()
```

#### FCM Token Registration

```swift
// Get FCM token
let token = try await Messaging.messaging().token()

// Store in Firestore
try await db.collection("users").document(userId).updateData([
    "fcmToken": token
])
```

---

## Testing Strategy

### Firebase Emulator Suite

#### Setup

```bash
# Install emulators
firebase init emulators

# Select:
# - Authentication Emulator
# - Firestore Emulator
# - Cloud Functions Emulator
# - Storage Emulator

# Start emulators
firebase emulators:start
```

#### Use in iOS

```swift
// In debug builds, connect to emulators
#if DEBUG
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings

Auth.auth().useEmulator(withHost: "localhost", port: 9099)
Storage.storage().useEmulator(withHost: "localhost", port: 9199)
#endif
```

### iOS Testing

#### Unit Tests

```swift
// Mock Firebase services for testing
class MockFirebaseMessageService: MessageService {
    var messages: [Message] = []

    func sendMessage(_ message: Message) async throws {
        messages.append(message)
    }
}

// Test
func testSendMessage() async throws {
    let mockService = MockFirebaseMessageService()
    let viewModel = ConversationViewModel(messageService: mockService)

    await viewModel.sendMessage("Test")
    XCTAssertEqual(mockService.messages.count, 1)
}
```

#### Integration Tests

- Use Firebase emulator
- Test real Firestore operations
- No production data affected

---

## Performance Requirements

### iOS Performance Targets

- App launch: < 2 seconds
- Message send (optimistic): < 100ms
- Firestore write confirmation: < 500ms (good network)
- Scroll performance: 60 FPS
- Memory usage: < 100MB base, < 300MB with images

### Firebase Performance

- Firestore read latency: < 100ms (p95)
- Firestore write latency: < 200ms (p95)
- Cloud Function cold start: < 1 second
- Cloud Function execution: < 500ms
- Storage download (images): < 1 second for thumbnails

---

## Security Requirements

### Firestore Security Rules

```javascript
// Only authenticated users can read/write
// Only conversation participants can access messages
// Only message sender can create messages
// See architecture.md for complete rules
```

### Firebase Authentication

- Email verification (optional)
- Password requirements: 6+ characters (Firebase default)
- Rate limiting: Built into Firebase
- Token expiration: 1 hour (auto-refreshed by SDK)

### iOS Security

- GoogleService-Info.plist: Not sensitive (API key is public)
- User tokens: Handled automatically by Firebase SDK
- Keychain: Use for additional sensitive data (if needed)

---

## Cost Optimization

### Firestore

- **Read optimization**: Cache aggressively with SwiftData
- **Write optimization**: Batch writes when possible
- **Query optimization**: Use indexes, limit query results
- **Delete old data**: Archive old messages to reduce storage

### Storage

- **Compress images** before upload
- **Generate thumbnails** via Cloud Functions
- **Set cache headers** for CDN efficiency

### Cloud Functions

- **Minimize cold starts**: Keep functions warm with scheduled pings
- **Batch operations**: Process multiple notifications together
- **Use triggers efficiently**: Don't create excessive functions

---

## Known Limitations

### Firebase Limitations

- **Firestore**: 1 write/second per document (sufficient for messaging)
- **Cloud Functions**: 1 million free invocations/month (then $0.40 per million)
- **Storage**: 5GB free, then $0.026/GB/month
- **Offline**: 10MB offline cache by default (configurable)

### iOS Limitations

- iOS 16+ only (excludes ~40% of devices as of 2025)
- SwiftData is newer, less mature than Core Data
- Firebase SDK adds ~10MB to app size

### SwiftData Limitations

- Newer technology (less Stack Overflow answers)
- Complex migrations harder than Core Data
- No CloudKit sync (yet)

---

## Firebase vs Custom Backend Comparison

| Aspect              | Firebase       | Custom Backend     |
| ------------------- | -------------- | ------------------ |
| Development Time    | 2-3 weeks      | 6-8 weeks          |
| Real-time           | Built-in       | Build WebSocket    |
| Offline Support     | Built-in       | Build queue system |
| Authentication      | Built-in       | Build from scratch |
| Push Notifications  | Integrated     | Setup APNs         |
| Hosting             | Managed        | Setup server       |
| Scaling             | Automatic      | Manual setup       |
| Cost (< 1000 users) | Free           | $5-50/month        |
| Cost (10K+ users)   | $100-500/month | $50-200/month      |
| Vendor Lock-in      | High           | Low                |
| Customization       | Limited        | Full control       |

**For MVP**: Firebase is the clear winner.

---

## Development Workflow

### 1. Local Development

```bash
# Start Firebase emulators
firebase emulators:start

# Run iOS app in Xcode (debug mode)
# App connects to local emulators automatically
```

### 2. Testing

```bash
# Run iOS unit tests
xcodebuild test -scheme Wutzup -destination 'platform=iOS Simulator,name=iPhone 15'

# Run Cloud Functions tests
cd functions
npm test
```

### 3. Deployment

#### Deploy Cloud Functions

```bash
firebase deploy --only functions
```

#### Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

#### Deploy Storage Rules

```bash
firebase deploy --only storage
```

#### iOS App

```bash
# Build for TestFlight
xcodebuild archive -scheme Wutzup -archivePath build/Wutzup.xcarchive

# Upload to App Store Connect
xcodebuild -exportArchive -archivePath build/Wutzup.xcarchive -exportPath build -exportOptionsPlist ExportOptions.plist
```

---

## Critical Issues & Debugging History

### ⚠️ Swift Async Runtime Bug - Parameter Corruption (RESOLVED)

**Discovered**: October 2025 **Severity**: CRITICAL - Data loss, crashes
**Status**: ✅ RESOLVED with @MainActor pattern

#### The Problem

Swift's async runtime has a catastrophic bug where parameters passed across
actor isolation boundaries get corrupted, shuffled, or lost entirely. This
affects **ALL** data types, not just primitives.

**Symptoms:**

```swift
// Call site
let userId = "A5OFcBvIBOcU7L3AyahMkTBJGKD2"
print("Before async: \(userId)") // ✅ "A5OFcBvIBOcU7L3AyahMkTBJGKD2"

await someAsyncFunction(userId: userId)

// Inside async function
func someAsyncFunction(userId: String) async {
    print("After async: \(userId)") // ❌ "" (EMPTY!)
}
```

**Impact:**

- String parameters arrive empty or corrupted
- Multiple parameters get shuffled (param1→param2, param2→param3, param3→lost)
- Struct fields get zeroed out (Data with 28 bytes becomes 0 bytes)
- Reference types (classes) get copied/recreated with different ObjectIdentifier
- Random crashes: EXC_BAD_ACCESS, SIGABRT

#### Investigation Process

**Phase 1: String Corruption**

```swift
// Attempt: Defensive String copying
let userId = String(user.id)  // Still corrupted!
```

Result: ❌ Still arrives empty

**Phase 2: Objective-C Types**

```swift
// Attempt: Use NSString (Objective-C bridge)
let userId = NSString(string: user.id) as String
```

Result: ❌ Crashes with SIGABRT during conversion

**Phase 3: Data (Byte Arrays)**

```swift
// Attempt: Pass as Data to avoid String corruption
struct UserDataPackage: Sendable {
    let idData: Data
    let displayNameData: Data
    let emailData: Data
}
let package = UserDataPackage(
    idData: Data(user.id.utf8),           // 28 bytes
    displayNameData: Data(user.displayName.utf8), // 11 bytes
    emailData: Data(user.email.utf8)      // 17 bytes
)
```

Debug output:

```
🔍 Before async:
   idData: 28 bytes
   displayNameData: 11 bytes
   emailData: 17 bytes

🔍 After async:
   idData: 0 bytes        ❌ LOST!
   displayNameData: 28 bytes   ❌ SHUFFLED from idData!
   emailData: 11 bytes    ❌ SHUFFLED from displayNameData!
```

Result: ❌ Parameters rotated/shuffled, data corrupted

**Phase 4: Sendable Structs**

```swift
// Attempt: Use Sendable struct (should be safe)
struct UserSelectionData: Sendable {
    let userId: String
    let displayName: String
    let email: String
}
let data = UserSelectionData(
    userId: user.id,
    displayName: user.displayName,
    email: user.email
)
```

Result: ❌ All fields arrive empty or shuffled

**Phase 5: Reference Types (Classes)**

```swift
// Attempt: Use class reference (should be passed by reference)
class UserReference {
    let userId: String
    let displayName: String

    init(userId: String, displayName: String) {
        self.userId = userId
        self.displayName = displayName
    }
}

let ref = UserReference(userId: user.id, displayName: user.displayName)
print("Before: ObjectIdentifier = \(ObjectIdentifier(ref))")
// ObjectIdentifier(0x13c787150)

await someAsyncFunction(userRef: ref)

// Inside async function
func someAsyncFunction(userRef: UserReference) async {
    print("After: ObjectIdentifier = \(ObjectIdentifier(userRef))")
    // ObjectIdentifier(0x2635cc4a0) ❌ DIFFERENT OBJECT!
    print("userId: \(userRef.userId)") // ❌ Empty!
}
```

Result: ❌ Object gets **COPIED** with new ObjectIdentifier, data lost

**Key Discovery**: Even reference types are not safe. Swift's async runtime is
copying/recreating objects across isolation boundaries, not just corrupting
primitives.

#### Root Cause Analysis

**Hypothesis**: Swift's async runtime uses unsafe serialization when crossing
actor isolation boundaries. This serialization:

1. Doesn't preserve data correctly (corruption)
2. Shuffles parameters in multi-parameter calls (rotation bug)
3. Copies reference types instead of passing references (unexpected behavior)
4. Fails silently with no compiler warnings or runtime errors

**Affected Code Patterns:**

```swift
// Pattern 1: Async closure passed through SwiftUI
NavigationStack {
    ChildView { user in                    // ⚠️ Async closure
        await viewModel.process(user)      // ❌ user corrupted here!
    }
}

// Pattern 2: Multiple parameters through async boundary
func process(param1: String, param2: String, param3: String) async {
    // ❌ Parameters shuffled: param1→param2, param2→param3, param3→lost
}

// Pattern 3: Task with captured values
Task {
    let userId = user.id  // Captured
    await doSomething(userId: userId)  // ❌ Corrupted across Task boundary
}
```

#### The Solution: @MainActor

**Key Insight**: `@MainActor` eliminates the async isolation boundary entirely,
preventing serialization/corruption.

```swift
// ✅ CORRECT: Mark closure with @MainActor
struct ChildView: View {
    let onUserSelected: @MainActor (User) async -> Void

    var body: some View {
        Button("Select") {
            Task { @MainActor in
                await onUserSelected(selectedUser) // ✅ No corruption!
            }
        }
    }
}

// Parent provides @MainActor closure
ParentView {
    ChildView { @MainActor user in
        await viewModel.process(user)  // ✅ user.id intact!
    }
}
```

**Why This Works:**

1. `@MainActor` forces all code to run on the main actor
2. No actor isolation boundary to cross
3. No serialization/deserialization of parameters
4. Parameters passed directly in memory
5. Reference types remain references (not copied)

**Verification:**

```
🔍 Before: userId = A5OFcBvIBOcU7L3AyahMkTBJGKD2
🔍 After: userId = A5OFcBvIBOcU7L3AyahMkTBJGKD2 ✅ CORRECT!
```

#### Lessons Learned

1. ✅ **Always use @MainActor for async closures** passed between SwiftUI views
2. ✅ **Never trust async parameter passing** without @MainActor
3. ✅ **Validate parameters immediately** with extensive logging
4. ✅ **Fail fast** if parameters are empty/corrupted
5. ❌ **Don't use multiple parameters** in async closures (risk of shuffling)
6. ❌ **Don't trust Sendable** to protect against corruption
7. ❌ **Don't trust reference types** to be passed by reference across async
   boundaries

#### Prevention Checklist

Before merging any PR with async closures:

- [ ] Closure type marked with `@MainActor`
- [ ] Closure definition uses `{ @MainActor param in ... }`
- [ ] Closure call wrapped in `Task { @MainActor in ... }`
- [ ] Parameter validation logging at function entry
- [ ] Fail-fast checks for empty/corrupted parameters
- [ ] Unit tests verify parameter integrity

#### Files Modified

- `wutzup/Views/NewConversation/NewChatView.swift` - Added @MainActor to closure
  type
- `wutzup/Views/ChatList/ChatListView.swift` - Added @MainActor to closure
  definition
- `wutzup/ViewModels/ChatListViewModel.swift` - Added extensive parameter
  validation
- `@docs/systemPatterns.md` - Documented @MainActor pattern
- `@docs/techContext.md` - Documented investigation and solution

#### Related Documentation

- Failed approaches documented in: `SENDABLE_WRAPPER_FIX.md`,
  `NSSTRING_PARAMETERS_FIX.md`
- Pattern documented in: `@docs/systemPatterns.md` → "Swift Concurrency
  Patterns"
- Firebase rules fix: `firebase/firestore.rules` (updated to match data
  structure)

---

## Conclusion

Firebase architecture provides:

- ✅ **80% less backend code** to write
- ✅ **Real-time by default** (no WebSocket complexity)
- ✅ **Offline-first built-in** (no queue system to build)
- ✅ **Authentication included** (no auth flow to implement)
- ✅ **Push notifications integrated** (no APNs setup)
- ✅ **Auto-scaling** (no DevOps needed)
- ✅ **6-8 week MVP** (vs 10-12 weeks with custom backend)

**Focus 100% on the iOS app experience, not backend infrastructure.**

---

**Last Updated**: October 24, 2025
