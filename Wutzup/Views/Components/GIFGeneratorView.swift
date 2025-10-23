//
//  GIFGeneratorView.swift
//  Wutzup
//
//  Modal view for generating GIFs with DALL-E
//

import SwiftUI
import Combine

struct GIFGeneratorView: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppConstants.Colors.accent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: viewModel.generatedGIFURL != nil ? "checkmark.circle.fill" : "photo.stack")
                                .font(.system(size: 36))
                                .foregroundColor(AppConstants.Colors.accent)
                        }
                        
                        Text(viewModel.generatedGIFURL != nil ? "GIF Generated!" : "Generate GIF")
                            .font(.title2.bold())
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        if viewModel.generatedGIFURL == nil {
                            Text("Describe the animated GIF you'd like to create")
                                .font(.subheadline)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Prompt Input (always visible)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Prompt")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        TextField("e.g., a cat dancing under disco lights", text: $prompt, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(AppConstants.Colors.surfaceSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppConstants.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .tint(AppConstants.Colors.accent)
                            .lineLimit(3...6)
                            .disabled(viewModel.isGeneratingGIF || viewModel.generatedGIFURL != nil)
                    }
                    .padding(.horizontal)
                    
                    // GIF Preview (when available)
                    if let gifURL = viewModel.generatedGIFURL {
                        VStack(spacing: 8) {
                            Text("Preview")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            
                            // Use AnimatedImageView for GIF preview (supports animation)
                            AnimatedImageView(
                                url: URL(string: gifURL),
                                cornerRadius: 12
                            )
                        }
                        .padding(.horizontal)
                    } else {
                        // Info Card (only when no GIF generated)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppConstants.Colors.accent)
                                Text("How it works")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(icon: "sparkles", text: "AI generates a unique image")
                                InfoRow(icon: "film", text: "Converted to GIF format")
                                InfoRow(icon: "clock", text: "Takes about 5-10 seconds")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    if viewModel.generatedGIFURL != nil {
                        // Send and Regenerate buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    await viewModel.approveAndSendGIF()
                                    dismiss()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send GIF")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppConstants.Colors.accent)
                                )
                            }
                            
                            Button(action: {
                                viewModel.rejectGIF()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Try Again")
                                        .font(.headline)
                                }
                                .foregroundColor(AppConstants.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppConstants.Colors.surfaceSecondary)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    } else {
                        // Generate button
                        Button(action: {
                            Task {
                                await viewModel.generateGIF(prompt: prompt)
                            }
                        }) {
                            HStack(spacing: 12) {
                                if viewModel.isGeneratingGIF {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Generating...")
                                        .font(.headline)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate GIF")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(prompt.isEmpty || viewModel.isGeneratingGIF ? AppConstants.Colors.mutedIcon : AppConstants.Colors.accent)
                            )
                        }
                        .disabled(prompt.isEmpty || viewModel.isGeneratingGIF)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
                .background(AppConstants.Colors.background)
                
                // Loading Overlay with message
                if viewModel.isGeneratingGIF {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppConstants.Colors.accent)
                            
                            Text("Generating GIF...")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Text("This may take 5-10 seconds")
                                .font(.subheadline)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelGIFGenerator()
                        dismiss()
                    }
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .disabled(viewModel.isGeneratingGIF)
                }
            }
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.accent)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppConstants.Colors.textSecondary)
        }
    }
}

#Preview {
    let previewService = PreviewMessageService()
    let previewPresence = PreviewPresenceService()
    let previewAuth = PreviewAuthenticationService()
    let viewModel = ConversationViewModel(
        conversation: Conversation(
            participantIds: ["1", "2"],
            participantNames: ["1": "Alice", "2": "Bob"],
            isGroup: false
        ),
        messageService: previewService,
        presenceService: previewPresence,
        authService: previewAuth
    )
    
    return GIFGeneratorView(viewModel: viewModel)
}

// Preview services for GIFGeneratorView
private final class PreviewMessageService: MessageService {
    func fetchMessages(conversationId: String, limit: Int) async throws -> [Message] { [] }
    func observeMessages(conversationId: String) -> AsyncStream<Message> {
        AsyncStream { continuation in continuation.finish() }
    }
    func sendMessage(conversationId: String, content: String, mediaUrl: String?, mediaType: String?, messageId: String?) async throws -> Message {
        Message(
            id: messageId ?? UUID().uuidString,
            conversationId: conversationId,
            senderId: "1",
            senderName: "Alice",
            content: content,
            timestamp: Date(),
            status: .sent,
            isFromCurrentUser: true
        )
    }
    func markAsRead(conversationId: String, messageId: String, userId: String) async throws { }
    func markAsDelivered(conversationId: String, messageId: String, userId: String) async throws { }
    func batchMarkAsRead(conversationId: String, messageIds: [String], userId: String) async throws { }
    func batchMarkAsDelivered(conversationId: String, messageIds: [String], userId: String) async throws { }
}

private final class PreviewPresenceService: PresenceService {
    func setOnline(userId: String) async throws { }
    func setOffline(userId: String) async throws { }
    func setAway(userId: String) async throws { }
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in continuation.finish() }
    }
    func setTyping(userId: String, conversationId: String, isTyping: Bool) async throws { }
    func observeTyping(conversationId: String) -> AsyncStream<[String : Bool]> {
        AsyncStream { continuation in continuation.finish() }
    }
}

private final class PreviewAuthenticationService: AuthenticationService {
    var authStatePublisher: AnyPublisher<User?, Never> {
        Just(User(id: "1", email: "alice@wutzup.app", displayName: "Alice")).eraseToAnyPublisher()
    }
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
    var currentUser: User? {
        User(id: "1", email: "alice@wutzup.app", displayName: "Alice")
    }
    func register(email: String, password: String, displayName: String) async throws -> User { currentUser! }
    func login(email: String, password: String) async throws -> User { currentUser! }
    func logout() async throws { }
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws { }
    func deleteAccount() async throws { }
}

