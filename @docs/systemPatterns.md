# System Patterns: Wutzup

## Architectural Patterns

### MVVM (Model-View-ViewModel)

Wutzup follows the MVVM pattern for clean separation of concerns and
testability.

```
View (SwiftUI) → ViewModel (ObservableObject) → Service Layer → Data Layer
```

**Why MVVM?**

- Clean separation between UI and business logic
- Testable ViewModels without UI dependencies
- Natural fit for SwiftUI's reactive paradigm
- Combine framework integration

**Implementation Pattern:**

```swift
// View subscribes to ViewModel
struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel

    var body: some View {
        // UI reflects viewModel.state
    }
}

// ViewModel manages state and coordinates services
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private let messageService: MessageService

    func sendMessage(_ content: String) async {
        // Business logic here
    }
}
```

### Repository Pattern (Simplified with Firebase)

Abstract data access behind protocol interfaces.

**Purpose**: Decouple business logic from Firebase implementation.

```swift
protocol MessageService {
    func sendMessage(_ message: Message) async throws
    func fetchMessages(for conversationId: String) async throws -> [Message]
    func observeMessages(for conversationId: String) -> AsyncStream<Message>
}

// Firebase implementation
class FirebaseMessageService: MessageService {
    private let db = Firestore.firestore()
    // Implementation details hidden
}

// Mock for testing
class MockMessageService: MessageService {
    var messages: [Message] = []
    // Mock implementation
}
```

**Benefits:**

- Services don't depend on Firebase directly
- Easy to mock for testing
- Can switch from Firebase to custom backend later (if needed)
- **Note**: With Firebase, repository layer is less critical since Firestore SDK
  is the abstraction

### Service Layer Pattern (Firebase Edition)

Encapsulate business logic in dedicated service classes that wrap Firebase SDK.

**Structure:**

```
MessageService
├── Wraps Firestore operations (conversations/messages)
├── Observes Firestore real-time listeners
├── Handles optimistic updates (SwiftData + Firestore)
└── No manual queue needed (Firestore handles offline)

ChatService
├── Manages Firestore conversations collection
├── Creates/updates conversations
└── Handles participant management

PresenceService
├── Updates presence collection in Firestore
├── Observes presence via Firestore listeners
├── Manages typing indicators
└── No WebSocket needed (Firestore real-time)

AuthenticationService
├── Wraps Firebase Auth SDK
├── Creates users in Firestore on signup
└── Manages current user state
```

**Benefits:**

- Single responsibility per service
- Reusable across ViewModels
- Testable in isolation (mock Firebase calls)
- **Simpler**: No custom WebSocket or queue management
- Firebase SDK handles connectivity, retries, offline

## Data Flow Patterns

### Offline-First Architecture (Firebase Edition)

Firestore has built-in offline support! Still use SwiftData for local cache.

**Flow:**

1. Write to SwiftData (local) AND Firestore (queued if offline)
2. Update UI immediately (optimistic)
3. Firestore SDK syncs automatically when online
4. Firestore listener updates with server confirmation

```swift
func sendMessage(_ content: String) async throws {
    let message = Message(id: UUID().uuidString, content: content, status: .sending)

    // 1. Save locally to SwiftData
    modelContext.insert(MessageModel(from: message))
    try modelContext.save()

    // 2. Update UI (via @Published property)
    messages.append(message)

    // 3. Write to Firestore (SDK queues if offline)
    Task {
        do {
            try await db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(message.id)
                .setData(message.firestoreData)

            // Firestore listener will trigger update automatically
        } catch {
            // Update local status to failed
            message.status = .failed
        }
    }
}
```

**Key Difference**: Firestore SDK handles offline queue automatically! You just
write to Firestore; it queues if offline and sends when online. No manual queue
needed.

### Optimistic Updates (IMPLEMENTED ✅)

Show changes immediately, reconcile with server later.

**Example Flow:**

```
User taps Send
   ↓
Message appears immediately (🕐 sending...)
   ↓
Send to Firebase in background
   ↓
Success: Update to ✓ sent
   ↓
Recipient receives: Update to ✓✓ delivered
   ↓
Recipient reads: Update to ✓✓ read (blue)

OR on failure:
   ↓
Failure: Update to ⚠️ failed (Tap to retry)
   ↓
User taps: Retry with same message ID
```

**Benefits:**

- ✅ **Instant feedback** - Messages appear immediately
- ✅ **No perceived lag** - UI feels responsive even on slow networks
- ✅ **Clear status** - Users see exactly what's happening with their messages
- ✅ **Graceful failure** - Failed messages are clearly marked and can be retried
- ✅ **No duplicates** - Same message ID ensures server and local versions match
- ✅ **Offline support** - Works seamlessly with Firestore offline persistence

### Event-Driven Communication (Firestore Listeners)

Components communicate via Firestore real-time listeners (no custom WebSocket).

**Firestore Snapshot Listeners:**

```swift
// Observe messages in real-time
func observeMessages(for conversationId: String) -> AsyncStream<Message> {
    AsyncStream { continuation in
        let listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }

                for change in snapshot.documentChanges {
                    switch change.type {
                    case .added:
                        let message = Message(from: change.document)
                        continuation.yield(message)
                    case .modified:
                        let message = Message(from: change.document)
                        continuation.yield(message)
                    case .removed:
                        // Handle deletion
                        break
                    }
                }
            }

        continuation.onTermination = { _ in
            listener.remove() // Clean up listener
        }
    }
}

// In ViewModel
Task {
    for await message in messageService.observeMessages(for: conversationId) {
        // Update UI
        if !messages.contains(where: { $0.id == message.id }) {
            messages.append(message)
        }
    }
}
```

**Benefits of Firestore Listeners:**

- ✅ No WebSocket code to write
- ✅ Auto-reconnection built-in
- ✅ Offline changes queued automatically
- ✅ Works with offline persistence
- ✅ Type-safe (no string-based events)

## State Management Patterns

### Single Source of Truth

Each piece of data has one authoritative source.

**Examples:**

- Messages: Core Data (local) ↔ PostgreSQL (server)
- User status: PresenceService publishes, Views observe
- Network state: NetworkMonitor publishes, Services observe

### Reactive State Updates

Use Combine framework for reactive data flow.

```swift
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping: Bool = false
    @Published var connectionStatus: ConnectionStatus = .connected

    private var cancellables = Set<AnyCancellable>()

    init(messageService: MessageService, networkMonitor: NetworkMonitor) {
        // Observe message updates
        messageService.messagesPublisher
            .sink { [weak self] messages in
                self?.messages = messages
            }
            .store(in: &cancellables)

        // Observe network status
        networkMonitor.statusPublisher
            .sink { [weak self] status in
                self?.connectionStatus = status
            }
            .store(in: &cancellables)
    }
}
```

## Network Patterns (Firebase Edition)

### Firestore Real-Time Listeners (No WebSocket Needed!)

Firestore provides real-time updates natively.

**Strategy:**

- Real-time listeners for: Messages, conversations, presence, typing
- Firestore SDK handles: Connection, reconnection, offline queue
- No custom WebSocket or REST API needed!

### Auto-Reconnection (Built-In)

Firestore SDK handles this automatically!

**What Firebase Does For You:**

- ✅ Automatic reconnection on network restore
- ✅ Exponential backoff (built-in)
- ✅ Connection state monitoring
- ✅ Offline queue management
- ✅ Write caching during offline

**You just write:**

```swift
// Enable offline persistence (enabled by default)
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings

// Then just use Firestore normally - it handles everything!
```

### Message Queue Pattern (Not Needed!)

**Good News**: Firestore has built-in offline queue!

**How it works:**

1. You write to Firestore (even if offline)
2. Firestore SDK queues write locally
3. When online, SDK automatically sends queued writes
4. Listener updates when server confirms

**Implementation** (it's this simple):

```swift
// Just write to Firestore - SDK queues if offline
try await db.collection("conversations")
    .document(conversationId)
    .collection("messages")
    .document(messageId)
    .setData([...])

// Firebase handles:
// - Queueing if offline
// - Retrying on failure
// - Sending when online
// - Notifying via listener when confirmed
```

**No custom queue code needed!** 🎉

## Data Persistence Patterns

### SwiftData Container (iOS 16+)

Modern Swift-first persistence framework.

```swift
import SwiftData

@main
struct WutzupApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: MessageModel.self,
                ConversationModel.self,
                UserModel.self
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

### SwiftData Models (Simpler than Core Data!)

SwiftData models ARE domain models (no separate entity classes needed).

**Pattern:**

```swift
import SwiftData

@Model
class MessageModel {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var content: String
    var timestamp: Date
    var status: String
    var isFromCurrentUser: Bool
    var mediaUrl: String?

    init(id: String, conversationId: String, senderId: String,
         content: String, timestamp: Date, status: String,
         isFromCurrentUser: Bool, mediaUrl: String? = nil) {
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

// Usage in View
struct ConversationView: View {
    @Query(
        filter: #Predicate<MessageModel> { $0.conversationId == conversationId },
        sort: \MessageModel.timestamp
    ) var messages: [MessageModel]

    var body: some View {
        List(messages) { message in
            MessageBubbleView(message: message)
        }
    }
}
```

**Benefits over Core Data:**

- ✅ No @NSManaged properties (pure Swift)
- ✅ No separate entity/model conversion
- ✅ @Query macro for reactive SwiftUI
- ✅ Less boilerplate
- ✅ Type-safe predicates
- ✅ Automatic SwiftUI updates

### Dual Persistence Strategy (SwiftData + Firestore)

Use both for maximum reliability.

**Pattern:**

- **SwiftData**: Local cache, offline access, fast reads
- **Firestore**: Source of truth, real-time sync, cloud backup

```swift
class MessageService {
    @Environment(\.modelContext) private var modelContext
    private let db = Firestore.firestore()

    func sendMessage(_ message: Message) async throws {
        // 1. Save to SwiftData immediately (optimistic)
        let localMessage = MessageModel(from: message)
        modelContext.insert(localMessage)
        try modelContext.save()

        // 2. Write to Firestore (queued if offline)
        try await db.collection("conversations")
            .document(message.conversationId)
            .collection("messages")
            .document(message.id)
            .setData(message.firestoreData)

        // 3. Firestore listener will update SwiftData when confirmed
    }

    func observeMessages(conversationId: String) {
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addSnapshotListener { snapshot, error in
                guard let changes = snapshot?.documentChanges else { return }

                for change in changes {
                    let message = Message(from: change.document)

                    // Update SwiftData
                    if change.type == .added || change.type == .modified {
                        self.upsertToSwiftData(message)
                    }
                }
            }
    }
}
```

## Error Handling Patterns

### Typed Errors

Use enum-based errors for clarity.

```swift
enum MessageError: Error, LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case messageTooBig
    case conversationNotFound
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to send messages"
        case .networkUnavailable:
            return "No internet connection. Message will send when online."
        case .messageTooBig:
            return "Message is too long"
        case .conversationNotFound:
            return "Conversation no longer exists"
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        }
    }
}
```

### Graceful Degradation

App remains functional even when features fail.

**Examples:**

- WebSocket disconnected? Fall back to REST polling
- Image upload failed? Show message text, retry image later
- Push notifications denied? Still show in-app notifications

## Testing Patterns

### Protocol-Based Mocking

Use protocols to create testable components.

```swift
protocol MessageService {
    func sendMessage(_ message: Message) async throws
    func fetchMessages(conversationId: UUID) async throws -> [Message]
}

// Production implementation
class RealMessageService: MessageService { /* ... */ }

// Test mock
class MockMessageService: MessageService {
    var sendMessageCalled = false
    var messagesToReturn: [Message] = []

    func sendMessage(_ message: Message) async throws {
        sendMessageCalled = true
    }

    func fetchMessages(conversationId: UUID) async throws -> [Message] {
        return messagesToReturn
    }
}

// Test usage
func testSendMessage() async throws {
    let mockService = MockMessageService()
    let viewModel = ConversationViewModel(messageService: mockService)

    await viewModel.sendMessage("Test")
    XCTAssertTrue(mockService.sendMessageCalled)
}
```

## Security Patterns

### Token Management

Secure storage and refresh of JWT tokens.

```swift
class TokenManager {
    private let keychain = KeychainSwift()

    func saveToken(_ token: String) {
        keychain.set(token, forKey: "auth_token")
    }

    func getToken() -> String? {
        keychain.get("auth_token")
    }

    func clearToken() {
        keychain.delete("auth_token")
    }

    func isTokenExpired() -> Bool {
        guard let token = getToken() else { return true }
        // Decode JWT and check expiration
        return decodeJWT(token)?.isExpired ?? true
    }
}
```

### Request Authentication

Automatic token attachment to requests.

```swift
class APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url)

        // Attach token to all requests
        if let token = tokenManager.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle 401 (token expired)
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            try await refreshToken()
            return try await request(endpoint) // Retry with new token
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

## Performance Patterns

### Lazy Loading

Load data on demand to improve performance.

```swift
// Pagination for message history
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private var currentPage = 0
    private let pageSize = 50

    func loadMoreMessages() async {
        let newMessages = try? await messageService.fetchMessages(
            conversationId: conversationId,
            offset: currentPage * pageSize,
            limit: pageSize
        )

        if let newMessages = newMessages {
            messages.insert(contentsOf: newMessages, at: 0)
            currentPage += 1
        }
    }
}
```

### Image Caching

Efficient image loading with Kingfisher.

```swift
import Kingfisher

struct ProfileImageView: View {
    let imageUrl: String

    var body: some View {
        KFImage(URL(string: imageUrl))
            .placeholder {
                ProgressView()
            }
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
    }
}
```

### Background Processing

Heavy operations on background contexts.

```swift
func syncMessages() async throws {
    let context = persistenceController.newBackgroundContext()

    try await context.perform {
        let messages = try self.fetchMessagesFromServer()

        for message in messages {
            let entity = MessageEntity(context: context)
            entity.fromDomainModel(message)
        }

        try context.save()
    }
}
```

## Dependency Injection

### Constructor Injection

Pass dependencies through initializers.

```swift
class ConversationViewModel: ObservableObject {
    private let messageService: MessageService
    private let presenceService: PresenceService

    init(
        messageService: MessageService,
        presenceService: PresenceService
    ) {
        self.messageService = messageService
        self.presenceService = presenceService
    }
}

// In production:
let viewModel = ConversationViewModel(
    messageService: RealMessageService(),
    presenceService: RealPresenceService()
)

// In tests:
let viewModel = ConversationViewModel(
    messageService: MockMessageService(),
    presenceService: MockPresenceService()
)
```

### Environment Objects

Use SwiftUI environment for deep injection.

```swift
@main
struct WutzupApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(appState.authService)
        }
    }
}

// Deep in view hierarchy:
struct SomeDeepView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        // Use authService
    }
}
```

---

## Swift Concurrency Patterns (CRITICAL)

### ⚠️ @MainActor for Async Closures (REQUIRED)

**CRITICAL BUG**: Swift's async runtime has a catastrophic parameter corruption
bug when passing data across actor isolation boundaries. This affects **ALL**
data types: String, Data, structs, AND reference types (classes).

**Symptoms:**

- Parameters arrive empty, corrupted, or shuffled
- Multiple parameters get rotated:
  `param1 → param2, param2 → param3, param3 → lost`
- Struct fields get zeroed out: `Data` with 28 bytes becomes 0 bytes
- Even reference types (classes) get copied/recreated with different
  `ObjectIdentifier`
- Random crashes with `EXC_BAD_ACCESS` or `SIGABRT`

**THE ONLY RELIABLE SOLUTION**: Use `@MainActor` to eliminate async isolation
boundaries entirely.

### Required Pattern for SwiftUI Navigation Closures

**❌ NEVER DO THIS:**

```swift
// DON'T: Async closure without @MainActor - WILL CORRUPT PARAMETERS!
NavigationStack {
    ChatListView()
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .newChat:
                NewChatView { user in  // ⚠️ BUG: user will be corrupted!
                    return await viewModel.createConversation(with: user)
                }
            }
        }
}
```

**✅ ALWAYS DO THIS:**

```swift
// DO: Use @MainActor annotation on closure signature
NavigationStack {
    ChatListView()
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .newChat:
                NewChatView(
                    createOrFetchConversation: { @MainActor (user: User) async -> Conversation? in
                        // All code runs on MainActor - no async boundary!
                        return await viewModel.createConversation(with: user)
                    }
                )
            }
        }
}
```

### Implementation Guidelines

**1. Mark Closure Type with @MainActor**

```swift
// In child view (e.g., NewChatView)
struct NewChatView: View {
    // Closure signature MUST include @MainActor
    let createOrFetchConversation: @MainActor (User) async -> Conversation?

    var body: some View {
        // When calling the closure, wrap in Task with @MainActor
        Button("Start Chat") {
            Task { @MainActor in
                if let user = selectedUser {
                    // Call closure - no async boundary crossed!
                    let conversation = await createOrFetchConversation(user)
                }
            }
        }
    }
}
```

**2. Define Closure in Parent with @MainActor**

```swift
// In parent view (e.g., ChatListView)
struct ChatListView: View {
    @StateObject var viewModel: ChatListViewModel

    var body: some View {
        NavigationStack {
            // ...
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .newChat:
                    NewChatView(
                        createOrFetchConversation: { @MainActor user in
                            // Stays on MainActor - no corruption!
                            return await viewModel.createConversation(with: user)
                        }
                    )
                }
            }
        }
    }
}
```

**3. In ViewModel, Add Extensive Validation Logging**

```swift
class ChatListViewModel: ObservableObject {
    func createConversation(with otherUser: User) async -> Conversation? {
        // 🔍 ALWAYS validate parameters at entry
        print("🔍 ChatListViewModel.createConversation called")
        print("   otherUser.id: \(otherUser.id)")
        print("   otherUser.displayName: \(otherUser.displayName)")
        print("   otherUser.email: \(otherUser.email)")

        // ⚠️ Fail fast if corrupted
        guard !otherUser.id.isEmpty else {
            print("❌ CRITICAL: otherUser.id is EMPTY!")
            return nil
        }

        // Continue with logic...
        return await chatService.createConversation(with: otherUser)
    }
}
```

### Why Other Solutions DON'T Work

**Failed Approach #1: Defensive String Copying**

```swift
let userId = String(user.id)  // ❌ Still corrupts!
```

Result: Still arrives empty across async boundary.

**Failed Approach #2: NSString (Objective-C Types)**

```swift
let userId = NSString(string: user.id)  // ❌ Crashes with SIGABRT!
```

Result: Crashes when converting back to String.

**Failed Approach #3: Data (Byte Arrays)**

```swift
struct UserDataPackage: Sendable {
    let idData: Data
    let displayNameData: Data
    let emailData: Data
}
let data = Data(user.id.utf8)  // ❌ Byte count becomes 0!
```

Result: Sent 28 bytes, received 0 bytes. Shuffled with other parameters.

**Failed Approach #4: Sendable Structs**

```swift
struct UserSelectionData: Sendable {
    let userId: String
    let displayName: String
    let email: String
}
// ❌ All fields corrupted!
```

Result: Fields arrive empty or shuffled.

**Failed Approach #5: Reference Types (Classes)**

```swift
class UserReference {
    let userId: String
    init(userId: String) { self.userId = userId }
}
// ❌ Object gets COPIED with new ObjectIdentifier!
```

Result: Debugger shows `ObjectIdentifier(0x13c787150)` becomes
`ObjectIdentifier(0x2635cc4a0)`. Object recreated, data lost.

### When to Use @MainActor

**✅ REQUIRED:**

- SwiftUI navigation destination closures
- SwiftUI sheet/fullScreenCover closures with parameters
- Any async closure passed between views
- Callbacks from child views to parent views
- Any closure that crosses view boundaries with data

**✅ RECOMMENDED:**

- ViewModel methods called from views
- Service methods that update `@Published` properties
- Any async method that touches UI state

**⚠️ BE CAREFUL:**

- Don't use for heavy computation (blocks main thread)
- Don't use for network calls (unless they're quick)
- For long operations, do work off MainActor, then return to MainActor for UI
  updates

### Example: Complete Pattern

```swift
// ===============================================
// CHILD VIEW: Declares @MainActor closure
// ===============================================
struct NewChatView: View {
    @StateObject private var viewModel = UserPickerViewModel()

    // 1️⃣ Closure parameter MUST be @MainActor
    let createOrFetchConversation: @MainActor (User) async -> Conversation?

    var body: some View {
        List(viewModel.users) { user in
            Button(user.displayName) {
                // 2️⃣ Wrap call in Task with @MainActor
                Task { @MainActor in
                    print("🔍 NewChatView: About to call closure with user.id: \(user.id)")

                    // 3️⃣ Call closure - no async boundary!
                    if let conversation = await createOrFetchConversation(user) {
                        print("✅ Conversation created: \(conversation.id)")
                    }
                }
            }
        }
    }
}

// ===============================================
// PARENT VIEW: Provides @MainActor closure
// ===============================================
struct ChatListView: View {
    @StateObject var viewModel: ChatListViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(viewModel.conversations) { conversation in
                ConversationRowView(conversation: conversation)
            }
            .navigationTitle("Chats")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .newChat:
                    // 4️⃣ Create closure with @MainActor annotation
                    NewChatView(
                        createOrFetchConversation: { @MainActor user in
                            print("🔍 ChatListView closure: Received user.id: \(user.id)")

                            // 5️⃣ All code stays on MainActor!
                            return await viewModel.createDirectConversation(with: user)
                        }
                    )
                }
            }
        }
    }
}

// ===============================================
// VIEW MODEL: Validates and processes
// ===============================================
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    private let chatService: ChatService

    // 6️⃣ Extensive validation logging
    func createDirectConversation(with otherUser: User) async -> Conversation? {
        print("🔍 ChatListViewModel.createDirectConversation called")
        print("   otherUser.id: \(otherUser.id)")
        print("   otherUser.displayName: \(otherUser.displayName)")
        print("   otherUser.email: \(otherUser.email)")

        // 7️⃣ Validate parameters (should NEVER be empty with @MainActor!)
        guard !otherUser.id.isEmpty else {
            print("❌ CRITICAL ERROR: otherUser.id is EMPTY! This should never happen with @MainActor!")
            return nil
        }

        guard let currentUser = authService.currentUser else {
            print("❌ No current user")
            return nil
        }

        // 8️⃣ Create conversation
        do {
            let conversation = try await chatService.fetchOrCreateDirectConversation(
                currentUserId: currentUser.id,
                otherUserId: otherUser.id,
                otherUserDisplayName: otherUser.displayName
            )

            print("✅ Conversation created successfully: \(conversation.id)")
            return conversation

        } catch {
            print("❌ Failed to create conversation: \(error)")
            return nil
        }
    }
}
```

### Testing for Corruption

**Before fix (without @MainActor):**

```
🔍 NewChatView: user.id = A5OFcBvIBOcU7L3AyahMkTBJGKD2
🔍 ChatListView closure: user.id = A5OFcBvIBOcU7L3AyahMkTBJGKD2
🔍 ChatListViewModel: otherUserId = "" ❌ CORRUPTED!
```

**After fix (with @MainActor):**

```
🔍 NewChatView: user.id = A5OFcBvIBOcU7L3AyahMkTBJGKD2
🔍 ChatListView closure: user.id = A5OFcBvIBOcU7L3AyahMkTBJGKD2
🔍 ChatListViewModel: otherUserId = A5OFcBvIBOcU7L3AyahMkTBJGKD2 ✅ CORRECT!
```

### Summary: @MainActor Rules

1. ✅ **ALWAYS** use `@MainActor` for async closures passed between views
2. ✅ **ALWAYS** mark closure type:
   `let closure: @MainActor (Param) async -> Return`
3. ✅ **ALWAYS** define closure with: `{ @MainActor param in ... }`
4. ✅ **ALWAYS** wrap calls in: `Task { @MainActor in ... }`
5. ✅ **ALWAYS** add validation logging to detect corruption early
6. ❌ **NEVER** pass multiple parameters through async closures (use single
   struct/class if needed)
7. ❌ **NEVER** trust that Sendable, Data, or NSString will protect you
8. ❌ **NEVER** assume reference types are safe (they get copied too!)

**This bug cost us hours of debugging. Following these rules prevents
recurrence! 🛡️**

---

## SwiftUI State Update Patterns (CRITICAL)

### ⚠️ Task.yield() for Multiple Frame Updates (REQUIRED)

**CRITICAL ISSUE**: SwiftUI's NavigationRequestObserver (and other view update mechanisms) can error when receiving multiple state updates within a single rendering frame.

**Error Message**: `"Update NavigationRequestObserver tried to update multiple times per frame"`

**Symptoms**:
- Console errors during navigation
- Navigation glitches or delays
- Visual inconsistencies
- State updates not completing properly

**THE SOLUTION**: Use `Task.yield()` to defer state changes to next frame cycle.

### Required Pattern for Multiple State Updates

**❌ NEVER DO THIS:**

```swift
// DON'T: Multiple state updates in same frame
func observeAuthState() {
    authService.authStatePublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] user in
            self?.currentUser = user           // Frame 1: Update 1
            self?.isAuthenticated = user != nil // Frame 1: Update 2
            
            Task { @MainActor in
                // Frame 1: Updates 3, 4, 5... all in same frame!
                await self?.loadData()
                self?.showPermissionPrompt = true
                self?.navigationState.push()
            }
        }
}
```

**✅ ALWAYS DO THIS:**

```swift
// DO: Use Task.yield() to defer updates to next frame
func observeAuthState() {
    authService.authStatePublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] user in
            self?.currentUser = user           // Frame 1: Update 1
            self?.isAuthenticated = user != nil // Frame 1: Update 2
            
            Task { @MainActor in
                // Yield to next run loop before making more state changes
                await Task.yield()  // ✅ Frame completes here
                
                // Frame 2: Updates happen in next frame cycle
                await self?.loadData()
                self?.showPermissionPrompt = true
                self?.navigationState.push()
            }
        }
}
```

### Implementation Guidelines

**1. In Combine Publishers with State Updates**

```swift
class AppState: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var conversations: [Conversation] = []
    
    func observeAuth() {
        authPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                // Synchronous updates (Frame 1)
                self?.user = user
                self?.isLoading = false
                
                // Async updates (Frame 2+)
                Task { @MainActor in
                    await Task.yield() // ✅ Critical: defer to next frame
                    
                    // Now safe to make more state changes
                    await self?.loadConversations()
                    self?.showNotification = true
                }
            }
            .store(in: &cancellables)
    }
}
```

**2. In Navigation State Changes**

```swift
class ChatListView: View {
    @State private var navigationPath = NavigationPath()
    
    @MainActor
    func navigateToConversation(_ conversation: Conversation) {
        // Update data model first (synchronous)
        viewModel.addConversation(conversation)
        
        // Navigation changes in next frame
        Task { @MainActor in
            await Task.yield() // ✅ Critical: defer navigation updates
            
            // Now safe to modify navigation path
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
            navigationPath.append(conversation)
        }
    }
}
```

**3. In View Lifecycle Methods**

```swift
struct ContentView: View {
    @StateObject var viewModel: ViewModel
    @State private var showSheet = false
    
    var body: some View {
        VStack { /* ... */ }
            .onAppear {
                Task { @MainActor in
                    await Task.yield() // ✅ Let view finish appearing
                    
                    // Safe to trigger state changes
                    await viewModel.loadInitialData()
                    showSheet = viewModel.needsOnboarding
                }
            }
    }
}
```

### When to Use Task.yield()

**✅ REQUIRED:**
- Making multiple state updates from Combine sinks
- Updating navigation state programmatically
- Triggering async operations that update multiple @Published properties
- Batching multiple @State or @Published property updates
- In onAppear/onDisappear when triggering state changes
- After setting user/auth state that triggers cascading updates

**✅ RECOMMENDED:**
- Before showing/dismissing sheets programmatically
- Before navigation push/pop operations
- When updating multiple view models simultaneously
- In callbacks from child views that trigger parent state changes

**⚠️ NOT NEEDED:**
- Single state update with no cascading effects
- User-triggered actions (button taps) that don't cascade
- Simple computed properties
- Read-only operations

### Technical Explanation

**SwiftUI Frame Cycle**:
```
Frame N:
  1. Input Processing
  2. State Updates
  3. View Computation (body)
  4. Layout
  5. Render
  
Task.yield() here
  ↓
  
Frame N+1:
  1. Input Processing
  2. State Updates (resumed task)
  3. View Computation
  4. Layout
  5. Render
```

**What Task.yield() Does**:
1. Suspends the current task
2. Allows current frame cycle to complete fully
3. Returns control to the run loop
4. Resumes task in next frame cycle
5. Subsequent state changes happen in fresh frame

**Why This Works**:
- Each frame gets distinct, non-overlapping state updates
- Navigation system processes changes sequentially
- View updates don't conflict with each other
- SwiftUI has time to reconcile state between updates

### Real-World Example: Auth State Flow

```swift
// BEFORE (BROKEN): Multiple updates per frame
authPublisher.sink { user in
    self.currentUser = user              // Update 1
    self.isAuthenticated = user != nil   // Update 2
    
    Task { @MainActor in
        await loadConversations()        // Update 3 (triggers @Published)
        self.showPrompt = true           // Update 4
        navigationPath.append(route)     // Update 5
    }
}
// ❌ Error: NavigationRequestObserver updated 5 times in one frame!

// AFTER (FIXED): Updates spread across frames
authPublisher.sink { user in
    self.currentUser = user              // Frame 1: Update 1
    self.isAuthenticated = user != nil   // Frame 1: Update 2
    
    Task { @MainActor in
        await Task.yield()               // ✅ Frame 1 completes
        
        // Frame 2+: Remaining updates
        await loadConversations()        // Frame 2: Update 3
        self.showPrompt = true           // Frame 2: Update 4
        navigationPath.append(route)     // Frame 2: Update 5
    }
}
// ✅ Success: Updates spread across multiple frames!
```

### Prevention Checklist

Before committing code with state updates, check:

- [ ] Are multiple @Published properties updated in sequence?
- [ ] Does a Combine sink trigger async operations with state changes?
- [ ] Are navigation path changes made programmatically?
- [ ] Does auth state change trigger cascading updates?
- [ ] Are sheets/alerts shown after state updates?
- [ ] Do view lifecycle methods trigger multiple updates?

If **any** of the above are true → Use `Task.yield()`!

### Common Patterns

**Pattern: Auth State → Load Data**
```swift
Task { @MainActor in
    await Task.yield()
    await loadUserData()
    await loadConversations()
    startObservingPresence()
}
```

**Pattern: Navigation After Data Update**
```swift
Task { @MainActor in
    viewModel.updateData()
    await Task.yield()
    navigationPath.append(newRoute)
}
```

**Pattern: Cascading UI Updates**
```swift
Task { @MainActor in
    await Task.yield()
    showLoadingIndicator = false
    showSuccessMessage = true
    dismissAfterDelay()
}
```

### Testing

Verify no multiple-update errors:
1. Monitor console for NavigationRequestObserver errors
2. Test navigation flows (push, pop, replace)
3. Test login/logout cycles
4. Test rapid state changes (typing, scrolling)
5. Profile with Instruments (no dropped frames)

### Summary: Task.yield() Rules

1. ✅ **ALWAYS** use `await Task.yield()` before cascading state updates
2. ✅ **ALWAYS** yield at start of Task when triggered from Combine sink
3. ✅ **ALWAYS** yield before programmatic navigation changes
4. ✅ **ALWAYS** yield in onAppear if triggering state updates
5. ✅ **ALWAYS** yield after auth state changes that trigger data loads
6. ❌ **NEVER** make multiple navigation path changes without yield
7. ❌ **NEVER** update multiple @Published properties without yield
8. ❌ **NEVER** assume SwiftUI will batch updates automatically

**This pattern prevents navigation errors and ensures smooth UI updates! 🎯**

---

## Firebase Architecture Benefits Summary

### What Firebase Eliminates

- ❌ No WebSocket server to build
- ❌ No WebSocket reconnection logic
- ❌ No manual message queue system
- ❌ No REST API endpoints to create
- ❌ No PostgreSQL database setup
- ❌ No server deployment/hosting
- ❌ No custom authentication system
- ❌ No APNs certificate management
- ❌ No file storage server

### What Firebase Provides

- ✅ Real-time listeners (built-in)
- ✅ Offline persistence (automatic)
- ✅ Offline queue (automatic)
- ✅ Auto-reconnection (automatic)
- ✅ Authentication (Firebase Auth)
- ✅ Push notifications (FCM)
- ✅ File storage (Firebase Storage)
- ✅ Serverless functions (Cloud Functions)
- ✅ Security rules (declarative)
- ✅ Auto-scaling (Google infrastructure)

### Code Reduction Estimate

| Component          | Custom Backend   | Firebase                      |
| ------------------ | ---------------- | ----------------------------- |
| Backend code       | ~5,000 lines     | ~500 lines (Cloud Functions)  |
| WebSocket handling | ~1,000 lines     | 0 lines (Firestore listeners) |
| Offline queue      | ~500 lines       | 0 lines (built-in)            |
| Auth system        | ~800 lines       | 0 lines (Firebase Auth)       |
| API endpoints      | ~2,000 lines     | 0 lines (Firestore SDK)       |
| **Total backend**  | **~9,300 lines** | **~500 lines**                |

**Result**: ~95% less backend code to write! Focus on iOS app instead.

---

**Last Updated**: October 21, 2025
