//
//  MessageActionsToolbar.swift
//  Wutzup
//
//  Message actions toolbar with glass morphism effect
//

import SwiftUI

// MARK: - Shared Language Enum (available on all iOS versions)
enum TranslationLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case arabic = "ar"
    case russian = "ru"
    case hindi = "hi"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .arabic: return "Arabic"
        case .russian: return "Russian"
        case .hindi: return "Hindi"
        }
    }
}

struct MessageActionsToolbar: View {
    let messageText: String
    let conversationHistory: [Message]?
    let learningLanguageCode: String? // User's selected learning language
    let onDismiss: () -> Void
    let onTranslationComplete: (String, String) -> Void  // (translatedText, languageName)
    let onContextComplete: (String) -> Void
    @State private var isTranslating = false
    @State private var copyFeedback = false
    @State private var showingUnsupportedAlert = false
    @State private var isLoadingContext = false
    @State private var translatedText: String = ""
    @State private var showingTranslation = false
    @State private var contextText: String = ""
    @State private var showingContext = false
    @State private var showingContextError = false
    @State private var contextErrorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Main action buttons
            HStack(spacing: 4) {
                // Copy Button
                actionButton(
                    icon: copyFeedback ? "checkmark" : "doc.on.doc",
                    iconColor: copyFeedback ? AppConstants.Colors.brightGreen : AppConstants.Colors.accent,
                    title: copyFeedback ? "Copied!" : "Copy",
                    action: {
                        copyToClipboard()
                    }
                )
                
                // Translate Button
                if isTranslating {
                    loadingButton(
                        title: "Translating...",
                        color: AppConstants.Colors.purple
                    )
                } else {
                    actionButton(
                        icon: "globe",
                        iconColor: AppConstants.Colors.purple,
                        title: "Translate",
                        action: {
                            translateToLearningLanguage()
                        }
                    )
                }
                
                // Context Button
                if isLoadingContext {
                    loadingButton(
                        title: "Loading...",
                        color: AppConstants.Colors.teal
                    )
                } else {
                    actionButton(
                        icon: "text.bubble",
                        iconColor: AppConstants.Colors.teal,
                        title: "Context",
                        action: {
                            fetchContext()
                        }
                    )
                }
                
                // Close Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(AppConstants.Colors.surface)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppConstants.Colors.border.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .alert("Translation Failed", isPresented: $showingUnsupportedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if learningLanguageCode == nil {
                Text("Please set your Learning Language in Account settings to use translation.")
            } else {
                Text("Translation failed. Please try again later.")
            }
        }
        .alert("Context Failed", isPresented: $showingContextError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(contextErrorMessage)
        }
        .sheet(isPresented: $showingTranslation) {
            TranslationResultView(
                originalText: messageText,
                translatedText: translatedText,
                onDismiss: {
                    showingTranslation = false
                    onDismiss()
                }
            )
        }
        .sheet(isPresented: $showingContext) {
            ContextResultView(
                originalText: messageText,
                contextText: contextText,
                onDismiss: {
                    showingContext = false
                    onDismiss()
                }
            )
        }
    }
    
    private func actionButton(
        icon: String,
        iconColor: Color,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(1.0))
                        .frame(width: 24, height: 24)
                    
                    // Dark overlay for contrast
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.Colors.textPrimary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppConstants.Colors.surface)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func loadingButton(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(1.0))
                    .frame(width: 24, height: 24)
                
                // Dark overlay for contrast
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 24, height: 24)
                
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.white)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppConstants.Colors.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppConstants.Colors.surface)
        )
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = messageText
        
        // Show feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copyFeedback = true
        }
        
        // Reset feedback after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                copyFeedback = false
            }
        }
        
        // Auto-dismiss after copying
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onDismiss()
        }
    }
    
    private func translateToLearningLanguage() {
        // Get the user's learning language or default to English
        guard let languageCode = learningLanguageCode,
              let targetLanguage = TranslationLanguage(rawValue: languageCode) else {
            // If no learning language is set, show an error
            showingUnsupportedAlert = true
            return
        }
        
        translateTo(targetLanguage)
    }
    
    private func translateTo(_ language: TranslationLanguage) {
        isTranslating = true
        Task { @MainActor in
            do {
                let service = FirebaseAIService()
                let result = try await service.translateText(text: messageText, targetLanguage: language.rawValue)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTranslating = false
                }
                // Pass the translation result to parent
                onTranslationComplete(result.translatedText, language.displayName)
                // Auto-dismiss toolbar after showing translation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            } catch {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTranslating = false
                }
                showingUnsupportedAlert = true
            }
        }
    }
    
    private func fetchContext() {
        isLoadingContext = true
        
        Task { @MainActor in
            do {
                let service = FirebaseAIService()
                let history = conversationHistory ?? []
                let analysis = try await service.getMessageContext(selectedMessage: messageText, conversationHistory: history)
                
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isLoadingContext = false
                }
                
                // Check if the analysis is empty
                if analysis.isEmpty {
                    contextErrorMessage = "No context could be generated. Please try again."
                    showingContextError = true
                    return
                }
                
                // Pass the context result to parent
                onContextComplete(analysis)
                
                // Auto-dismiss toolbar after showing context
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            } catch {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isLoadingContext = false
                }
                contextErrorMessage = "Failed to fetch context: \(error.localizedDescription)"
                showingContextError = true
            }
        }
    }
}

// MARK: - Translation Result View
struct TranslationResultView: View {
    let originalText: String
    let translatedText: String
    let onDismiss: () -> Void
    @State private var copyFeedback = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Original Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        Text(originalText)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppConstants.Colors.surface)
                            )
                    }
                    
                    // Translated Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        HStack {
                            Text(translatedText)
                                .font(.body)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = translatedText
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    copyFeedback = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        copyFeedback = false
                                    }
                                }
                            }) {
                                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 16))
                                    .foregroundColor(copyFeedback ? AppConstants.Colors.brightGreen : AppConstants.Colors.accent)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppConstants.Colors.messageIncoming)
                        )
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .background(AppConstants.Colors.background)
        }
    }
}

// MARK: - Context Result View
struct ContextResultView: View {
    let originalText: String
    let contextText: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Message")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        Text(originalText)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppConstants.Colors.surface)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        Text(contextText)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppConstants.Colors.messageIncoming)
                            )
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .background(AppConstants.Colors.background)
        }
    }
}

// MARK: - Fallback Toolbar for iOS < 18.0
struct MessageActionsToolbarFallback: View {
    let messageText: String
    let onDismiss: () -> Void
    @State private var copyFeedback = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main action buttons
            HStack(spacing: 4) {
                // Copy Button
                Button(action: {
                    copyToClipboard()
                }) {
                    HStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(copyFeedback ? AppConstants.Colors.brightGreen.opacity(1.0) : AppConstants.Colors.accent.opacity(1.0))
                                .frame(width: 24, height: 24)
                            
                            // Dark overlay for contrast
                            Circle()
                                .fill(.black.opacity(0.5))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Text(copyFeedback ? "Copied!" : "Copy")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppConstants.Colors.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppConstants.Colors.surface)
                    )
                }
                .buttonStyle(.plain)
                
                // Translation not available badge
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.system(size: 11))
                        .foregroundColor(AppConstants.Colors.textTertiary)
                    
                    Text("iOS 18+ Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppConstants.Colors.textTertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppConstants.Colors.surface.opacity(0.5))
                )
                
                // Close Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(AppConstants.Colors.surface)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppConstants.Colors.border.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = messageText
        
        // Show feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copyFeedback = true
        }
        
        // Reset feedback after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                copyFeedback = false
            }
        }
        
        // Auto-dismiss after copying
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onDismiss()
        }
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                MessageActionsToolbar(
                    messageText: "Hello, how are you doing today?",
                    conversationHistory: nil,
                    learningLanguageCode: "es",
                    onDismiss: {},
                    onTranslationComplete: { _, _ in },
                    onContextComplete: { _ in }
                )
                .padding()
            }
        }
    } else {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                MessageActionsToolbarFallback(
                    messageText: "Hello, how are you doing today?",
                    onDismiss: {}
                )
                .padding()
            }
        }
    }
}

