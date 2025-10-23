//
//  FirebaseResearchService.swift
//  Wutzup
//
//  Firebase Cloud Function implementation for web research
//

import Foundation

class FirebaseResearchService: ResearchService {
    private let baseURL: String
    
    init() {
        // Get the Firebase Functions URL from environment or use default
        // Production: https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net
        // For local testing: http://127.0.0.1:5001/YOUR-PROJECT-ID/us-central1
        #if DEBUG
        // Use emulator in debug mode (if available)
        self.baseURL = "https://us-central1-wutzup-swift.cloudfunctions.net"
        #else
        self.baseURL = "https://us-central1-wutzup-swift.cloudfunctions.net"
        #endif
    }
    
    func conductResearch(prompt: String) async throws -> String {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ResearchError.invalidPrompt
        }
        
        // Create request URL
        guard let url = URL(string: "\(baseURL)/conduct_research") else {
            throw ResearchError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let requestBody: [String: Any] = [
            "prompt": prompt
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResearchError.invalidResponse
        }
        
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJSON["error"] as? String {
                throw ResearchError.serverError(errorMessage)
            }
            throw ResearchError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String else {
            throw ResearchError.invalidResponse
        }
        
        
        return summary
    }
}

enum ResearchError: LocalizedError {
    case invalidPrompt
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPrompt:
            return "Please enter a valid research question."
        case .invalidURL:
            return "Invalid service URL."
        case .invalidResponse:
            return "Failed to parse server response."
        case .httpError(let code):
            return "Server error: HTTP \(code)"
        case .serverError(let message):
            return message
        }
    }
}

