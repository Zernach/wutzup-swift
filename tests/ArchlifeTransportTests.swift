import Foundation

@main
struct ArchlifeTransportTests {
    static func main() throws {
        var original = URLRequest(url: URL(string: "https://api.archlife.org/api/wutzup/translate_text")!)
        original.httpMethod = "POST"
        original.httpBody = Data("{\"text\":\"Hello\"}".utf8)
        original.setValue("fixed-retry-id", forHTTPHeaderField: "Idempotency-Key")
        let request = try WutzupRequestTransport.prepare(original, token: "firebase-id-token")
        precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer firebase-id-token")
        precondition(request.value(forHTTPHeaderField: "Idempotency-Key") == "fixed-retry-id")
        precondition(request.value(forHTTPHeaderField: "X-Request-ID") != nil)
        precondition(request.httpBody == original.httpBody && request.httpMethod == "POST")
        precondition(request.timeoutInterval == 180)
        var redirectWasRejected = false
        let session = URLSession(configuration: .ephemeral)
        WutzupSessionDelegate().urlSession(session, task: session.dataTask(with: request),
            willPerformHTTPRedirection: HTTPURLResponse(url: original.url!, statusCode: 302,
                httpVersion: nil, headerFields: ["Location": "https://evil.example"])!,
            newRequest: URLRequest(url: URL(string: "https://evil.example")!)) { redirected in
                redirectWasRejected = redirected == nil
            }
        precondition(redirectWasRejected)
        session.invalidateAndCancel()
        for address in ["https://evil.example/api/wutzup/translate_text",
                        "https://api.archlife.org.evil.example/api/wutzup/translate_text",
                        "http://api.archlife.org/api/wutzup/translate_text",
                        "https://user@api.archlife.org/api/wutzup/translate_text",
                        "https://api.archlife.org/api/another-app/translate_text",
                        "https://api.archlife.org:9999/api/wutzup/translate_text",
                        "https://api.archlife.org/api/wutzup/../another-app"] {
            do {
                _ = try WutzupRequestTransport.prepare(URLRequest(url: URL(string: address)!), token: "token")
                fatalError("Credentials could be sent outside Wutzup")
            } catch { }
        }
        for token in ["", "token with spaces"] {
            do { _ = try WutzupRequestTransport.prepare(original, token: token); fatalError("Invalid token accepted") }
            catch { }
        }
        let suggestionData = Data("{\"positive_response\":\"Yes\",\"negative_response\":\"No\"}".utf8)
        let suggestions = try JSONDecoder().decode(AIResponseSuggestion.self, from: suggestionData)
        precondition(suggestions.positiveResponse == "Yes" && suggestions.negativeResponse == "No")
        let tutor = try JSONDecoder().decode(TutorResponse.self, from: Data("{\"message\":\"Hola\",\"translation\":\"Hello\"}".utf8))
        precondition(tutor.translation == "Hello")
        let research = WutzupResearchText.attributed("Findings.\n\n[Primary source](https://example.org/source)")
        precondition(research.runs.compactMap { $0.link }.contains(URL(string: "https://example.org/source")!))
        precondition(String(research.characters).contains("\n\n"))
        let unsafe = WutzupResearchText.attributed("[unsafe](javascript:alert) [insecure](http://example.org)")
        precondition(unsafe.runs.compactMap { $0.link }.isEmpty)
        let gifBytes = Data("GIF89a".utf8)
        let imageResponse = HTTPURLResponse(url: original.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "image/gif"])!
        try WutzupMediaResponse.validate(gifBytes, response: imageResponse)
        for status in [403, 404, 503] {
            do {
                let failed = HTTPURLResponse(url: original.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "image/gif"])!
                try WutzupMediaResponse.validate(gifBytes, response: failed)
                fatalError("Failed media response would be cached")
            } catch { }
        }
        precondition(!WutzupMediaResponse.isImage(Data("{\"error\":\"unavailable\"}".utf8)))
        precondition(!WutzupMediaResponse.mayDownload(URL(string: "https://firebasestorage.googleapis.com/v0/b/legacy")!))
        precondition(WutzupMediaResponse.mayDownload(URL(string: "https://api.archlife.org/api/wutzup/media/id/token")!))
        let fixtureURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let fixture = try JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL)) as! [String: Any]
        let response = HTTPURLResponse(url: original.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        func payload(_ key: String) throws -> Data { try JSONSerialization.data(withJSONObject: fixture[key]!) }
        let user = try WutzupWire.decode(WutzupUserResult.self, data: payload("userResponse"), response: response).user
        precondition(user.id == "legacy_student" && user.email == "student@example.test")
        let tutorUser = try WutzupWire.decode(WutzupUserResult.self, data: payload("tutorResponse"), response: response).user
        precondition(tutorUser.id == "firebaseTutorUid" && tutorUser.isTutor && tutorUser.email.isEmpty)
        let conversation = try WutzupWire.decode(WutzupConversationResult.self, data: payload("conversationResponse"), response: response).conversation
        precondition(conversation.id == "legacy_chat" && conversation.revision == 1 && conversation.unreadCount == 1)
        let messages = try WutzupWire.decode(WutzupMessagesResult.self, data: payload("messagesResponse"), response: response).messages
        precondition(messages.count == 1 && messages[0].id == "legacy_message" && messages[0].content == "¡Hola!")
        precondition(messages[0].readBy == ["firebaseTutorUid"])
        let requestBody = try WutzupWire.request(base: "https://api.archlife.org/api/wutzup", action: "send_message", body: ["id": "stable-id", "conversationId": "chat", "content": "Hello"], requestId: "stable-retry")
        precondition(requestBody.value(forHTTPHeaderField: "Idempotency-Key") == "stable-retry")
        precondition(requestBody.url!.path == "/api/wutzup/data/send_message")
        do {
            let denied = HTTPURLResponse(url: original.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            let _: WutzupMessagesResult = try WutzupWire.decode(WutzupMessagesResult.self, data: Data("{\"error\":\"conversation_forbidden\"}".utf8), response: denied)
            fatalError("Authorization failure accepted")
        } catch let error as WutzupAPIError { precondition(error.status == 403) }
        print("Wutzup native transport and executed PostgreSQL response contracts passed")
    }
}
