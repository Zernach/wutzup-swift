//
//  MessageInputView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: () -> Void
    let onTextChanged: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Text Input
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AppConstants.Colors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppConstants.Colors.border, lineWidth: 1)
                )
                .cornerRadius(20)
                .foregroundColor(AppConstants.Colors.textPrimary)
                .tint(AppConstants.Colors.accent)
                .lineLimit(1...5)
                .onChange(of: text) {
                    onTextChanged()
                }
            
            // Send Button
            Button(action: {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSend()
                }
            }) {
                if isSending {
                    ProgressView()
                        .tint(AppConstants.Colors.textPrimary)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? AppConstants.Colors.mutedIcon
                                : AppConstants.Colors.accent
                        )
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(AppConstants.Colors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppConstants.Colors.border),
            alignment: .top
        )
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isSending: false,
            onSend: {},
            onTextChanged: {}
        )
    }
}
