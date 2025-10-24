//
//  FirebaseAIService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

class FirebaseAIService: AIService {
    private let functionURL: String
    private let baseFunctionsURL: String
    
    init(functionURL: String = "https://generate-response-suggestions-uv2bm2c2tq-uc.a.run.app",
         baseFunctionsURL: String = "https://us-central1-wutzup-swift.cloudfunctions.net") {
        // Cloud Function URL (2nd gen) - deployed via Firebase
        // Get this URL from: firebase deploy --only functions:generate_response_suggestions
        self.functionURL = functionURL
        self.baseFunctionsURL = baseFunctionsURL
    }
    
    func generateResponseSuggestions(
        conversationHistory: [Message],
        userPersonality: String?
    ) async throws -> AIResponseSuggestion {
        guard let url = URL(string: functionURL) else {
            throw NSError(
                domain: "FirebaseAIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
        }
        
        // Prepare conversation history with current user context
        let messages = conversationHistory.map { message in
            return [
                "sender_id": message.senderId,
                "sender_name": message.senderName ?? "Unknown",
                "content": message.content,
                "timestamp": ISO8601DateFormatter().string(from: message.timestamp),
                "is_from_current_user": message.isFromCurrentUser
            ] as [String : Any]
        }
        
        // Create request body
        var requestBody: [String: Any] = [
            "conversation_history": messages
        ]
        
        if let personality = userPersonality {
            requestBody["user_personality"] = personality
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "FirebaseAIService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            )
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "FirebaseAIService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server error: \(errorMessage)"]
            )
        }
        
        // Decode response
        let decoder = JSONDecoder()
        let suggestion = try decoder.decode(AIResponseSuggestion.self, from: data)
        
        return suggestion
    }

    // MARK: - New Endpoints
    func translateText(text: String, targetLanguage: String) async throws -> (translatedText: String, detectedLanguage: String?) {
        guard let url = URL(string: "\(baseFunctionsURL)/translate_text") else {
            throw NSError(domain: "FirebaseAIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "text": text,
            "target_language": targetLanguage
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FirebaseAIService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Server error: \(errorMessage)"])
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let translated = json?["translated_text"] as? String ?? ""
        let detected = json?["detected_language"] as? String
        return (translated, detected)
    }

    func getMessageContext(selectedMessage: String, conversationHistory: [Message]) async throws -> String {
        guard let url = URL(string: "\(baseFunctionsURL)/message_context") else {
            throw NSError(domain: "FirebaseAIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let historyPayload: [[String: Any]] = conversationHistory.suffix(10).map { m in
            [
                "sender_id": m.senderId,
                "sender_name": m.senderName ?? "Unknown",
                "content": m.content,
                "timestamp": ISO8601DateFormatter().string(from: m.timestamp),
                "is_from_current_user": m.isFromCurrentUser
            ]
        }
        let body: [String: Any] = [
            "selected_message": selectedMessage,
            "conversation_history": historyPayload
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // DEBUG: Log request
        print("🔍 [DEBUG] message_context REQUEST:")
        print("  URL: \(url.absoluteString)")
        print("  Selected Message: \(selectedMessage)")
        print("  Conversation History Count: \(conversationHistory.count)")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("  Request Body: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // DEBUG: Log raw response
        print("🔍 [DEBUG] message_context RESPONSE:")
        if let httpResponse = response as? HTTPURLResponse {
            print("  Status Code: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("  Raw Response: \(responseString)")
        }
        
        // Parse JSON response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [DEBUG] Failed to parse JSON response")
            throw NSError(domain: "FirebaseAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        // DEBUG: Log parsed JSON
        print("🔍 [DEBUG] Parsed JSON keys: \(json.keys)")
        if let context = json["context"] as? String {
            print("  Context length: \(context.count) chars")
            print("  Context preview: \(context.prefix(100))...")
        } else {
            print("  ⚠️ No 'context' key found in response")
        }
        if let error = json["error"] as? String {
            print("  ❌ Error in response: \(error)")
        }
        
        // Check for error response from server
        if let errorMessage = json["error"] as? String {
            print("❌ [DEBUG] Server returned error: \(errorMessage)")
            throw NSError(domain: "FirebaseAIService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = json["error"] as? String ?? "Unknown error"
            print("❌ [DEBUG] Bad status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw NSError(domain: "FirebaseAIService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Extract context
        guard let context = json["context"] as? String, !context.isEmpty else {
            print("❌ [DEBUG] Context is empty or missing")
            throw NSError(domain: "FirebaseAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty context returned from server"])
        }
        
        print("✅ [DEBUG] Successfully extracted context (\(context.count) chars)")
        return context
    }
    
    func generateTutorResponse(
        userMessage: String,
        conversationHistory: [[String: String]],
        learningLanguageCode: String,
        primaryLanguageCode: String
    ) async throws -> TutorResponse {
        guard let url = URL(string: "\(baseFunctionsURL)/language_tutor") else {
            throw NSError(
                domain: "FirebaseAIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_message": userMessage,
            "conversation_history": conversationHistory,
            "learning_language": learningLanguageCode,
            "primary_language": primaryLanguageCode
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "FirebaseAIService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            )
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "FirebaseAIService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server error: \(errorMessage)"]
            )
        }
        
        // Decode response
        let decoder = JSONDecoder()
        let tutorResponse = try decoder.decode(TutorResponse.self, from: data)
        
        return tutorResponse
    }
}

