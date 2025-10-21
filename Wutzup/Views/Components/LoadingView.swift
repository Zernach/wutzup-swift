//
//  LoadingView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var messageIndex = 0
    
    private let welcomeMessages = [
        "Welcome back! 👋",
        "Getting things ready...",
        "Just a moment...",
        "Loading your chats..."
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppConstants.Colors.background,
                    AppConstants.Colors.background.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated logo/icon area
                ZStack {
                    // Pulsing circles
                    Circle()
                        .fill(AppConstants.Colors.accent.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Circle()
                        .fill(AppConstants.Colors.accent.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.8)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Center icon
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.accent)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                .linear(duration: 3)
                                .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 20)
                
                // App name
                VStack(spacing: 8) {
                    Text("Wutzup")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.textPrimary)
                    
                    Text(welcomeMessages[messageIndex])
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .animation(.easeInOut, value: messageIndex)
                }
                
                // Loading indicator
                ProgressView()
                    .tint(AppConstants.Colors.accent)
                    .scaleEffect(1.2)
                    .padding(.top, 20)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            startMessageRotation()
        }
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                messageIndex = (messageIndex + 1) % welcomeMessages.count
            }
        }
    }
}

#Preview {
    LoadingView()
}

