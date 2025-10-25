//
//  FirebaseTutorChatService.swift
//  Wutzup
//
//  Created on October 25, 2025
//

import Foundation

/// Firebase implementation of TutorChatService using Cloud Functions
class FirebaseTutorChatService: TutorChatService {
    private let functionBaseURL: String
    
    init(projectId: String = "wutzup-swift") {
        self.functionBaseURL = "https://us-central1-\(projectId).cloudfunctions.net"
    }
    
    func generateTutorGreeting(
        tutorId: String,
        tutorPersonality: String,
        tutorName: String,
        userName: String,
        conversationId: String
    ) async throws -> String {
        let url = URL(string: "\(functionBaseURL)/generate_tutor_greeting")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "tutor_id": tutorId,
            "tutor_personality": tutorPersonality,
            "tutor_name": tutorName,
            "user_name": userName,
            "conversation_id": conversationId
        ]
        
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TutorChatError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TutorChatError.serverError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let greeting = json["greeting"] as? String else {
            throw TutorChatError.invalidResponseData
        }
        
        return greeting
    }
    
    func generateTutorResponse(
        tutorId: String,
        tutorPersonality: String,
        tutorName: String,
        conversationHistory: [TutorChatMessage],
        conversationId: String
    ) async throws -> String {
        let url = URL(string: "\(functionBaseURL)/generate_tutor_response")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert conversation history to JSON-compatible format
        let historyData = conversationHistory.map { message in
            [
                "sender_id": message.senderId,
                "sender_name": message.senderName,
                "content": message.content,
                "timestamp": message.timestamp ?? ""
            ]
        }
        
        let body: [String: Any] = [
            "tutor_id": tutorId,
            "tutor_personality": tutorPersonality,
            "tutor_name": tutorName,
            "conversation_history": historyData,
            "conversation_id": conversationId
        ]
        
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TutorChatError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TutorChatError.serverError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tutorResponse = json["response"] as? String else {
            throw TutorChatError.invalidResponseData
        }
        
        return tutorResponse
    }
}

/// Errors that can occur during tutor chat operations
enum TutorChatError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case invalidResponseData
    case missingTutorData
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .invalidResponseData:
            return "Invalid response data"
        case .missingTutorData:
            return "Missing tutor information"
        }
    }
}

