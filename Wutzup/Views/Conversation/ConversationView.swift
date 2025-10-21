//
//  ConversationView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ConversationViewModel
    @State private var scrollProxy: ScrollViewProxy?
    
    let conversation: Conversation
    
    init(conversation: Conversation) {
        self.conversation = conversation
        
        let appState = AppState()
        _viewModel = StateObject(wrappedValue: ConversationViewModel(
            conversation: conversation,
            messageService: appState.messageService,
            presenceService: appState.presenceService,
            authService: appState.authService
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // Typing Indicator
                        if let typingText = viewModel.typingIndicatorText {
                            HStack {
                                Text(typingText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom()
                }
            }
            
            // Message Input
            MessageInputView(
                text: $viewModel.messageText,
                isSending: viewModel.isSending,
                onSend: {
                    Task {
                        await viewModel.sendMessage()
                        scrollToBottom()
                    }
                },
                onTextChanged: {
                    viewModel.onTypingChanged()
                }
            )
        }
        .navigationTitle(conversation.displayName(currentUserId: appState.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchMessages()
                viewModel.startObserving()
            }
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = viewModel.messages.last else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConversationView(conversation: Conversation(
            participantIds: ["1", "2"],
            participantNames: ["1": "Alice", "2": "Bob"]
        ))
        .environmentObject(AppState())
    }
}

