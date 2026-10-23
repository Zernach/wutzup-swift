//
//  ArchlifeTutorChatService.swift
//  Wutzup
//
//  Created on October 25, 2025
//

import Foundation

/// Archlife API implementation using the existing Firebase identity and Archlife chat data.
class ArchlifeTutorChatService: TutorChatService {
    private let functionBaseURL: String
    
    init(baseURL: String = ArchlifeWutzupAPI.baseURL) {
        self.functionBaseURL = baseURL
    }
    
    func generateTutorGreeting(
        tutorId: String,
        tutorPersonality: String,
        tutorName: String,
        userName: String,
        conversationId: String,
        groupName: String?
    ) async throws -> String {
        let url = URL(string: "\(functionBaseURL)/generate_tutor_greeting")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Archlife resolves names, personality and group context from saved records.
        let body: [String: Any] = [
            "tutor_id": tutorId,
            "conversation_id": conversationId
        ]
        
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await ArchlifeWutzupAPI.send(request)
        
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
        
        // Conversation history is read by the API after membership validation.
        let body: [String: Any] = [
            "tutor_id": tutorId,
            "conversation_id": conversationId
        ]
        
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await ArchlifeWutzupAPI.send(request)
        
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

