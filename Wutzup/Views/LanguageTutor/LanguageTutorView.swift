//
//  LanguageTutorView.swift
//  Wutzup
//
//  Created on October 24, 2025
//

import SwiftUI

struct TutorMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isFromTutor: Bool
    let timestamp: Date
    let translation: String?
    
    init(content: String, isFromTutor: Bool, timestamp: Date = Date(), translation: String? = nil) {
        self.content = content
        self.isFromTutor = isFromTutor
        self.timestamp = timestamp
        self.translation = translation
    }
}

struct LanguageTutorView: View {
    let currentUser: User?
    let aiService: AIService
    
    @State private var messages: [TutorMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var learningLanguageName: String = "your learning language"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // Info Banner
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(AppConstants.Colors.accent)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language Tutor")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Text("Practice \(learningLanguageName) with an AI tutor")
                                .font(.caption)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppConstants.Colors.surface)
                }
                
                Divider()
                    .background(AppConstants.Colors.border)
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(messages) { message in
                                    TutorMessageBubble(message: message)
                                }
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(AppConstants.Colors.border)
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("Type your message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .padding(12)
                        .background(AppConstants.Colors.surfaceSecondary)
                        .cornerRadius(20)
                        .lineLimit(1...5)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? AppConstants.Colors.mutedIcon : AppConstants.Colors.accent)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppConstants.Colors.surface)
            }
        }
        .navigationTitle("Language Tutor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppConstants.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            setupTutor()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppConstants.Colors.mutedIcon)
            
            Text("Start Learning!")
                .font(.title2)
                .foregroundColor(AppConstants.Colors.textPrimary)
            
            Text("Say hello to your language tutor in \(learningLanguageName)")
                .font(.body)
                .foregroundColor(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
    
    private func setupTutor() {
        guard let user = currentUser else { return }
        
        // Get the learning language name
        if let langCode = user.learningLanguageCode,
           let supportedLang = SupportedLanguage(rawValue: langCode) {
            learningLanguageName = supportedLang.displayName
        }
        
        // Add welcome message from tutor
        let welcomeMessage = TutorMessage(
            content: getWelcomeMessage(),
            isFromTutor: true,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func getWelcomeMessage() -> String {
        guard let langCode = currentUser?.learningLanguageCode else {
            return "Hello! I'm your language tutor. Let's practice together! 🎓"
        }
        
        // Welcome messages in different languages
        switch langCode {
        case "es":
            return "¡Hola! Soy tu tutor de español. ¿Cómo estás hoy? 🎓"
        case "fr":
            return "Bonjour! Je suis votre tuteur de français. Comment allez-vous aujourd'hui? 🎓"
        case "de":
            return "Hallo! Ich bin Ihr Deutschlehrer. Wie geht es Ihnen heute? 🎓"
        case "it":
            return "Ciao! Sono il tuo tutor di italiano. Come stai oggi? 🎓"
        case "pt":
            return "Olá! Sou seu tutor de português. Como você está hoje? 🎓"
        case "zh":
            return "你好！我是你的中文老师。你今天好吗？🎓"
        case "ja":
            return "こんにちは！私はあなたの日本語の先生です。今日はお元気ですか？🎓"
        case "ko":
            return "안녕하세요! 저는 당신의 한국어 선생님입니다. 오늘 기분이 어때요? 🎓"
        case "ar":
            return "مرحبا! أنا معلمك للغة العربية. كيف حالك اليوم؟ 🎓"
        case "ru":
            return "Привет! Я твой учитель русского языка. Как дела сегодня? 🎓"
        case "hi":
            return "नमस्ते! मैं आपका हिंदी शिक्षक हूं। आज आप कैसे हैं? 🎓"
        default:
            return "Hello! I'm your language tutor. Let's practice together! 🎓"
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = TutorMessage(content: text, isFromTutor: false)
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        isLoading = true
        
        // Get AI response
        Task {
            do {
                let response = try await aiService.generateTutorResponse(
                    userMessage: text,
                    conversationHistory: messages.map { msg in
                        ["role": msg.isFromTutor ? "assistant" : "user", "content": msg.content]
                    },
                    learningLanguageCode: currentUser?.learningLanguageCode ?? "es",
                    primaryLanguageCode: currentUser?.primaryLanguageCode ?? "en"
                )
                
                await MainActor.run {
                    let tutorMessage = TutorMessage(
                        content: response.message,
                        isFromTutor: true,
                        translation: response.translation
                    )
                    messages.append(tutorMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct TutorMessageBubble: View {
    let message: TutorMessage
    @State private var showTranslation = false
    
    var body: some View {
        HStack {
            if !message.isFromTutor {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromTutor ? .leading : .trailing, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isFromTutor ? AppConstants.Colors.textPrimary : .white)
                    .padding(12)
                    .background(message.isFromTutor ? AppConstants.Colors.surface : AppConstants.Colors.accent)
                    .cornerRadius(16)
                
                // Translation toggle for tutor messages
                if message.isFromTutor, let translation = message.translation {
                    Button(action: {
                        withAnimation {
                            showTranslation.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showTranslation ? "eye.slash" : "eye")
                                .font(.caption)
                            Text(showTranslation ? "Hide translation" : "Show translation")
                                .font(.caption)
                        }
                        .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    
                    if showTranslation {
                        Text(translation)
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                            .italic()
                            .padding(.horizontal, 8)
                    }
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
            
            if message.isFromTutor {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LanguageTutorView(
            currentUser: User(
                id: "test",
                email: "test@wutzup.app",
                displayName: "Test User",
                primaryLanguageCode: "en",
                learningLanguageCode: "es"
            ),
            aiService: PreviewAIService()
        )
    }
}

private final class PreviewAIService: AIService {
    func generateResponseSuggestions(conversationHistory: [Message], userPersonality: String?) async throws -> AIResponseSuggestion {
        AIResponseSuggestion(
            positiveResponse: "That's great!",
            negativeResponse: "I'm not sure about that."
        )
    }
    
    func generateTutorResponse(userMessage: String, conversationHistory: [[String: String]], learningLanguageCode: String, primaryLanguageCode: String) async throws -> TutorResponse {
        TutorResponse(
            message: "¡Muy bien! That's a great start!",
            translation: "Very good! That's a great start!"
        )
    }
}

