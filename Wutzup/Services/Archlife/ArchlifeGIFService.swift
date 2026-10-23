//
//  ArchlifeGIFService.swift
//  Wutzup
//
//  Archlife implementation for GIF generation service
//

import Foundation

final class ArchlifeGIFService: GIFService {
    private let cloudFunctionURL: String
    
    init(baseURL: String = ArchlifeWutzupAPI.baseURL) {
        self.cloudFunctionURL = "\(baseURL)/generate_gif"
    }
    
    func generateGIF(prompt: String) async throws -> String {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GIFServiceError.invalidPrompt
        }
        
        // Prepare request
        guard let url = URL(string: cloudFunctionURL) else {
            throw GIFServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await ArchlifeWutzupAPI.send(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GIFServiceError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GIFServiceError.generationFailed(errorMessage)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let gifURL = json["gif_url"] as? String else {
            throw GIFServiceError.invalidResponse
        }
        
        return gifURL
    }
}

