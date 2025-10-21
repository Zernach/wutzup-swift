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
      "fields": [
        { "fieldPath": "timestamp", "order": "ASCENDING" }
      ]
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

| Aspect | Firebase | Custom Backend |
|--------|----------|----------------|
| Development Time | 2-3 weeks | 6-8 weeks |
| Real-time | Built-in | Build WebSocket |
| Offline Support | Built-in | Build queue system |
| Authentication | Built-in | Build from scratch |
| Push Notifications | Integrated | Setup APNs |
| Hosting | Managed | Setup server |
| Scaling | Automatic | Manual setup |
| Cost (< 1000 users) | Free | $5-50/month |
| Cost (10K+ users) | $100-500/month | $50-200/month |
| Vendor Lock-in | High | Low |
| Customization | Limited | Full control |

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

**Last Updated**: October 21, 2025
