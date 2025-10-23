//
//  CoreMLAIService.swift
//  Wutzup
//
//  Created on October 22, 2025
//
//  Enhanced with CoreML-based text generation using on-device LLM models
//

import Foundation
import CoreML
import NaturalLanguage

class CoreMLAIService: AIService {
    
    // Optional: Language model for advanced text generation
    // To use this, add a CoreML LLM model (e.g., Mistral-7B-Instruct or Llama-2-7b-chat)
    // Download from: https://huggingface.co/models?library=coreml&pipeline_tag=text-generation
    private var languageModel: MLModel?
    
    // Cache for embeddings and language understanding
    private let embeddingModel: NLEmbedding?
    
    init() {
        // Try to load sentence embedding model for better semantic understanding
        self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
        
        // Attempt to load LLM model if available in the bundle
        // Add your .mlmodel file to the project and update the name here
        // Example model names: "MistralCoreML", "Llama2Chat", "GPT2CoreML"
        self.languageModel = nil // Set to nil by default; uncomment below when model is added
        
        // Uncomment when you add a CoreML LLM model to your project:
        // do {
        //     let config = MLModelConfiguration()
        //     config.computeUnits = .cpuAndNeuralEngine // Use Neural Engine for efficiency
        //     self.languageModel = try MLModel(contentsOf: modelURL, configuration: config)
        // } catch {
        //     print("⚠️ CoreML LLM model not available, using enhanced NaturalLanguage fallback: \(error)")
        // }
    }
    
    func generateResponseSuggestions(
        conversationHistory: [Message],
        userPersonality: String?
    ) async throws -> AIResponseSuggestion {
        // Get the last few messages for context
        let recentMessages = conversationHistory.suffix(5)
        
        // Preferably respond to messages from other participants
        let messagesFromOthers = recentMessages.filter { !$0.isFromCurrentUser }
        let lastMessage = messagesFromOthers.last ?? recentMessages.last
        
        guard let messageToRespondTo = lastMessage else {
            throw NSError(domain: "CoreMLAIService", code: 400, 
                         userInfo: [NSLocalizedDescriptionKey: "No messages available"])
        }
        
        // Analyze conversation context using NaturalLanguage framework
        let messagesToAnalyze = messagesFromOthers.isEmpty ? Array(recentMessages) : Array(messagesFromOthers)
        let context = analyzeContext(messages: messagesToAnalyze, currentMessage: messageToRespondTo)
        
        // Try to generate responses using LLM if available
        if let llmResponses = await generateLLMResponses(context: context, personality: userPersonality) {
            return llmResponses
        }
        
        // Fallback to enhanced template-based generation with dynamic content
        let positiveResponse = await generateDynamicPositiveResponse(
            context: context,
            personality: userPersonality
        )
        
        let negativeResponse = await generateDynamicNegativeResponse(
            context: context,
            personality: userPersonality
        )
        
        return AIResponseSuggestion(
            positiveResponse: positiveResponse,
            negativeResponse: negativeResponse
        )
    }
    
    // MARK: - Context Analysis
    
    /// Comprehensive context structure for understanding conversation
    private struct ConversationContext {
        let sentiment: Double
        let topics: [String]
        let entities: [Entity]
        let messageLength: MessageLength
        let isQuestion: Bool
        let questionType: QuestionType?
        let dominantEmotion: Emotion
        let semanticThemes: [String]
        let lastMessage: Message
        let conversationHistory: String
    }
    
    private enum MessageLength {
        case short, medium, long
    }
    
    private enum QuestionType {
        case how, what, `where`, `when`, why, yesNo, other
    }
    
    private enum Emotion {
        case positive, negative, neutral, excited, concerned, curious
    }
    
    private struct Entity {
        let text: String
        let type: NLTag
    }
    
    /// Analyze conversation context using NaturalLanguage framework
    private func analyzeContext(messages: [Message], currentMessage: Message) -> ConversationContext {
        let text = currentMessage.content
        let tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType, .lexicalClass])
        tagger.string = text
        
        // Sentiment analysis
        let sentiment = analyzeSentiment(text: text, tagger: tagger)
        
        // Topic and entity extraction
        let topics = extractTopics(from: text, tagger: tagger)
        let entities = extractEntities(from: text, tagger: tagger)
        
        // Question analysis
        let isQuestion = text.contains("?")
        let questionType = isQuestion ? classifyQuestion(text) : nil
        
        // Message characteristics
        let messageLength = classifyMessageLength(text)
        let dominantEmotion = classifyEmotion(sentiment: sentiment, text: text)
        
        // Semantic themes using embedding similarity
        let semanticThemes = extractSemanticThemes(from: text)
        
        // Build conversation history context
        let conversationHistory = messages.suffix(3).map { $0.content }.joined(separator: " ")
        
        return ConversationContext(
            sentiment: sentiment,
            topics: topics,
            entities: entities,
            messageLength: messageLength,
            isQuestion: isQuestion,
            questionType: questionType,
            dominantEmotion: dominantEmotion,
            semanticThemes: semanticThemes,
            lastMessage: currentMessage,
            conversationHistory: conversationHistory
        )
    }
    
    private func analyzeSentiment(text: String, tagger: NLTagger) -> Double {
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentimentValue = sentiment?.rawValue, let score = Double(sentimentValue) {
            return score
        }
        return 0.0
    }
    
    private func extractTopics(from text: String, tagger: NLTagger) -> [String] {
        tagger.string = text
        var topics: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, tag == .noun {
                let topic = String(text[tokenRange])
                if topic.count > 3 {
                    topics.append(topic)
                }
            }
            return true
        }
        
        return Array(topics.prefix(3))
    }
    
    private func extractEntities(from text: String, tagger: NLTagger) -> [Entity] {
        tagger.string = text
        var entities: [Entity] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let entityText = String(text[tokenRange])
                entities.append(Entity(text: entityText, type: tag))
            }
            return true
        }
        
        return entities
    }
    
    private func classifyMessageLength(_ text: String) -> MessageLength {
        let wordCount = text.split(separator: " ").count
        if wordCount < 5 { return .short }
        if wordCount < 15 { return .medium }
        return .long
    }
    
    private func classifyQuestion(_ text: String) -> QuestionType {
        let lowercased = text.lowercased()
        if lowercased.contains("how") { return .how }
        if lowercased.contains("what") { return .what }
        if lowercased.contains("where") { return .`where` }
        if lowercased.contains("when") { return .`when` }
        if lowercased.contains("why") { return .why }
        if lowercased.contains("do you") || lowercased.contains("can you") || 
           lowercased.contains("will you") || lowercased.contains("are you") {
            return .yesNo
        }
        return .other
    }
    
    private func classifyEmotion(sentiment: Double, text: String) -> Emotion {
        let lowercased = text.lowercased()
        let excitementWords = ["amazing", "awesome", "excited", "wow", "great", "fantastic", "love"]
        let concernWords = ["worried", "concerned", "anxious", "nervous", "afraid"]
        let curiousWords = ["wonder", "curious", "interested", "thinking"]
        
        if excitementWords.contains(where: lowercased.contains) {
            return .excited
        }
        if concernWords.contains(where: lowercased.contains) {
            return .concerned
        }
        if curiousWords.contains(where: lowercased.contains) {
            return .curious
        }
        
        if sentiment > 0.3 { return .positive }
        if sentiment < -0.3 { return .negative }
        return .neutral
    }
    
    private func extractSemanticThemes(from text: String) -> [String] {
        // Use NLEmbedding to find semantic themes
        guard let embedding = embeddingModel else {
            return []
        }
        
        // Extract key phrases using tokenization
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        var themes: [String] = []
        var currentPhrase: [String] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            if token.count > 3 {
                currentPhrase.append(token)
                if currentPhrase.count >= 2 {
                    themes.append(currentPhrase.joined(separator: " "))
                    currentPhrase.removeFirst()
                }
            }
            return true
        }
        
        return Array(themes.prefix(3))
    }
    
    // MARK: - LLM-Based Response Generation
    
    /// Generate responses using CoreML LLM model if available
    private func generateLLMResponses(
        context: ConversationContext,
        personality: String?
    ) async -> AIResponseSuggestion? {
        guard let model = languageModel else {
            return nil
        }
        
        // Build prompts for positive and negative responses
        let positivePrompt = buildPrompt(
            context: context,
            tone: .positive,
            personality: personality
        )
        
        let negativePrompt = buildPrompt(
            context: context,
            tone: .negative,
            personality: personality
        )
        
        // Generate responses using the model
        do {
            let positiveResponse = try await generateTextWithModel(model: model, prompt: positivePrompt)
            let negativeResponse = try await generateTextWithModel(model: model, prompt: negativePrompt)
            
            return AIResponseSuggestion(
                positiveResponse: positiveResponse,
                negativeResponse: negativeResponse
            )
        } catch {
            print("⚠️ LLM generation failed: \(error)")
            return nil
        }
    }
    
    private enum ToneType {
        case positive, negative
    }
    
    /// Build a structured prompt for the LLM
    private func buildPrompt(context: ConversationContext, tone: ToneType, personality: String?) -> String {
        var prompt = "You are a helpful, friendly conversational assistant. "
        
        if let personality = personality {
            prompt += "Your personality is: \(personality). "
        }
        
        prompt += "\n\nConversation history:\n\(context.conversationHistory)\n\n"
        prompt += "Latest message: \"\(context.lastMessage.content)\"\n\n"
        
        // Add context information
        if !context.topics.isEmpty {
            prompt += "Key topics: \(context.topics.joined(separator: ", "))\n"
        }
        
        if !context.entities.isEmpty {
            prompt += "Mentioned: \(context.entities.map { $0.text }.joined(separator: ", "))\n"
        }
        
        prompt += "Sentiment: \(context.sentiment > 0 ? "positive" : context.sentiment < 0 ? "negative" : "neutral")\n"
        
        // Specify response tone
        switch tone {
        case .positive:
            prompt += "\nGenerate an enthusiastic, agreeable response that shows engagement and support. "
            if context.isQuestion {
                prompt += "Answer the question helpfully and thoroughly. "
            }
        case .negative:
            prompt += "\nGenerate a polite, empathetic response that shows understanding but provides an alternative perspective or gentle disagreement. "
            if context.isQuestion {
                prompt += "Acknowledge the question but express some uncertainty or provide a balanced view. "
            }
        }
        
        prompt += "Keep the response natural, conversational, and under 50 words.\n\nResponse:"
        
        return prompt
    }
    
    /// Generate text using CoreML model
    private func generateTextWithModel(model: MLModel, prompt: String) async throws -> String {
        // This is a simplified example. The actual implementation depends on your specific model's input/output format.
        // Most CoreML LLM models require specific input features and configurations.
        
        // For models like Mistral-7B-Instruct or Llama-2-7b-chat converted to CoreML:
        // 1. Create input features (usually text or token IDs)
        // 2. Run prediction
        // 3. Extract generated text from output
        
        // Run on background thread since CoreML inference can be intensive
        return try await Task {
            let inputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "input"
            let outputName = model.modelDescription.outputDescriptionsByName.keys.first ?? "output"
            
            guard let inputFeature = try? MLFeatureValue(string: prompt),
                  let inputProvider = try? MLDictionaryFeatureProvider(dictionary: [inputName: inputFeature]) else {
                throw NSError(domain: "CoreMLAIService", code: 500, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to create input features"])
            }
            
            let prediction = try model.prediction(from: inputProvider)
            
            guard let outputValue = prediction.featureValue(for: outputName) else {
                throw NSError(domain: "CoreMLAIService", code: 500, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to extract output features"])
            }
            
            // Try to get string value - different models have different output types
            // MLFeatureValue.stringValue is optional, so we need to check it exists
            if outputValue.type == .string {
                // When type is .string, stringValue should contain the string
                let generatedText = outputValue.stringValue ?? ""
                if generatedText.isEmpty {
                    throw NSError(domain: "CoreMLAIService", code: 500,
                                 userInfo: [NSLocalizedDescriptionKey: "Model returned empty string"])
                }
                return cleanGeneratedText(generatedText)
            } else if outputValue.type == .multiArray {
                // Some models return token IDs as MLMultiArray - this would need a tokenizer
                throw NSError(domain: "CoreMLAIService", code: 501,
                             userInfo: [NSLocalizedDescriptionKey: "Model output requires token decoding (not yet implemented)"])
            } else {
                throw NSError(domain: "CoreMLAIService", code: 500,
                             userInfo: [NSLocalizedDescriptionKey: "Unsupported model output type: \(outputValue.type)"])
            }
        }.value
    }
    
    /// Clean and post-process generated text
    private func cleanGeneratedText(_ text: String) -> String {
        // Remove any prompt artifacts, extra whitespace, etc.
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common generation artifacts
        if let responseStart = cleaned.range(of: "Response:") {
            cleaned = String(cleaned[responseStart.upperBound...])
        }
        
        // Trim to a reasonable length
        let words = cleaned.split(separator: " ")
        if words.count > 50 {
            cleaned = words.prefix(50).joined(separator: " ") + "..."
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Enhanced Template-Based Response Generation
    
    /// Generate dynamic positive response using templates enhanced with NLP analysis
    private func generateDynamicPositiveResponse(
        context: ConversationContext,
        personality: String?
    ) async -> String {
        // Use NLP context to build more dynamic responses
        var responseComponents: [String] = []
        
        // Handle questions with specific question types
        if context.isQuestion, let questionType = context.questionType {
            responseComponents.append(generateQuestionResponse(type: questionType, context: context, isPositive: true))
        }
        
        // Add topic-specific engagement
        if !context.topics.isEmpty {
            responseComponents.append(generateTopicEngagement(topics: context.topics, context: context))
        }
        
        // Add emotion-specific language
        responseComponents.append(generateEmotionResponse(emotion: context.dominantEmotion, isPositive: true))
        
        // Combine and return
        var response = responseComponents.joined(separator: " ")
        
        // Add personality touch if available
        if let personality = personality {
            response = addPersonalityTouch(response: response, personality: personality)
        }
        
        return response
    }
    
    /// Generate dynamic negative response using templates enhanced with NLP analysis
    private func generateDynamicNegativeResponse(
        context: ConversationContext,
        personality: String?
    ) async -> String {
        var responseComponents: [String] = []
        
        // Handle questions with empathy
        if context.isQuestion, let questionType = context.questionType {
            responseComponents.append(generateQuestionResponse(type: questionType, context: context, isPositive: false))
        }
        
        // Add topic-specific consideration
        if !context.topics.isEmpty {
            responseComponents.append(generateTopicConsideration(topics: context.topics, context: context))
        }
        
        // Add emotion-appropriate response
        responseComponents.append(generateEmotionResponse(emotion: context.dominantEmotion, isPositive: false))
        
        var response = responseComponents.joined(separator: " ")
        
        if let personality = personality {
            response = addPersonalityTouch(response: response, personality: personality)
        }
        
        return response
    }
    
    // MARK: - Response Component Generators
    
    private func generateQuestionResponse(type: QuestionType, context: ConversationContext, isPositive: Bool) -> String {
        let templates: [QuestionType: (positive: [String], negative: [String])] = [
            .how: (
                positive: [
                    "Great question! I think I can walk you through that.",
                    "That's something I've thought about before. Here's my take:",
                    "I'm glad you asked! Let me share what I know."
                ],
                negative: [
                    "That's a thoughtful question. I'm not entirely sure about all the details.",
                    "Interesting question. I don't have all the answers, but let's explore it together.",
                    "I appreciate you asking. I might need to think more about that one."
                ]
            ),
            .what: (
                positive: [
                    "Good question! I actually have some thoughts on that.",
                    "I've been wondering about that too. Here's what I think:",
                    "That's worth discussing! Let me tell you what I know."
                ],
                negative: [
                    "That's a fair question. I'm not completely sure about that.",
                    "Interesting point. I don't have a definitive answer on that one.",
                    "I appreciate you bringing that up. I'd need to consider it more."
                ]
            ),
            .why: (
                positive: [
                    "That's a really thought-provoking question!",
                    "Great observation! I think there are a few reasons for that.",
                    "You're asking the right questions. Here's my perspective:"
                ],
                negative: [
                    "That's a complex question. I'm not sure I have all the answers.",
                    "Interesting question. I think there might be multiple perspectives on that.",
                    "Good question. I'm not entirely convinced I know the full story there."
                ]
            ),
            .yesNo: (
                positive: [
                    "Absolutely! I'd be happy to help with that.",
                    "Yes! That sounds like something I can do.",
                    "I think so! Let me give it a try."
                ],
                negative: [
                    "I'm not entirely sure about that one.",
                    "That's a tough one. I might need to think about it.",
                    "I'm hesitant to say for certain. What do you think?"
                ]
            )
        ]
        
        let responseSet = templates[type] ?? templates[.what]!
        let options = isPositive ? responseSet.positive : responseSet.negative
        return options.randomElement() ?? options[0]
    }
    
    private func generateTopicEngagement(topics: [String], context: ConversationContext) -> String {
        guard let topic = topics.first else { return "" }
        
        let templates = [
            "I find \(topic) really interesting!",
            "Thanks for bringing up \(topic).",
            "\(topic) is definitely worth exploring more.",
            "I've been thinking about \(topic) lately too."
        ]
        
        return templates.randomElement() ?? templates[0]
    }
    
    private func generateTopicConsideration(topics: [String], context: ConversationContext) -> String {
        guard let topic = topics.first else { return "" }
        
        let templates = [
            "I hear what you're saying about \(topic).",
            "That's an interesting perspective on \(topic).",
            "I can see why you'd mention \(topic).",
            "\(topic) is certainly something to consider carefully."
        ]
        
        return templates.randomElement() ?? templates[0]
    }
    
    private func generateEmotionResponse(emotion: Emotion, isPositive: Bool) -> String {
        switch (emotion, isPositive) {
        case (.excited, true):
            return "That's so exciting! I'd love to hear more about this!"
        case (.excited, false):
            return "I can feel your excitement! Though I wonder if we should consider some other angles too."
        case (.concerned, true):
            return "I understand your concern, and I think we can work through this together."
        case (.concerned, false):
            return "I hear your concerns. It's okay to feel uncertain about this."
        case (.curious, true):
            return "Your curiosity is great! Let's explore this further."
        case (.curious, false):
            return "That's an interesting angle to consider. I'm curious about other perspectives too."
        case (.positive, true):
            return "That sounds wonderful! I'm really happy for you."
        case (.positive, false):
            return "That's nice! Though I wonder if there's more to consider."
        case (.negative, true):
            return "I'm sorry you're going through that. Things will get better!"
        case (.negative, false):
            return "I understand that's difficult. It's okay to feel that way."
        case (.neutral, true):
            return "Thanks for sharing that with me!"
        case (.neutral, false):
            return "I appreciate you letting me know."
        }
    }
    
    private func addPersonalityTouch(response: String, personality: String) -> String {
        // Simple personality modifier - in a real implementation, this could be more sophisticated
        let lowercasedPersonality = personality.lowercased()
        
        if lowercasedPersonality.contains("enthusiastic") || lowercasedPersonality.contains("energetic") {
            return response + " 😊"
        } else if lowercasedPersonality.contains("thoughtful") || lowercasedPersonality.contains("analytical") {
            return "Hmm, " + response
        } else if lowercasedPersonality.contains("warm") || lowercasedPersonality.contains("caring") {
            return response + " I'm here if you want to talk more."
        }
        
        return response
    }
}

