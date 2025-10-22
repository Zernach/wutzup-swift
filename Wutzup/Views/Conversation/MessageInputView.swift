//
//  MessageInputView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

// Preference key to communicate the height of the input view
struct MessageInputHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: (String) -> Void
    let onTextChanged: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
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
                .focused($isTextFieldFocused)
                .onChange(of: text) {
                    onTextChanged()
                }
            
            // Send Button
            Button(action: {
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedText.isEmpty {
                    isTextFieldFocused = false
                    text = ""
                    onSend(trimmedText)
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
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        print("📏 [MessageInputView] Initial geometry: \(geometry.size)")
                    }
                    .preference(
                        key: MessageInputHeightKey.self,
                        value: geometry.size.height
                    )
            }
        )
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isSending: false,
            onSend: { _ in },
            onTextChanged: {}
        )
    }
}
