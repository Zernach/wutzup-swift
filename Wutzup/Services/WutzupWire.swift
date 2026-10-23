import Foundation

nonisolated struct WutzupAPIError: LocalizedError {
    let status: Int
    let code: String
    var errorDescription: String? {
        switch status {
        case 401: return "Please sign in again to continue."
        case 403: return "You no longer have access to this conversation."
        case 409: return "This changed in another session. Refresh and try again."
        case 429: return "The daily limit has been reached. Please try again later."
        default: return "Could not reach Wutzup. Your pending messages can be retried."
        }
    }
}
nonisolated enum WutzupWire {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid API timestamp"))
        }
        return decoder
    }
    static func request(base: String, action: String, body: [String: Any], requestId: String = UUID().uuidString) throws -> URLRequest {
        guard action.range(of: "^[a-z_]+$", options: .regularExpression) != nil,
              let url = URL(string: "\(base)/data/\(action)") else { throw WutzupAPIError(status: 400, code: "invalid_action") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(requestId, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return request
    }
    static func decode<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 503
        guard (200..<300).contains(status) else {
            let error = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw WutzupAPIError(status: status, code: error?["error"] as? String ?? "api_unavailable")
        }
        return try decoder().decode(T.self, from: data)
    }
}

nonisolated struct WutzupOK: Decodable, Sendable { let ok: Bool }
nonisolated struct WutzupUserResult: Decodable, Sendable { let user: User }
nonisolated struct WutzupConversationResult: Decodable, Sendable { let conversation: Conversation }
nonisolated struct WutzupMessageResult: Decodable, Sendable { let message: Message }
nonisolated struct WutzupUsersResult: Decodable, Sendable { let users: [User]; let next: String? }
nonisolated struct WutzupConversationsResult: Decodable, Sendable { let conversations: [Conversation]; let next: String? }
nonisolated struct WutzupCursor: Codable, Sendable { let at: String; let id: String }
nonisolated struct WutzupMessagesResult: Decodable, Sendable { let messages: [Message]; let cursor: WutzupCursor? }
nonisolated struct WutzupPresenceResult: Decodable, Sendable { let presence: Presence }
nonisolated struct WutzupTypingResult: Decodable, Sendable { let typing: [String: Bool] }
nonisolated struct WutzupMediaResult: Decodable, Sendable { let url: String }
