//
//  CoreMLAIService.swift
//  Wutzup
//
//  Created on October 22, 2025
//

import Foundation
import CoreML
import NaturalLanguage

class CoreMLAIService: AIService {
    
    func generateResponseSuggestions(
        conversationHistory: [Message],
        userPersonality: String?
    ) async throws -> AIResponseSuggestion {
        // For now, we'll use a simple local generation approach
        // This can be enhanced with actual CoreML models later
        
        print("🧠 [CoreMLAIService] Generating local AI suggestions...")
        print("   Conversation history: \(conversationHistory.count) messages")
        print("   User personality: \(userPersonality ?? "none")")
        
        // Get the last few messages for context
        let recentMessages = conversationHistory.suffix(5)
        let lastMessage = recentMessages.last
        
        // Analyze sentiment of recent messages
        let sentiment = analyzeSentiment(messages: Array(recentMessages))
        
        // Generate contextual responses based on sentiment
        let positiveResponse: String
        let negativeResponse: String
        
        if sentiment > 0.3 {
            // Positive context
            positiveResponse = generatePositiveResponse(lastMessage: lastMessage, personality: userPersonality)
            negativeResponse = generateNeutralResponse(lastMessage: lastMessage, personality: userPersonality)
        } else if sentiment < -0.3 {
            // Negative context
            positiveResponse = generateSupportiveResponse(lastMessage: lastMessage, personality: userPersonality)
            negativeResponse = generateEmpathyResponse(lastMessage: lastMessage, personality: userPersonality)
        } else {
            // Neutral context
            positiveResponse = generateEngagingResponse(lastMessage: lastMessage, personality: userPersonality)
            negativeResponse = generateCasualResponse(lastMessage: lastMessage, personality: userPersonality)
        }
        
        print("✅ [CoreMLAIService] Local AI suggestions generated!")
        print("   Positive: \(positiveResponse)")
        print("   Negative: \(negativeResponse)")
        
        return AIResponseSuggestion(
            positiveResponse: positiveResponse,
            negativeResponse: negativeResponse
        )
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(messages: [Message]) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        
        var totalSentiment: Double = 0
        var count = 0
        
        for message in messages {
            tagger.string = message.content
            let (sentiment, _) = tagger.tag(at: message.content.startIndex, unit: .paragraph, scheme: .sentimentScore)
            
            if let sentimentValue = sentiment?.rawValue, let score = Double(sentimentValue) {
                totalSentiment += score
                count += 1
            }
        }
        
        return count > 0 ? totalSentiment / Double(count) : 0
    }
    
    // MARK: - Response Generators
    
    private func generatePositiveResponse(lastMessage: Message?, personality: String?) -> String {
        let responses = [
            "That's awesome! 😊",
            "Love it! 🎉",
            "That's great to hear!",
            "Amazing! Tell me more!",
            "That sounds wonderful!",
            "I'm so happy for you! 💚"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateNeutralResponse(lastMessage: Message?, personality: String?) -> String {
        let responses = [
            "Thanks for sharing",
            "Got it",
            "Understood",
            "Noted",
            "Makes sense",
            "Interesting"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateSupportiveResponse(lastMessage: Message?, personality: String?) -> String {
        let responses = [
            "I'm here for you 💚",
            "That sounds tough. How can I help?",
            "Sending you good vibes",
            "Thanks for sharing that with me",
            "I appreciate you opening up",
            "You've got this! 💪"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateEmpathyResponse(lastMessage: Message?, personality: String?) -> String {
        let responses = [
            "I understand",
            "That makes sense",
            "I hear you",
            "Thanks for letting me know",
            "I appreciate that",
            "I see where you're coming from"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateEngagingResponse(lastMessage: Message?, personality: String?) -> String {
        let responses = [
            "Tell me more about that!",
            "What do you think?",
            "How was your day?",
            "What's new?",
            "How are you feeling?",
            "Want to chat about it?"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateCasualResponse(lastMessage: Message?, personality: String?) -> String {
        let responses = [
            "Cool",
            "Nice",
            "Sounds good",
            "Alright",
            "For sure",
            "Yeah, totally"
        ]
        return responses.randomElement() ?? responses[0]
    }
}

