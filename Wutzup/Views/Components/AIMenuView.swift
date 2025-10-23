//
//  AIMenuView.swift
//  Wutzup
//
//  AI Actions Menu with glass morphism effect
//

import SwiftUI

struct AIMenuView: View {
    @Binding var isExpanded: Bool
    let isGeneratingCoreML: Bool
    let isGeneratingAI: Bool
    let onConciseReplies: () -> Void
    let onThoughtfulReplies: () -> Void
    let onConductResearch: () -> Void
    let onGenerateGIF: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Menu Items
                VStack(spacing: 0) {
                    // Concise Reply (CoreML)
                    menuItem(
                        icon: "sparkles",
                        iconColor: AppConstants.Colors.brightGreen,
                        title: "Concise Reply",
                        subtitle: "Fast, on-device",
                        isLoading: isGeneratingCoreML,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                            onConciseReplies()
                        }
                    )
                    
                    Divider()
                        .background(AppConstants.Colors.border)
                    
                    // Thoughtful Reply (OpenAI)
                    menuItem(
                        icon: "sparkles",
                        iconColor: AppConstants.Colors.accent,
                        title: "Thoughtful Reply",
                        subtitle: "Detailed, contextual",
                        isLoading: isGeneratingAI,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                            onThoughtfulReplies()
                        }
                    )
                    
                    Divider()
                        .background(AppConstants.Colors.border)
                    
                    // Conduct Research
                    menuItem(
                        icon: "magnifyingglass",
                        iconColor: AppConstants.Colors.purple,
                        title: "Conduct Research",
                        subtitle: "Web search & analysis",
                        isLoading: false,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                            onConductResearch()
                        }
                    )
                    
                    Divider()
                        .background(AppConstants.Colors.border)
                    
                    // Generate GIF
                    menuItem(
                        icon: "photo.stack",
                        iconColor: AppConstants.Colors.brightYellow,
                        title: "Generate GIF",
                        subtitle: "Create animated image",
                        isLoading: false,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                            onGenerateGIF()
                        }
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppConstants.Colors.border.opacity(0.5), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.bottom, 8)
                .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
            }
            
            // Main AI Button (Blue Sparkles)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    // Glass morphism background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppConstants.Colors.accent.opacity(0.3), lineWidth: 1)
                        )
                    
                    if isGeneratingAI || isGeneratingCoreML {
                        ProgressView()
                            .tint(AppConstants.Colors.accent)
                    } else {
                        Image(systemName: isExpanded ? "xmark" : "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(AppConstants.Colors.accent)
                            .rotationEffect(.degrees(isExpanded ? 0 : 0))
                    }
                }
                .frame(width: 56, height: 56)
                .shadow(color: AppConstants.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
    }
    
    private func menuItem(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    if isLoading {
                        ProgressView()
                            .tint(iconColor)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    ZStack {
        AppConstants.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                AIMenuView(
                    isExpanded: .constant(true),
                    isGeneratingCoreML: false,
                    isGeneratingAI: false,
                    onConciseReplies: {},
                    onThoughtfulReplies: {},
                    onConductResearch: {},
                    onGenerateGIF: {}
                )
                .padding(.leading, 16)
                .padding(.bottom, 76)
                
                Spacer()
            }
        }
    }
}

