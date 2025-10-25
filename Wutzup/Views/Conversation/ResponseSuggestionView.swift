//
//  ResponseSuggestionView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct ResponseSuggestionView: View {
    let suggestion: AIResponseSuggestion?
    let isLoading: Bool
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header - Always Visible
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(AppConstants.Colors.accent)
                        
                        Text("AI Suggestions")
                            .font(.title2.bold())
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        if !isLoading {
                            Text("Choose a response or edit before sending")
                                .font(.body)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    if isLoading {
                        // Loading State
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppConstants.Colors.accent)
                            
                            Text("Generating AI Replies...")
                                .font(.headline)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            Text("AI is analyzing the conversation")
                                .font(.subheadline)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                        .padding(.top, 40) 
                    } else if let suggestion = suggestion {
                        // Positive Response
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "hand.thumbsup.fill")
                                    .foregroundColor(AppConstants.Colors.brightGreen)
                                Text("Positive Response")
                                    .font(.headline)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                                Spacer()
                            }
                            
                            Text(suggestion.positiveResponse)
                                .font(.body)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppConstants.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppConstants.Colors.brightGreen.opacity(0.3), lineWidth: 2)
                                )
                                .cornerRadius(12)
                            
                            Button(action: {
                                onSelect(suggestion.positiveResponse)
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Use Positive Response")
                                }
                                .font(.body.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppConstants.Colors.brightGreen)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Negative Response
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .foregroundColor(.red)
                                Text("Negative Response")
                                    .font(.headline)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                                Spacer()
                            }
                            
                            Text(suggestion.negativeResponse)
                                .font(.body)
                                .foregroundColor(AppConstants.Colors.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppConstants.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                )
                                .cornerRadius(12)
                            
                            Button(action: {
                                onSelect(suggestion.negativeResponse)
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Use Negative Response")
                                }
                                .font(.body.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                }
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ResponseSuggestionView(
        suggestion: AIResponseSuggestion(
            positiveResponse: "That sounds great! I'd love to join you for coffee tomorrow. What time works best for you?",
            negativeResponse: "Thanks for the invite, but I'm pretty swamped this week. Maybe we can catch up another time?"
        ),
        isLoading: false,
        onSelect: { _ in },
        onDismiss: {}
    )
}

