import XCTest

@MainActor
final class WutzupReleaseTests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "org.archlife.wutzup")
    var configuration: [String:String] { ProcessInfo.processInfo.environment }
    var origin: String { configuration["WUTZUP_E2E_ORIGIN"]! }
    let password = "Isolated-wutzup-fixture-123!"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchEnvironment = [
            "WUTZUP_API_BASE_URL": origin + "/api/wutzup",
            "FIREBASE_AUTH_EMULATOR_HOST": configuration["WUTZUP_E2E_AUTH_HOST"]!
        ]
    }

    func control(_ path: String, _ body: [String:Any]? = nil) async throws -> [String:Any] {
        var request = URLRequest(url: URL(string: origin + "/__test/" + path)!)
        request.setValue(configuration["WUTZUP_E2E_CONTROL_KEY"]!, forHTTPHeaderField: "x-wutzup-test-control")
        if let body { request.httpMethod = "POST"; request.httpBody = try JSONSerialization.data(withJSONObject: body); request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data,response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode,200)
        return try JSONSerialization.jsonObject(with: data) as! [String:Any]
    }

    func data(_ actor: String, _ action: String, _ body: [String:Any]) async throws -> [String:Any] {
        let actors = try await control("actors")
        let identity = actors[actor] as! [String:String]
        var request = URLRequest(url: URL(string: origin + "/api/wutzup/data/" + action)!)
        request.httpMethod = "POST"
        request.setValue("Bearer " + identity["token"]!, forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data,response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode,200)
        return try JSONSerialization.jsonObject(with: data) as! [String:Any]
    }

    func fill(_ field: XCUIElement, _ value: String) {
        XCTAssertTrue(field.waitForExistence(timeout:15))
        field.tap(); field.typeText(value)
    }
    func dismissPrompt() {
        let later = app.buttons["Not Now"]
        if later.waitForExistence(timeout:3) { later.tap() }
    }
    func login(_ actor: String) {
        fill(app.textFields["Email"], actor + "@wutzup.example.test")
        fill(app.secureTextFields["Password"], password)
        app.buttons["Log In"].tap()
        XCTAssertTrue(app.navigationBars["Chats"].waitForExistence(timeout:25))
        dismissPrompt()
    }
    func openChat() {
        let row=app.buttons["conversation.native-chat"]
        XCTAssertTrue(row.waitForExistence(timeout:20));row.tap()
        XCTAssertTrue(app.textFields["Message"].waitForExistence(timeout:15))
    }
    func send(_ text:String) {
        fill(app.textFields["Message"], text)
        app.buttons["Send message"].tap()
    }
    func logout() {
        if !app.buttons["Account"].exists { app.navigationBars.buttons.firstMatch.tap() }
        app.buttons["Account"].tap()
        let button=app.buttons["Logout"]
        for _ in 0..<8 { if button.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(button.isHittable);button.tap()
        XCTAssertTrue(app.buttons["Log In"].waitForExistence(timeout:15))
    }
    func waitForMessage(_ text:String, actor:String="bob", count:Int=1) async throws -> [[String:Any]] {
        for _ in 0..<50 {
            let response=try await data(actor,"messages",["conversationId":"native-chat"])
            let matches=(response["messages"] as! [[String:Any]]).filter { $0["content"] as? String == text }
            if matches.count==count { return matches }
            try await Task.sleep(nanoseconds:200_000_000)
        }
        XCTFail("Expected \(count) durable messages for the synthetic scenario")
        return []
    }

    func testOfflineMessagesAndDraftsStayWithTheirOwner() async throws {
        app.launch();login("alice");openChat()
        _ = try await control("network",["dropSends":true])
        let text="Alice owns this queued message"
        send(text)
        XCTAssertTrue(app.staticTexts["Ready to Sync"].waitForExistence(timeout:15))
        fill(app.textFields["Message"],"Alice private draft")
        logout()
        _ = try await control("network",["dropSends":false])
        login("bob");openChat()
        XCTAssertEqual(app.textFields["Message"].value as? String,"Message","Bob cannot see Alice's draft")
        app.terminate();app.launch();dismissPrompt();openChat()
        let response=try await data("bob","messages",["conversationId":"native-chat"])
        XCTAssertFalse((response["messages"] as! [[String:Any]]).contains { $0["content"] as? String == text },"Bob must not replay Alice's queued send")
        logout();login("alice")
        let sent=try await waitForMessage(text)
        XCTAssertEqual(sent.first?["senderId"] as? String,"alice")
        openChat()
        XCTAssertEqual(app.textFields["Message"].value as? String,"Alice private draft")
        app.textFields["Message"].tap()
        app.textFields["Message"].typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:"Alice private draft".count))
        logout()
    }

    func testRegistrationCreatesAChatAndPersistsItsMessage() async throws {
        app.launch()
        let register=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Don't have an account?")).firstMatch
        XCTAssertTrue(register.waitForExistence(timeout:15));register.tap()
        fill(app.textFields["Display Name"],"Native registered learner")
        fill(app.textFields["Email"],"native-register@wutzup.example.test")
        fill(app.secureTextFields["Password"],password)
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.navigationBars["Chats"].waitForExistence(timeout:25));dismissPrompt()
        app.buttons["New conversation options"].tap()
        app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","New Chat")).firstMatch.tap()
        let bob=app.buttons["recipient.bob"]
        XCTAssertTrue(bob.waitForExistence(timeout:15));bob.tap()
        XCTAssertTrue(app.textFields["Message"].waitForExistence(timeout:20))
        send("Native registered and created this chat")
        var saved:[[String:Any]]=[]
        for _ in 0..<50 {
            let conversations=try await data("bob","conversations",[:])["conversations"] as! [[String:Any]]
            if let chat=conversations.first(where:{ ($0["participantNames"] as? [String:String])?.values.contains("Native registered learner") == true }) {
                let messages=try await data("bob","messages",["conversationId":chat["id"]!])["messages"] as! [[String:Any]]
                saved=messages.filter { $0["content"] as? String == "Native registered and created this chat" }
                if saved.count==1 { break }
            }
            try await Task.sleep(nanoseconds:200_000_000)
        }
        XCTAssertEqual(saved.count,1)
        XCTAssertNotEqual(saved.first?["senderId"] as? String,"bob")
        logout()
    }

    func testSignedInMessagingSurvivesRelaunchAndReceivesPeerChanges() async throws {
        app.launch();login("alice");openChat()
        let text="Native release persistence"
        send(text)
        let saved=try await waitForMessage(text)
        XCTAssertEqual(saved.first?["senderId"] as? String,"alice")
        let id=saved[0]["id"] as! String
        _ = try await data("bob","receipts",["conversationId":"native-chat","ids":[id],"kind":"read"])
        _ = try await data("bob","send_message",["conversationId":"native-chat","id":"peer-reply","content":"Reply from independent session"])
        XCTAssertTrue(app.staticTexts["Reply from independent session"].waitForExistence(timeout:15))
        app.terminate();app.launch();dismissPrompt();openChat()
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout:15))
        _ = try await waitForMessage(text)
        logout()
    }
}
