import Foundation
import FirebaseAuth

/// Shared authenticated transport. OpenAI credentials exist only on the server.
enum ArchlifeWutzupAPI {
    private static let session = URLSession(configuration: .ephemeral,
                                           delegate: WutzupSessionDelegate(), delegateQueue: nil)
    static var baseURL: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["WUTZUP_API_BASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "WutzupAPIBaseURL") as? String
            ?? "https://api-dev.archlife/api/wutzup"
        #else
        return Bundle.main.object(forInfoDictionaryKey: "WutzupAPIBaseURL") as? String
            ?? "https://api.archlife.org/api/wutzup"
        #endif
    }

    static func send(_ original: URLRequest, expectedActor: String? = nil) async throws -> (Data, URLResponse) {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "WutzupAPI", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Please sign in to continue."])
        }
        if let expectedActor { try requireActor(expectedActor) }
        let token = try await user.getIDToken()
        try requireActor(user.uid)
        let request = try WutzupRequestTransport.prepare(original, token: token)
        return try await session.data(for: request)
    }
}

extension ArchlifeWutzupAPI {
    static var currentUserID: String? { Auth.auth().currentUser?.uid }
    static func data<T: Decodable & Sendable>(_ action: String, _ body: [String: Any] = [:], requestId: String = UUID().uuidString, expectedActor: String? = nil) async throws -> T {
        let request = try WutzupWire.request(base: baseURL, action: action, body: body, requestId: requestId)
        let (data, response) = try await send(request, expectedActor: expectedActor)
        return try WutzupWire.decode(T.self, data: data, response: response)
    }
    static func requireActor(_ userId: String) throws {
        guard currentUserID == userId else { throw WutzupAPIError(status: 401, code: "identity_changed") }
    }
}

