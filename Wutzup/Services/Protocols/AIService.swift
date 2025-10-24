//
//  AIService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

struct AIResponseSuggestion: Codable, Identifiable {
    let id = UUID()
    let positiveResponse: String
    let negativeResponse: String
    
    enum CodingKeys: String, CodingKey {
        case positiveResponse = "positive_response"
        case negativeResponse = "negative_response"
    }
}

struct TutorResponse: Codable {
    let message: String
    let translation: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case translation
    }
}

protocol AIService: AnyObject {
    func generateResponseSuggestions(
        conversationHistory: [Message],
        userPersonality: String?
    ) async throws -> AIResponseSuggestion
    
    func generateTutorResponse(
        userMessage: String,
        conversationHistory: [[String: String]],
        learningLanguageCode: String,
        primaryLanguageCode: String
    ) async throws -> TutorResponse
}

