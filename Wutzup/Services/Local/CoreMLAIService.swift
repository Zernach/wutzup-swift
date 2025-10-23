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
        // Enhanced local generation with contextual analysis
        // Uses NaturalLanguage framework for topic extraction and sentiment
        
        
        // Get the last few messages for context
        let recentMessages = conversationHistory.suffix(5)
        
        // Preferably respond to messages from other participants, but if there are none,
        // use the last message in the conversation (which could be from current user)
        let messagesFromOthers = recentMessages.filter { !$0.isFromCurrentUser }
        let lastMessage = messagesFromOthers.last ?? recentMessages.last
        
        guard let messageToRespondTo = lastMessage else {
            throw NSError(domain: "CoreMLAIService", code: 400, 
                         userInfo: [NSLocalizedDescriptionKey: "No messages available"])
        }
        
        // Analyze sentiment, topics, and message characteristics
        // Use messages from others if available, otherwise use all recent messages
        let messagesToAnalyze = messagesFromOthers.isEmpty ? Array(recentMessages) : Array(messagesFromOthers)
        let sentiment = analyzeSentiment(messages: messagesToAnalyze)
        let topics = extractTopics(from: messageToRespondTo.content)
        let messageLength = classifyMessageLength(messageToRespondTo.content)
        let isQuestion = messageToRespondTo.content.contains("?")
        
        let isRespondingToSelf = messageToRespondTo.isFromCurrentUser
        
        // Generate contextual responses based on comprehensive analysis
        let positiveResponse = generateDetailedPositiveResponse(
            lastMessage: messageToRespondTo,
            topics: topics,
            sentiment: sentiment,
            messageLength: messageLength,
            isQuestion: isQuestion,
            personality: userPersonality
        )
        
        let negativeResponse = generateDetailedNegativeResponse(
            lastMessage: messageToRespondTo,
            topics: topics,
            sentiment: sentiment,
            messageLength: messageLength,
            isQuestion: isQuestion,
            personality: userPersonality
        )
        
        
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
    
    // MARK: - Topic Extraction
    
    private func extractTopics(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        var topics: [String] = []
        
        // Extract named entities (people, places, organizations)
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType) { tag, tokenRange in
            if tag != nil {
                let topic = String(text[tokenRange])
                if topic.count > 2 {
                    topics.append(topic)
                }
            }
            return true
        }
        
        // Also extract important nouns
        if topics.isEmpty {
            tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                                unit: .word,
                                scheme: .lexicalClass) { tag, tokenRange in
                if let tag = tag, tag == .noun {
                    let topic = String(text[tokenRange])
                    if topic.count > 3 { // Longer words are more meaningful
                        topics.append(topic)
                    }
                }
                return true
            }
        }
        
        return Array(topics.prefix(3)) // Return up to 3 topics
    }
    
    // MARK: - Message Classification
    
    private func classifyMessageLength(_ text: String) -> MessageLength {
        let wordCount = text.split(separator: " ").count
        if wordCount < 5 { return .short }
        if wordCount < 15 { return .medium }
        return .long
    }
    
    private enum MessageLength: String {
        case short
        case medium
        case long
    }
    
    // MARK: - Detailed Response Generators
    
    private func generateDetailedPositiveResponse(
        lastMessage: Message,
        topics: [String],
        sentiment: Double,
        messageLength: MessageLength,
        isQuestion: Bool,
        personality: String?
    ) -> String {
        let content = lastMessage.content.lowercased()
        
        // Question responses (detailed and helpful)
        if isQuestion {
            if content.contains("how") {
                return "That's a great question! I'd love to share my thoughts on that. Let me think about the best way to explain it to you."
            } else if content.contains("what") || content.contains("where") || content.contains("when") {
                return "Good question! I actually have some experience with this. I think the key thing to consider here is the context and details."
            } else if content.contains("why") {
                return "That's really thought-provoking! From my perspective, I think it comes down to a few different factors that are worth exploring together."
            } else if content.contains("do you") || content.contains("can you") {
                return "I'd be happy to help with that! Let me see what I can do. What specific aspect would you like me to focus on?"
            }
            return "That's an interesting question! I'd be happy to discuss this more with you. What specifically are you most curious about?"
        }
        
        // Topic-based responses (longer and more engaged)
        if !topics.isEmpty {
            let topic = topics.first!
            if sentiment > 0.3 {
                return "That's wonderful news about \(topic)! I'm really excited to hear that. How long have you been working on this? I'd love to know more details!"
            } else if sentiment > 0 {
                return "Thanks for sharing about \(topic). That sounds really interesting! I've been thinking about something similar lately. What made you decide to pursue this?"
            } else {
                return "I appreciate you mentioning \(topic). That's definitely something worth discussing further. What's been your experience with it so far?"
            }
        }
        
        // Sentiment-based longer responses
        if sentiment > 0.5 {
            return "That's absolutely fantastic! I'm so happy to hear things are going well for you. It sounds like you've put a lot of effort into this. What's been the most rewarding part?"
        } else if sentiment > 0.3 {
            return "That sounds really positive! I'm glad to hear that. It's great when things work out the way we hope they will. What are you planning to do next?"
        } else if sentiment > 0 {
            return "That's nice to hear! Thanks for keeping me updated on this. I really appreciate you sharing these details with me. How has everything else been going?"
        }
        
        // Engagement-based responses by message length
        switch messageLength {
        case .long:
            return "Wow, thanks for sharing all those details! That really helps me understand the situation better. From what you're describing, it sounds like there's quite a lot happening. What do you think is the most important aspect?"
        case .medium:
            return "Thanks for explaining that! I really appreciate you taking the time to share this with me. It sounds like you've given this a lot of thought. What's your next step?"
        case .short:
            return "Got it! That makes sense to me. I'd love to hear more about your thoughts on this if you're up for sharing. What else is on your mind?"
        }
    }
    
    private func generateDetailedNegativeResponse(
        lastMessage: Message,
        topics: [String],
        sentiment: Double,
        messageLength: MessageLength,
        isQuestion: Bool,
        personality: String?
    ) -> String {
        let content = lastMessage.content.lowercased()
        
        // Empathetic responses to questions
        if isQuestion {
            if content.contains("why") || content.contains("how") {
                return "I'm not entirely sure about that, but I appreciate you asking. Maybe we could figure this out together? What are your initial thoughts on it?"
            }
            return "That's a fair question. I don't have a strong opinion either way, but I'm interested in hearing more about what you think. What's your perspective?"
        }
        
        // Topic-based neutral/supportive responses (longer)
        if !topics.isEmpty {
            let topic = topics.first!
            if sentiment < -0.3 {
                return "I'm sorry to hear you're dealing with challenges around \(topic). That sounds really difficult and frustrating. Is there anything specific I can help with, or would you just like someone to listen?"
            } else if sentiment < 0 {
                return "Thanks for mentioning \(topic). I understand where you're coming from on this one. It's definitely something worth considering carefully. How are you feeling about it overall?"
            } else {
                return "I appreciate you bringing up \(topic). That's certainly an important consideration. What do you think would be the best approach to handle this situation?"
            }
        }
        
        // Sentiment-based longer neutral/empathetic responses
        if sentiment < -0.3 {
            return "I'm really sorry you're going through this right now. That sounds incredibly tough, and I want you to know I'm here for you. Would it help to talk more about what's been happening?"
        } else if sentiment < 0 {
            return "I hear you, and I understand that's not an ideal situation. It's completely okay to feel frustrated or uncertain about these things. What do you think might help make it better?"
        }
        
        // Neutral acknowledgment responses by message length
        switch messageLength {
        case .long:
            return "I really appreciate you sharing all of that with me. It sounds like you've been dealing with quite a bit lately. I want to make sure I understand everything - is there a particular part you'd like to focus on first?"
        case .medium:
            return "Thanks for letting me know about this. I can definitely see why that would be on your mind. What's been your experience with this so far?"
        case .short:
            return "I understand. Sometimes it's hard to know what to say in these situations, but I'm here if you want to talk more about it. No pressure though!"
        }
    }
}

