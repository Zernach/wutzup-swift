//
//  GIFGeneratorView.swift
//  Wutzup
//
//  Modal view for generating GIFs with DALL-E
//

import SwiftUI

struct GIFGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String = ""
    @State private var isGenerating: Bool = false
    
    let onGenerate: (String) async -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "photo.stack")
                            .font(.system(size: 36))
                            .foregroundColor(AppConstants.Colors.accent)
                    }
                    
                    Text("Generate GIF")
                        .font(.title2.bold())
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text("Describe the animated GIF you'd like to create")
                        .font(.subheadline)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)
                
                // Prompt Input
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
                
                Spacer()
                
                // Generate Button
                Button(action: {
                    Task {
                        isGenerating = true
                        await onGenerate(prompt)
                        isGenerating = false
                        dismiss()
                    }
                }) {
                    HStack(spacing: 12) {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
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
                            .fill(prompt.isEmpty ? AppConstants.Colors.mutedIcon : AppConstants.Colors.accent)
                    )
                }
                .disabled(prompt.isEmpty || isGenerating)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(AppConstants.Colors.background)
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
    GIFGeneratorView { prompt in
        print("Generating GIF: \(prompt)")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

