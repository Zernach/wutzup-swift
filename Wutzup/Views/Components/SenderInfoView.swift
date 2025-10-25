//
//  SenderInfoView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct SenderInfoView: View {
    let senderName: String?
    let senderUser: User?
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Display name
            if let displayName = senderName ?? senderUser?.displayName {
                Text(displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppConstants.Colors.textPrimary)
            }
            
            // Username (email)
            if let username = senderUser?.email {
                Text("@\(username.components(separatedBy: "@").first ?? username)")
                    .font(.caption2)
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    SenderInfoView(
        senderName: "John Doe",
        senderUser: User(
            id: "1",
            email: "john.doe@example.com",
            displayName: "John Doe"
        ),
        message: Message(
            conversationId: "test",
            senderId: "1",
            content: "Hello world"
        )
    )
    .padding()
}
