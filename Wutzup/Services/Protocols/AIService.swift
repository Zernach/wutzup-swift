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

protocol AIService: AnyObject {
    func generateResponseSuggestions(
        conversationHistory: [Message],
        userPersonality: String?
    ) async throws -> AIResponseSuggestion
}

