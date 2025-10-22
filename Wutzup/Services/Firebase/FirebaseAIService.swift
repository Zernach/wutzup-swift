//
//  FirebaseAIService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

class FirebaseAIService: AIService {
    private let functionURL: String
    
    init(functionURL: String = "https://generate-response-suggestions-uv2bm2c2tq-uc.a.run.app") {
        // Cloud Function URL (2nd gen) - deployed via Firebase
        // Get this URL from: firebase deploy --only functions:generate_response_suggestions
        self.functionURL = functionURL
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
        
        // Prepare conversation history
        let messages = conversationHistory.map { message in
            return [
                "sender_id": message.senderId,
                "sender_name": message.senderName,
                "content": message.content,
                "timestamp": ISO8601DateFormatter().string(from: message.timestamp)
            ]
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
}

