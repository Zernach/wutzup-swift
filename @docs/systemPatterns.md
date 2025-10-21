# System Patterns: Wutzup

## Architectural Patterns

### MVVM (Model-View-ViewModel)
Wutzup follows the MVVM pattern for clean separation of concerns and testability.

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
- **Note**: With Firebase, repository layer is less critical since Firestore SDK is the abstraction

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

**Key Difference**: Firestore SDK handles offline queue automatically! You just write to Firestore; it queues if offline and sends when online. No manual queue needed.

### Optimistic Updates
Show changes immediately, reconcile with server later.

**Pattern:**
- User action triggers immediate UI update
- Background task syncs with server
- On success: update state with server response
- On failure: revert or show error state

**Example:**
```
User taps Send
   ↓
Show message immediately (status: .sending)
   ↓
Send to server in background
   ↓
Success: Update to .sent
Failure: Update to .failed, show retry option
```

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
| Component | Custom Backend | Firebase |
|-----------|---------------|----------|
| Backend code | ~5,000 lines | ~500 lines (Cloud Functions) |
| WebSocket handling | ~1,000 lines | 0 lines (Firestore listeners) |
| Offline queue | ~500 lines | 0 lines (built-in) |
| Auth system | ~800 lines | 0 lines (Firebase Auth) |
| API endpoints | ~2,000 lines | 0 lines (Firestore SDK) |
| **Total backend** | **~9,300 lines** | **~500 lines** |

**Result**: ~95% less backend code to write! Focus on iOS app instead.

---

**Last Updated**: October 21, 2025

