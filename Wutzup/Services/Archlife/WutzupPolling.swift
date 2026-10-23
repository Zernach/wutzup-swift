import Foundation

/// Bounded polling survives transient failures and cancels with the consuming view.
@MainActor
enum WutzupPolling {
    static func stream<T: Equatable & Sendable>(load: @escaping @MainActor () async throws -> [T]) -> AsyncStream<T> {
        AsyncStream(bufferingPolicy: .bufferingNewest(500)) { continuation in
            let actor = ArchlifeWutzupAPI.currentUserID
            let task = Task { @MainActor in
                var previous: [T] = []
                var delay: UInt64 = 2
                while !Task.isCancelled && ArchlifeWutzupAPI.currentUserID == actor && actor != nil {
                    do {
                        let values = try await load()
                        for value in values where !previous.contains(value) { continuation.yield(value) }
                        previous = values
                        delay = 2
                    } catch let error as WutzupAPIError where error.status == 401 || error.status == 403 {
                        break
                    } catch {
                        delay = min(delay * 2, 30)
                    }
                    do { try await Task.sleep(nanoseconds: delay * 1_000_000_000) } catch { break }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
