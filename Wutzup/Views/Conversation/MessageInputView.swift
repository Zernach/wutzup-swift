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
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
                .onChange(of: text) { _ in
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
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray
                                : .blue
                        )
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
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

