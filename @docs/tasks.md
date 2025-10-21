# Wutzup - Implementation Tasks (Firebase Edition)

## Overview
This document breaks down the Wutzup messaging app implementation into actionable tasks for Firebase-based architecture. **Much simpler than custom backend!**

**Priority Levels:**
- 🔴 **Critical** - Core functionality, blocks other work
- 🟡 **High** - Important features, needed for MVP
- 🟢 **Medium** - Nice to have, can be deferred
- 🔵 **Low** - Polish and optimization

**Effort Estimates:**
- **XS** - 1-2 hours
- **S** - 3-5 hours
- **M** - 1-2 days
- **L** - 3-5 days
- **XL** - 1+ weeks

---

## 🎯 Firebase MVP Advantage

### What We DON'T Need to Build:
- ❌ Backend server (Node.js/Express)
- ❌ PostgreSQL database
- ❌ WebSocket server
- ❌ REST API endpoints
- ❌ Message queue system
- ❌ Authentication system
- ❌ Push notification server
- ❌ File storage server

### What We DO Need to Build:
- ✅ Firebase project setup
- ✅ Firestore collections & security rules
- ✅ iOS app (Swift + SwiftUI)
- ✅ Firebase service layer (wrapping SDK)
- ✅ SwiftData models (local cache)
- ✅ Cloud Functions (push notifications)

**Result: ~60% less work, 4-6 weeks instead of 8-10 weeks!**

---

## Phase 1: Firebase & iOS Setup

### 1.1 Firebase Project Setup
- [🔴 XS] Create Firebase project in console
  - Go to console.firebase.google.com
  - Create new project: "Wutzup"
  - Enable Google Analytics (optional)

- [🔴 S] Setup Firebase services
  - Enable Firebase Authentication (Email/Password)
  - Create Firestore database (start in test mode, will add rules later)
  - Enable Firebase Storage
  - Enable Firebase Cloud Messaging (FCM)

- [🔴 M] Setup Firebase CLI & Functions
  ```bash
  npm install -g firebase-tools
  firebase login
  firebase init
  # Select: Firestore, Functions, Storage, Emulators
  ```

- [🔴 S] Configure Firestore collections structure
  - Create `users` collection
  - Create `conversations` collection  
  - Create `presence` collection
  - Add sample data for testing

- [🔴 M] Write Firestore Security Rules
  - Rules for users collection
  - Rules for conversations collection
  - Rules for messages subcollection
  - Rules for presence collection
  - Deploy: `firebase deploy --only firestore:rules`

- [🔴 S] Setup Firebase Storage rules
  - Allow authenticated users to upload images
  - Path structure: `images/{userId}/{imageId}`
  - Deploy: `firebase deploy --only storage`

### 1.2 iOS Project Setup
- [🔴 S] Create new Xcode project
  - iOS App, SwiftUI
  - Name: Wutzup
  - Bundle ID: com.yourcompany.wutzup
  - Minimum iOS: 16.0 (for SwiftData)

- [🔴 M] Setup project structure
  ```
  Wutzup/
  ├── App/
  ├── Models/
  ├── Views/
  ├── ViewModels/
  ├── Services/
  ├── Utilities/
  └── Resources/
  ```

- [🔴 M] Add Firebase SDK via SPM
  - Add package: `https://github.com/firebase/firebase-ios-sdk`
  - Select products:
    - FirebaseAuth
    - FirebaseFirestore
    - FirebaseStorage
    - FirebaseMessaging
  - Add Kingfisher for image caching

- [🔴 S] Download & add GoogleService-Info.plist
  - Download from Firebase Console
  - Add to Xcode project (drag & drop)
  - Ensure it's included in target

- [🔴 S] Configure Firebase in app
  ```swift
  // WutzupApp.swift
  import FirebaseCore
  
  init() {
      FirebaseApp.configure()
      configureFirestore()
  }
  ```

- [🔴 M] Setup SwiftData models
  - Create MessageModel
  - Create ConversationModel
  - Create UserModel
  - Setup ModelContainer in App

- [🟡 S] Setup Firebase Emulator Suite
  ```bash
  firebase emulators:start
  ```
  - Configure iOS to use emulator in debug builds

- [🟡 XS] Create Constants file
  - Firebase collection names
  - App constants
  - Feature flags

---

## Phase 2: Authentication

### 2.1 Firebase Auth Backend
- [🔴 S] Configure Firebase Authentication
  - Enable Email/Password provider in Firebase Console
  - Set password requirements
  - (Optional) Enable email verification

### 2.2 iOS Authentication
- [🔴 M] Create User model
  ```swift
  struct User: Identifiable, Codable {
      let id: String
      var email: String
      var displayName: String
      var profileImageUrl: String?
      var createdAt: Date
  }
  ```

- [🔴 L] Implement FirebaseAuthService
  - register(email:password:displayName:) async throws
  - login(email:password:) async throws
  - logout() async throws
  - observeAuthState() -> AsyncStream<User?>
  - Create Firestore user document on registration

- [🔴 M] Create LoginView
  - Email text field
  - Password secure field
  - Login button
  - "Create account" navigation link
  - Form validation
  - Loading state

- [🔴 M] Create RegisterView
  - Email text field
  - Password secure field
  - Display name text field
  - Register button
  - Form validation
  - Loading state

- [🔴 M] Create AuthenticationViewModel
  - @Published var currentUser: User?
  - @Published var errorMessage: String?
  - @Published var isLoading: Bool
  - Handle login/register actions
  - Input validation

- [🔴 S] Create auth flow routing
  - Show auth views if not logged in
  - Show main app if logged in
  - Automatic navigation on auth state change

### 2.3 Testing Authentication
- [🔴 M] Test: User registration
  - Create new account
  - Verify user document in Firestore
  - Auto-login after registration

- [🔴 M] Test: User login
  - Login with credentials
  - Verify auth state persists
  - Test incorrect credentials

---

## Phase 3: Core Messaging (One-on-One)

### 3.1 Firestore Setup
- [🔴 M] Create Firestore indexes
  - Index on conversations: participantIds, lastMessageTimestamp
  - Index on messages: timestamp
  - Deploy: `firebase deploy --only firestore:indexes`

### 3.2 iOS Data Models
- [🔴 S] Create Message model
  ```swift
  struct Message: Identifiable, Codable {
      let id: String
      let conversationId: String
      let senderId: String
      let content: String
      let timestamp: Date
      var status: MessageStatus
      var mediaUrl: String?
  }
  ```

- [🔴 S] Create Conversation model
  ```swift
  struct Conversation: Identifiable, Codable {
      let id: String
      var participantIds: [String]
      var lastMessage: String?
      var lastMessageTimestamp: Date?
      var unreadCount: Int
      var isGroup: Bool
  }
  ```

- [🔴 S] Create MessageStatus enum
  ```swift
  enum MessageStatus: String, Codable {
      case sending, sent, delivered, read, failed
  }
  ```

### 3.3 Firebase Service Layer
- [🔴 L] Implement FirebaseMessageService
  - sendMessage(\_: Message) async throws
  - fetchMessages(conversationId:limit:) async throws -> [Message]
  - observeMessages(conversationId:) -> AsyncStream<Message>
  - markAsRead(messageId:) async throws
  - Write to Firestore with optimistic updates

- [🔴 M] Implement FirebaseChatService
  - createConversation(withUserIds:) async throws -> Conversation
  - fetchConversations() async throws -> [Conversation]
  - observeConversations() -> AsyncStream<Conversation>
  - Query conversations where user is participant

### 3.4 Local Persistence (SwiftData)
- [🔴 M] Implement local message caching
  - Save messages to SwiftData on receive
  - Query messages from SwiftData for instant display
  - Sync with Firestore in background

- [🔴 S] Implement local conversation caching
  - Save conversations to SwiftData
  - Update on Firestore changes

### 3.5 iOS UI - Chat List
- [🔴 M] Create ChatListView
  - List of conversations
  - Pull to refresh
  - Empty state ("No conversations")
  - Navigation to conversation

- [🔴 M] Create ChatListViewModel
  - @Published var conversations: [Conversation]
  - Observe Firestore conversations
  - Update SwiftData cache
  - Handle loading states

- [🔴 M] Create ConversationRowView
  - Profile picture (or initials)
  - Display name
  - Last message preview
  - Timestamp (relative: "2m ago")
  - Unread badge
  - Swipe to delete

### 3.6 iOS UI - Conversation View
- [🔴 L] Create ConversationView
  - Message list (ScrollView with LazyVStack)
  - Message bubbles (sent/received)
  - Auto-scroll to bottom
  - Load more on scroll to top (pagination)
  - Timestamps every 5 minutes
  - Keyboard handling

- [🔴 M] Create MessageBubbleView
  - Different styles for sent/received
  - Message content
  - Timestamp
  - Status indicator (✓, ✓✓)
  - Support for images
  - Long-press menu (future)

- [🔴 M] Create MessageInputView
  - Text field (multi-line)
  - Send button
  - Image picker button
  - Disable when offline
  - Clear input after send

- [🔴 XL] Create ConversationViewModel
  - @Published var messages: [Message]
  - @Published var isLoading: Bool
  - @Published var currentUserId: String
  - Observe Firestore messages (real-time)
  - Send message with optimistic update
  - Pagination (load older messages)
  - Mark messages as read
  - Handle keyboard

### 3.7 Testing Core Messaging
- [🔴 M] Test: Send message from User A → appears on User B
  - Two devices/simulators
  - Both logged in
  - Send message
  - Verify instant delivery

- [🔴 M] Test: Local persistence
  - Send messages
  - Force quit app
  - Reopen app
  - Verify messages present (from SwiftData)

- [🔴 M] Test: Optimistic UI
  - Send message
  - Message appears immediately
  - Status updates when Firestore confirms

---

## Phase 4: Offline Support (Built into Firebase!)

### 4.1 Enable Firestore Offline Persistence
- [🔴 S] Configure Firestore settings
  ```swift
  let settings = FirestoreSettings()
  settings.isPersistenceEnabled = true
  settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
  Firestore.firestore().settings = settings
  ```

### 4.2 Network Monitoring (Optional but helpful)
- [🟡 M] Implement NetworkMonitor
  - Use NWPathMonitor
  - @Published var isConnected: Bool
  - Show connection status in UI

- [🟡 S] Add connection indicator
  - "Offline" banner when disconnected
  - "Connecting..." when reconnecting
  - Auto-hide when connected

### 4.3 SwiftData Sync Logic
- [🔴 M] Implement Firestore → SwiftData sync
  - Listen to Firestore changes
  - Update SwiftData on new messages
  - Handle conflicts (Firestore wins)

### 4.4 Testing Offline Scenarios
- [🔴 M] Test: Offline message sending
  - Disconnect network
  - Send messages (they queue in Firestore SDK)
  - Reconnect
  - Verify messages send automatically

- [🔴 M] Test: Receive while offline
  - User A online, User B offline
  - User A sends messages
  - User B comes online
  - Verify User B receives all messages

- [🔴 S] Test: App backgrounded
  - Send message while app is in background
  - Foreground app
  - Verify message sent

---

## Phase 5: Real-Time Features

### 5.1 Presence (Online/Offline)

#### Firestore
- [🟡 M] Setup presence collection
  - Document per user
  - Fields: status, lastSeen, typing

#### iOS
- [🟡 M] Implement FirebasePresenceService
  - setOnline() async throws
  - setOffline() async throws
  - observePresence(userId:) -> AsyncStream<UserStatus>
  - Update on app lifecycle (foreground/background)

- [🟡 S] Add presence indicators to UI
  - Green dot for online
  - "Last seen" for offline
  - Update in real-time

### 5.2 Typing Indicators

#### Firestore
- [🟡 S] Use presence collection for typing
  - Field: typing: { conversationId: timestamp }
  - Auto-expire after 5 seconds (Cloud Function or client logic)

#### iOS
- [🟡 M] Implement typing indicator logic
  - Detect text input changes
  - Debounce (send after 1 second of typing)
  - Send "typing" update to Firestore
  - Stop after 3 seconds idle

- [🟡 S] Add typing indicator to UI
  - Show "User is typing..." in conversation
  - Animated dots
  - Show multiple users in groups

### 5.3 Read Receipts

#### Firestore
- [🟡 M] Track read status in messages
  - Field: readBy: [userId1, userId2, ...]
  - Update when message becomes visible

#### iOS
- [🟡 M] Implement read receipt logic
  - Mark messages as read when visible (onAppear)
  - Update Firestore readBy array
  - Observe changes via Firestore listener

- [🟡 S] Update UI with read indicators
  - Single checkmark: sent
  - Double checkmark: delivered
  - Blue double checkmark: read
  - Show who read in groups

---

## Phase 6: Media Support (Images)

### 6.1 Firebase Storage Setup
- [🟡 S] Configure Storage rules
  - Allow authenticated uploads
  - Size limits (5MB)
  - Allowed file types (JPEG, PNG)

### 6.2 iOS Image Handling
- [🟡 M] Implement image picker
  - Use PHPickerViewController
  - Request photo library permission
  - Image compression (resize to max 1080px)

- [🟡 M] Implement image upload
  - Upload to Firebase Storage
  - Path: `images/{userId}/{UUID}.jpg`
  - Show upload progress
  - Get download URL
  - Store URL in message

- [🟡 M] Display images in messages
  - Show thumbnail in message bubble
  - Tap to view full screen
  - Use Kingfisher for caching
  - Loading placeholders

- [🟡 S] Create full-screen image viewer
  - SwiftUI sheet with image
  - Pinch to zoom
  - Dismiss gesture

---

## Phase 7: Group Chat

### 7.1 Firestore Group Setup
- [🟡 S] Update conversations collection
  - Add isGroup boolean
  - Add groupName field
  - Add groupImageUrl field (optional)

### 7.2 iOS Group Chat
- [🟡 M] Create group creation UI
  - Select multiple users
  - Set group name
  - Create conversation button

- [🟡 M] Update ConversationView for groups
  - Show sender name above messages
  - Different bubble styles for different senders
  - Group info button (show members)

- [🟡 S] Create GroupInfoView
  - List of members
  - Leave group button
  - (Future) Add/remove members

- [🟡 M] Update MessageService for groups
  - Send to conversation (all participants notified)
  - Track readBy for all members
  - Show read receipts per member

### 7.3 Testing Group Chat
- [🔴 M] Test: Create group with 3 users
  - User A creates group with B and C
  - All see group in chat list
  - Send messages
  - All receive instantly

---

## Phase 8: Push Notifications (FCM)

### 8.1 Cloud Functions Setup
- [🟡 M] Write Cloud Function: onMessageCreated
  ```typescript
  export const onMessageCreated = functions.firestore
    .document('conversations/{conversationId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
      // Get recipients
      // Send FCM notification to each
    });
  ```

- [🟡 S] Deploy Cloud Functions
  ```bash
  firebase deploy --only functions
  ```

### 8.2 iOS FCM Setup
- [🟡 M] Configure push notifications
  - Enable Push Notifications capability in Xcode
  - Upload APNs key to Firebase Console
  - Request notification permission

- [🟡 M] Implement FirebaseNotificationService
  - requestPermission() async -> Bool
  - registerDeviceToken() async throws
  - Store FCM token in Firestore users collection

- [🟡 M] Handle notifications
  - UNUserNotificationCenterDelegate
  - Tap notification → open conversation
  - Update badge count
  - Handle foreground notifications

### 8.3 Testing Notifications
- [🟡 M] Test: Foreground notifications
  - App is open
  - Receive message
  - Notification banner shows

- [🟡 M] Test: Background notifications
  - App is closed/backgrounded
  - Send message
  - Notification appears
  - Tap opens conversation

---

## Phase 9: UI Polish & User Experience

### 9.1 Animations & Transitions
- [🟢 S] Add message send animation
- [🟢 S] Add message receive animation
- [🟢 S] Typing indicator animation (dots)
- [🟢 S] Pull-to-refresh animation
- [🟢 S] Smooth scroll to bottom

### 9.2 Improved Message Input
- [🟢 S] Auto-expand text field (multi-line)
- [🟢 S] Emoji picker button
- [🟢 S] Disable send when empty
- [🟢 S] Show character count (if needed)

### 9.3 User Feedback
- [🟢 S] Haptic feedback on message send
- [🟢 S] Haptic on message receive
- [🟢 S] Haptic on button taps

### 9.4 Profile & Settings
- [🟢 M] Create ProfileView
  - Display user info
  - Edit display name
  - Change profile picture
  - Logout button

- [🟢 S] Create SettingsView
  - Notification preferences
  - App version
  - Clear cache
  - Privacy policy link
  - Terms of service link

### 9.5 Error Handling
- [🟡 M] Improve error states
  - Network errors (user-friendly messages)
  - Failed message retry button
  - Loading states for all async ops
  - Empty states with helpful messages

### 9.6 Accessibility
- [🟢 M] VoiceOver support
- [🟢 S] Dynamic Type support
- [🟢 S] Color contrast (dark mode)
- [🟢 S] Accessibility labels

---

## Phase 10: Testing & Quality Assurance

### 10.1 Unit Tests
- [🟡 M] Write tests for services
  - Mock Firebase services
  - Test message sending logic
  - Test conversation creation

- [🟡 M] Write tests for ViewModels
  - Test state changes
  - Test async operations
  - Mock service dependencies

### 10.2 Integration Tests (with Emulator)
- [🟡 M] Test Firestore operations
  - Use Firebase emulator
  - Test real CRUD operations
  - Test real-time listeners

### 10.3 UI Tests
- [🟢 M] Critical flow tests
  - Login flow
  - Send message flow
  - Create conversation

### 10.4 Manual Testing (All Test Scenarios)
- [🔴 XL] Execute all 7 test scenarios from PRD
  1. ✅ Real-time chat between two devices
  2. ✅ Offline/online transitions
  3. ✅ Background/foreground behavior
  4. ✅ Force quit recovery
  5. ✅ Poor network conditions (use Network Link Conditioner)
  6. ✅ Rapid-fire messaging (20+ messages)
  7. ✅ Group chat with 3+ participants

---

## Phase 11: Performance Optimization

### 11.1 Firebase Optimization
- [🟢 M] Optimize Firestore queries
  - Add pagination (limit 50 messages)
  - Use composite indexes
  - Cache frequently accessed data

- [🟢 S] Optimize Storage costs
  - Compress images before upload
  - Generate thumbnails (Cloud Function)
  - Set cache headers

### 11.2 iOS Performance
- [🟢 M] Profile with Instruments
  - Memory leaks
  - CPU usage
  - Network usage

- [🟢 S] Optimize message list
  - Lazy loading
  - Image caching (Kingfisher)
  - Release memory on warning

### 11.3 SwiftData Optimization
- [🟢 S] Add indexes to SwiftData models
- [🟢 S] Limit local cache size
- [🟢 S] Background context for heavy operations

---

## Phase 12: Deployment Preparation

### 12.1 Firebase Production Setup
- [🟡 M] Create production Firebase project
  - Separate from development
  - Configure production Firestore rules
  - Setup Firebase Blaze plan (if needed for Cloud Functions)

- [🟡 S] Deploy production Cloud Functions
  ```bash
  firebase use production
  firebase deploy --only functions
  ```

- [🟡 S] Setup Firebase monitoring
  - Enable Crashlytics
  - Setup performance monitoring
  - Configure alerts

### 12.2 iOS App Store Preparation
- [🟡 M] Create app icons (all sizes)
- [🟡 M] Create launch screen
- [🟡 M] Take screenshots (all device sizes)
- [🟡 S] Write App Store description
- [🟡 S] Create privacy policy
- [🟡 S] Create terms of service

### 12.3 iOS Build Configuration
- [🟡 M] Configure release build settings
  - Code signing
  - Provisioning profiles
  - App version/build number
  - Production GoogleService-Info.plist

### 12.4 TestFlight
- [🟡 M] Create beta build
  - Archive in Xcode
  - Upload to App Store Connect
  - Submit for review

- [🟡 M] Invite beta testers
  - External testers (public link)
  - Collect feedback
  - Fix critical bugs

### 12.5 Security Audit
- [🟡 M] Review Firestore security rules
  - Test with different user roles
  - Verify no unauthorized access
  - Check edge cases

- [🟡 S] Review Storage security rules
- [🟡 S] Review Cloud Functions security
- [🟡 S] Check for exposed secrets in code

---

## Summary Checklist (MVP Definition of Done)

### Critical Features ✅
- [ ] Firebase project setup
- [ ] User authentication (Firebase Auth)
- [ ] One-on-one chat working end-to-end (Firestore)
- [ ] Messages persist (SwiftData + Firestore)
- [ ] Real-time message delivery (< 1 second)
- [ ] Optimistic UI updates
- [ ] Offline support (Firestore offline persistence)
- [ ] Online/offline status indicators
- [ ] Message timestamps
- [ ] Read receipts
- [ ] Group chat (3+ users)
- [ ] Push notifications via FCM (foreground)
- [ ] Image sharing (Firebase Storage)

### Test Scenarios ✅
- [ ] Two devices chatting in real-time
- [ ] Offline/online transitions
- [ ] Messages sent while app backgrounded
- [ ] App force-quit and reopened
- [ ] Poor network conditions
- [ ] Rapid-fire messaging (20+ messages)
- [ ] Group chat with 3+ participants

### Quality Metrics ✅
- [ ] Zero message loss in testing
- [ ] < 1 second message delivery on good network
- [ ] < 2 second app launch time
- [ ] 60 FPS scroll performance
- [ ] No critical bugs
- [ ] All test scenarios pass
- [ ] Firestore security rules tested

---

## Firebase vs Custom Backend Task Comparison

| Task Category | Custom Backend | Firebase | Time Saved |
|--------------|----------------|----------|------------|
| Backend Setup | 1 week | 1 day | 4 days |
| Authentication | 1 week | 2 days | 5 days |
| Real-time Messaging | 2 weeks | 3 days | 11 days |
| Offline Support | 1 week | 1 day (config) | 6 days |
| Push Notifications | 1 week | 3 days | 4 days |
| File Storage | 3 days | 1 day | 2 days |
| **Total** | **8-10 weeks** | **4-6 weeks** | **4 weeks** |

**Firebase eliminates ~50% of development time!**

---

## Notes

### Priority Guidelines
- Focus on **🔴 Critical** tasks first - get Firebase + core messaging working
- Complete authentication before messaging
- Offline support is mostly handled by Firebase (just enable it)
- Real-time features (Phase 5) can be done after core works
- Polish (Phase 9-11) is last

### Time Estimates
- Total estimated effort: **4-6 weeks** for single developer
- With Firebase: No backend developer needed!
- Critical path: Setup → Auth → Messaging → Testing

### Firebase Best Practices
1. Use Firestore emulator for development
2. Write security rules early (don't rely on test mode)
3. Enable offline persistence from start
4. Monitor Firebase usage dashboard (avoid surprise costs)
5. Use composite indexes for complex queries
6. Implement pagination (don't load all messages at once)

### Risk Mitigation
- Start with Firebase emulator (free, fast iteration)
- Test offline scenarios continuously
- Use real devices for testing (not just simulator)
- Monitor Firebase costs (set budget alerts)
- Write security rules before launch

---

**Last Updated**: October 21, 2025
