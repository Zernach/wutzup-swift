//
//  TutorChatService.swift
//  Wutzup
//
//  Created on October 25, 2025
//

import Foundation

/// Service protocol for AI-powered tutor chat interactions
protocol TutorChatService: Sendable {
    /// Generate an initial greeting from a tutor when a conversation is created
    /// - Parameters:
    ///   - tutorId: The tutor's user ID
    ///   - tutorPersonality: The tutor's personality description
    ///   - tutorName: The tutor's display name
    ///   - userName: The human user's name
    ///   - conversationId: The conversation ID
    /// - Returns: The generated greeting message
    func generateTutorGreeting(
        tutorId: String,
        tutorPersonality: String,
        tutorName: String,
        userName: String,
        conversationId: String
    ) async throws -> String
    
    /// Generate a tutor response based on conversation history
    /// - Parameters:
    ///   - tutorId: The tutor's user ID
    ///   - tutorPersonality: The tutor's personality description
    ///   - tutorName: The tutor's display name
    ///   - conversationHistory: Array of recent messages in the conversation
    ///   - conversationId: The conversation ID
    /// - Returns: The generated tutor response
    func generateTutorResponse(
        tutorId: String,
        tutorPersonality: String,
        tutorName: String,
        conversationHistory: [TutorChatMessage],
        conversationId: String
    ) async throws -> String
}

/// Message structure for tutor chat history
struct TutorChatMessage: Codable, Sendable {
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: String?
}

