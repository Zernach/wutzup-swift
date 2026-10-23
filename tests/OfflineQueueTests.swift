import Foundation

// External network boundary: the queue itself, serialization and account transitions are real.
@MainActor
final class NetworkMonitor { static let shared = NetworkMonitor(); var isConnected = true }

final class SendingBoundary: MessageService {
    var sent: [String] = []
    var onSend: (() async throws -> Void)?
    func sendMessage(conversationId:String,content:String,mediaUrl:String?,mediaType:String?,messageId:String?) async throws -> Message {
        sent.append(messageId!); try await onSend?()
        return Message(id:messageId!,conversationId:conversationId,senderId:"alice",content:content)
    }
    func fetchMessages(conversationId:String,limit:Int) async throws -> [Message] { [] }
    func observeMessages(conversationId:String) -> AsyncStream<Message> { AsyncStream { $0.finish() } }
    func markAsRead(conversationId:String,messageId:String,userId:String) async throws {}
    func markAsDelivered(conversationId:String,messageId:String,userId:String) async throws {}
    func batchMarkAsRead(conversationId:String,messageIds:[String],userId:String) async throws {}
    func batchMarkAsDelivered(conversationId:String,messageIds:[String],userId:String) async throws {}
}

@main
struct OfflineQueueTests {
    @MainActor static func main() async {
        let suite="wutzup.queue.test."+UUID().uuidString
        let defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let queue=OfflineMessageQueue(defaults:defaults)
        queue.activate(userID:"alice")
        let message=Message(id:"stable-id",conversationId:"chat",senderId:"alice",content:"Private pending message")
        queue.enqueue(message)
        queue.enqueue(message)
        precondition(queue.pendingCount==1,"Enqueue is synchronous and exact retries are deduplicated")
        queue.activate(userID:nil)
        precondition(queue.pendingMessages.isEmpty,"Logout hides the previous account queue")
        queue.activate(userID:"bob")
        let boundary=SendingBoundary()
        await queue.syncPendingMessages(messageService:boundary)
        precondition(boundary.sent.isEmpty,"Bob must never send Alice's queued message")
        queue.enqueue(message)
        precondition(queue.pendingMessages.isEmpty,"A stale enqueue cannot enter another account queue")
        let relaunched=OfflineMessageQueue(defaults:defaults)
        relaunched.activate(userID:"alice")
        precondition(relaunched.pendingMessages.map(\.id)==[message.id],"The owner's pending message survives relaunch")
        await relaunched.syncPendingMessages(messageService:boundary)
        precondition(boundary.sent==[message.id],"Retry preserves the original message identity")
        precondition(relaunched.pendingCount==0,"Acknowledged sends are removed synchronously")
        let reloaded=OfflineMessageQueue(defaults:defaults);reloaded.activate(userID:"alice")
        precondition(reloaded.pendingCount==0,"Acknowledged sends cannot reappear after process death")
        // Account change during a suspended send cannot drain or mutate the next account.
        let switching=OfflineMessageQueue(defaults:defaults)
        switching.activate(userID:"alice")
        switching.enqueue(message)
        switching.enqueue(Message(id:"second",conversationId:"chat",senderId:"alice",content:"Second"))
        let suspended=SendingBoundary()
        suspended.onSend = {
            switching.activate(userID:"bob")
            switching.enqueue(Message(id:"bob-pending",conversationId:"chat",senderId:"bob",content:"Bob owned"))
        }
        await switching.syncPendingMessages(messageService:suspended)
        precondition(suspended.sent==[message.id],"Account change stops the rest of the old batch")
        precondition(switching.pendingMessages.map(\.id)==["bob-pending"],"A late old acknowledgement cannot mutate the new account")
        switching.activate(userID:"alice")
        precondition(switching.pendingCount==2,"The previous owner's unacknowledged messages are retained for safe replay")

        let failing=SendingBoundary()
        failing.onSend = { throw URLError(.notConnectedToInternet) }
        let retries=OfflineMessageQueue(defaults:defaults);retries.activate(userID:"retry-owner")
        retries.enqueue(Message(id:"failure",conversationId:"chat",senderId:"retry-owner",content:"Retry boundary"))
        for _ in 0..<5 { await retries.syncPendingMessages(messageService:failing) }
        precondition(retries.statusCounts.failed==1,"The fifth failure reaches the bounded failed state")
        await retries.syncPendingMessages(messageService:failing)
        precondition(failing.sent.count==5,"Failed messages are not retried indefinitely")
        let failedReload=OfflineMessageQueue(defaults:defaults);failedReload.activate(userID:"retry-owner")
        precondition(failedReload.statusCounts.failed==1,"Failure state survives process death")
        failedReload.clearFailedMessages();precondition(failedReload.pendingCount==0)

        let legacy=Data("legacy unowned record".utf8)
        defaults.set(legacy,forKey:"offlineMessageQueue")
        let quarantined=OfflineMessageQueue(defaults:defaults);quarantined.activate(userID:"new-owner")
        precondition(quarantined.pendingCount==0,"Unowned legacy data is never reassigned")
        precondition(defaults.data(forKey:"offlineMessageQueue")==legacy,"Legacy bytes remain available for explicit recovery")
        let aliceDrafts=DraftManager(userID:"alice",defaults:defaults)
        let bobDrafts=DraftManager(userID:"bob",defaults:defaults)
        aliceDrafts.saveDraft("Private unsent draft",for:"shared-chat")
        precondition(bobDrafts.loadDraft(for:"shared-chat")==nil,"Shared conversation membership does not share private drafts")
        precondition(DraftManager(userID:"alice",defaults:defaults).loadDraft(for:"shared-chat")=="Private unsent draft")
        bobDrafts.removeAllDrafts()
        precondition(aliceDrafts.loadDraft(for:"shared-chat") != nil,"Clearing one account cannot erase another account drafts")
        print("Offline queue and draft isolation, cancellation, relaunch, failure and legacy recovery passed")
    }
}
