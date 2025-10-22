//
//  GIFService.swift
//  Wutzup
//
//  Protocol for GIF generation service
//

import Foundation

protocol GIFService {
    /// Generate a GIF from a text prompt using DALL-E
    /// - Parameters:
    ///   - prompt: The text description of the desired GIF
    /// - Returns: URL of the generated GIF in Firebase Storage
    func generateGIF(prompt: String) async throws -> String
}

enum GIFServiceError: Error, LocalizedError {
    case invalidPrompt
    case generationFailed(String)
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidPrompt:
            return "Please provide a valid prompt"
        case .generationFailed(let message):
            return "GIF generation failed: \(message)"
        case .networkError:
            return "Network error. Please check your connection"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

