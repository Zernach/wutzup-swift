//
//  AttachmentMenuView.swift
//  Wutzup
//
//  Expandable attachment menu with glass morphism effect
//

import SwiftUI

struct AttachmentMenuView: View {
    @Binding var isExpanded: Bool
    let onGenerateGIF: () -> Void
    let onConductResearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if isExpanded {
                // Conduct Research Button
                Button(action: {
                    onConductResearch()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                        Text("Conduct Research")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(AppConstants.Colors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppConstants.Colors.accent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .transition(.scale.combined(with: .opacity))
                
                // Generate GIF Button
                Button(action: {
                    onGenerateGIF()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 16))
                        Text("Generate GIF")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(AppConstants.Colors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppConstants.Colors.accent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Plus Button (Always Visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppConstants.Colors.border, lineWidth: 1)
                        )
                    
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppConstants.Colors.accent)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .frame(width: 36, height: 36)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        HStack {
            AttachmentMenuView(
                isExpanded: .constant(false),
                onGenerateGIF: {},
                onConductResearch: {}
            )
            Spacer()
        }
        .padding()
        .background(AppConstants.Colors.surface)
    }
    .background(AppConstants.Colors.background)
}

