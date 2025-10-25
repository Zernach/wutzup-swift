//
//  ResearchView.swift
//  Wutzup
//
//  Modal view for conducting research with AI
//

import SwiftUI

struct ResearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String = ""
    @State private var isResearching: Bool = false
    
    let onResearch: (String) async -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(AppConstants.Colors.accent)
                    }
                    
                    Text("Conduct Research")
                        .font(.title2.bold())
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text("Ask a question and get AI-powered research results")
                        .font(.subheadline)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)
                
                // Prompt Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Question")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppConstants.Colors.textSecondary)
                    
                    TextField("e.g., What are the latest developments in renewable energy?", text: $prompt, axis: .vertical)
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
                }
                .padding(.horizontal)
                
                // Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppConstants.Colors.accent)
                        Text("How it works")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppConstants.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "globe", text: "Searches the web for information")
                        InfoRow(icon: "sparkles", text: "AI summarizes the findings")
                        InfoRow(icon: "clock", text: "Takes about 10-15 seconds")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Research Button
                Button(action: {
                    Task {
                        isResearching = true
                        await onResearch(prompt)
                        isResearching = false
                        dismiss()
                    }
                }) {
                    HStack(spacing: 12) {
                        if isResearching {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "magnifyingglass")
                            Text("Conduct Research")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(prompt.isEmpty ? AppConstants.Colors.mutedIcon : AppConstants.Colors.accent)
                    )
                }
                .disabled(prompt.isEmpty || isResearching)
                .padding(.horizontal)
                .padding(.bottom, 32)
                }
                .background(AppConstants.Colors.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.Colors.textSecondary)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    ResearchView { prompt in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

