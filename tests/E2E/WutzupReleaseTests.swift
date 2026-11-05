import XCTest
import UIKit

@MainActor
final class WutzupReleaseTests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "org.archlife.wutzup")
    var configuration: [String: String] { ProcessInfo.processInfo.environment }
    var origin: String { configuration["WUTZUP_E2E_ORIGIN"]! }
    let password = "Isolated-wutzup-fixture-123!"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchEnvironment = [
            "WUTZUP_API_BASE_URL": origin + "/api/wutzup",
            "FIREBASE_AUTH_EMULATOR_HOST": configuration["WUTZUP_E2E_AUTH_HOST"]!,
        ]
        app.launch()
        if app.navigationBars["Chats"].waitForExistence(timeout: 4) {
            dismissPrompt()
            logout()
        }
    }
    override func tearDownWithError() throws {
        do {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Synthetic app failure screenshot"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        app.terminate()
    }

    func control(_ path: String, _ body: [String: Any]? = nil) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: origin + "/__test/" + path)!)
        request.timeoutInterval = 10
        request.setValue(
            configuration["WUTZUP_E2E_CONTROL_KEY"]!, forHTTPHeaderField: "x-wutzup-test-control")
        if let body {
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    func data(_ actor: String, _ action: String, _ body: [String: Any]) async throws -> [String: Any] {
        let actors = try await control("actors")
        let identity = actors[actor] as! [String: String]
        var request = URLRequest(url: URL(string: origin + "/api/wutzup/data/" + action)!)
        request.timeoutInterval = 10
        request.httpMethod = "POST"
        request.setValue("Bearer " + identity["token"]!, forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    func fill(_ field: XCUIElement, _ value: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        if let existing = field.value as? String, !existing.isEmpty, existing != field.placeholderValue {
            // Tapping the middle of existing text places the caret in the middle.
            // Move to its trailing edge before deleting the fixture's single-line value.
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        if field.elementType == .secureTextField {
            // AutoFill can intercept synthetic keystrokes in a new-password field.
            // Paste the known fixture through the real edit menu, then restore the
            // disposable simulator's clipboard. Registration/login verify the input.
            let clipboard = UIPasteboard.general.items
            defer { UIPasteboard.general.items = clipboard }
            UIPasteboard.general.string = value
            field.press(forDuration: 1)
            let paste = app.menuItems["Paste"].exists
                ? app.menuItems["Paste"] : app.buttons["Paste"].firstMatch
            XCTAssertTrue(paste.waitForExistence(timeout: 5))
            paste.tap()
        } else {
            if !value.isEmpty { field.typeText(value) }
            let actual = field.value as? String ?? ""
            if value.isEmpty {
                XCTAssertTrue(actual.isEmpty || actual == field.placeholderValue)
            } else {
                XCTAssertEqual(actual, value, "The UI must contain the requested text before sending")
            }
        }
    }
    func dismissPrompt() {
        for _ in 0..<4 {
            let save = app.sheets["Save Password?"]
            if save.waitForExistence(timeout: 1) { save.buttons["Not Now"].tap() }
            let later = app.buttons["notifications.later"]
            if later.waitForExistence(timeout: 1), later.isHittable { later.tap() }
        }
    }
    func login(_ actor: String) {
        fill(app.textFields["Email"], actor + "@wutzup.example.test")
        fill(app.secureTextFields["Password"], password)
        app.buttons["Log In"].tap()
        XCTAssertTrue(app.navigationBars["Chats"].waitForExistence(timeout: 25))
        dismissPrompt()
    }
    func openChat() {
        let row = app.buttons["conversation.native-chat"]
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch
                .waitForExistence(timeout: 15))
    }
    func send(_ text: String) {
        fill(app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch, text)
        app.buttons["Send message"].tap()
    }
    func logout() {
        if !app.buttons["Account"].exists { app.navigationBars.buttons.firstMatch.tap() }
        app.buttons["Account"].tap()
        let button = app.buttons["Logout"]
        for _ in 0..<8 {
            if button.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(app.buttons["Log In"].waitForExistence(timeout: 15))
    }
    func waitForMessage(_ text: String, actor: String = "bob", count: Int = 1) async throws -> [[String: Any]]
    {
        var observed: [String] = []
        for _ in 0..<50 {
            let response = try await data(actor, "messages", ["conversationId": "native-chat"])
            observed = (response["messages"] as! [[String: Any]]).compactMap { $0["content"] as? String }
            let matches = (response["messages"] as! [[String: Any]]).filter {
                $0["content"] as? String == text
            }
            if matches.count == count { return matches }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        XCTFail(
            "Expected \(count) durable messages for the synthetic scenario; observed synthetic contents: \(observed)"
        )
        return []
    }

    func test02OfflineMessagesAndDraftsStayWithTheirOwner() async throws {
        _ = try await control("network", ["dropSends": false])
        login("alice")
        openChat()
        _ = try await control("network", ["dropSends": true])
        let text = "Alice owns this queued message"
        send(text)
        XCTAssertTrue(app.staticTexts["Ready to Sync"].waitForExistence(timeout: 15))
        fill(
            app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch,
            "Alice private draft")
        logout()
        _ = try await control("network", ["dropSends": false])
        login("bob")
        openChat()
        XCTAssertTrue(
            ["", "Message"].contains(
                app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch.value
                    as? String ?? "invalid"), "Bob cannot see Alice's draft")
        app.terminate()
        app.launch()
        dismissPrompt()
        openChat()
        let response = try await data("bob", "messages", ["conversationId": "native-chat"])
        XCTAssertFalse(
            (response["messages"] as! [[String: Any]]).contains { $0["content"] as? String == text },
            "Bob must not replay Alice's queued send")
        logout()
        login("alice")
        let sent = try await waitForMessage(text)
        XCTAssertEqual(sent.first?["senderId"] as? String, "alice")
        openChat()
        XCTAssertEqual(
            app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch.value
                as? String, "Alice private draft")
        fill(app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch, "")
        logout()
    }

    func test01RegistrationCreatesAChatAndPersistsItsMessage() async throws {
        _ = try await control("network", ["dropSends": false])
        let register = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Don't have an account?")
        ).firstMatch
        XCTAssertTrue(register.waitForExistence(timeout: 15))
        register.tap()
        fill(app.textFields["Display Name"], "Native registered learner")
        fill(app.textFields["Email"], "native-register@wutzup.example.test")
        fill(app.secureTextFields["Password"], password)
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.navigationBars["Chats"].waitForExistence(timeout: 25))
        dismissPrompt()
        app.buttons["New conversation options"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "New Chat")).firstMatch.tap()
        let bob = app.buttons["recipient.bob"]
        XCTAssertTrue(bob.waitForExistence(timeout: 15))
        bob.tap()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "message.composer").firstMatch
                .waitForExistence(timeout: 20))
        send("Native registered and created this chat")
        var saved: [[String: Any]] = []
        for _ in 0..<50 {
            let conversations =
                try await data("bob", "conversations", [:])["conversations"] as! [[String: Any]]
            if let chat = conversations.first(where: {
                ($0["participantNames"] as? [String: String])?.values.contains("Native registered learner")
                    == true
            }) {
                let messages =
                    try await data("bob", "messages", ["conversationId": chat["id"]!])["messages"]
                    as! [[String: Any]]
                saved = messages.filter {
                    $0["content"] as? String == "Native registered and created this chat"
                }
                if saved.count == 1 { break }
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        XCTAssertEqual(saved.count, 1)
        XCTAssertNotEqual(saved.first?["senderId"] as? String, "bob")
        logout()
    }

    func test03SignedInMessagingSurvivesRelaunchAndReceivesPeerChanges() async throws {
        _ = try await control("network", ["dropSends": false])
        login("alice")
        openChat()
        let text = "Native release persistence"
        send(text)
        let saved = try await waitForMessage(text)
        XCTAssertEqual(saved.first?["senderId"] as? String, "alice")
        let id = saved[0]["id"] as! String
        _ = try await data("bob", "receipts", ["conversationId": "native-chat", "ids": [id], "kind": "read"])
        _ = try await data(
            "bob", "send_message",
            [
                "conversationId": "native-chat", "id": "peer-reply",
                "content": "Reply from independent session",
            ])
        XCTAssertTrue(app.staticTexts["Reply from independent session"].waitForExistence(timeout: 15))
        app.terminate()
        app.launch()
        dismissPrompt()
        openChat()
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 15))
        _ = try await waitForMessage(text)
        logout()
    }
}
