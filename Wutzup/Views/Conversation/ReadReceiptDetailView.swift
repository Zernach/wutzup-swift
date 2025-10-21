//
//  ReadReceiptDetailView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct ReadReceiptDetailView: View {
    let message: Message
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Message Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        Text(message.content)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppConstants.Colors.messageIncoming)
                            .cornerRadius(12)
                    }
                    
                    // Read by section
                    if !message.readBy.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppConstants.Colors.accent)
                                Text("Read by \(message.readBy.count)")
                                    .font(.headline)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                            }
                            
                            ForEach(message.readBy, id: \.self) { userId in
                                if let userName = conversation.participantNames[userId] {
                                    HStack {
                                        Circle()
                                            .fill(AppConstants.Colors.accent.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(userName.prefix(1).uppercased())
                                                    .font(.caption)
                                                    .foregroundColor(AppConstants.Colors.accent)
                                            )
                                        
                                        Text(userName)
                                            .font(.body)
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppConstants.Colors.accent)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Delivered to section (but not read)
                    let deliveredOnly = message.deliveredTo.filter { !message.readBy.contains($0) }
                    if !deliveredOnly.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                Text("Delivered to \(deliveredOnly.count)")
                                    .font(.headline)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                            }
                            
                            ForEach(deliveredOnly, id: \.self) { userId in
                                if let userName = conversation.participantNames[userId] {
                                    HStack {
                                        Circle()
                                            .fill(AppConstants.Colors.textSecondary.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(userName.prefix(1).uppercased())
                                                    .font(.caption)
                                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                            )
                                        
                                        Text(userName)
                                            .font(.body)
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(AppConstants.Colors.textSecondary)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Not delivered section
                    let notDelivered = conversation.participantIds.filter {
                        !message.deliveredTo.contains($0) && $0 != message.senderId
                    }
                    if !notDelivered.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(AppConstants.Colors.textTertiary)
                                Text("Not delivered to \(notDelivered.count)")
                                    .font(.headline)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                            }
                            
                            ForEach(notDelivered, id: \.self) { userId in
                                if let userName = conversation.participantNames[userId] {
                                    HStack {
                                        Circle()
                                            .fill(AppConstants.Colors.textTertiary.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(userName.prefix(1).uppercased())
                                                    .font(.caption)
                                                    .foregroundColor(AppConstants.Colors.textTertiary)
                                            )
                                        
                                        Text(userName)
                                            .font(.body)
                                            .foregroundColor(AppConstants.Colors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "circle")
                                            .foregroundColor(AppConstants.Colors.textTertiary)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Timestamp
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sent")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                        
                        Text(message.timestamp, style: .date)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        + Text(" at ")
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        + Text(message.timestamp, style: .time)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                    }
                }
                .padding()
            }
            .navigationTitle("Message Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(AppConstants.Colors.background)
        }
    }
}

#Preview("Group Message - Partially Read") {
    ReadReceiptDetailView(
        message: Message(
            conversationId: "conv1",
            senderId: "user1",
            senderName: "Alice",
            content: "Hey everyone! How's it going?",
            timestamp: Date().addingTimeInterval(-3600),
            status: .delivered,
            readBy: ["user1", "user2"],
            deliveredTo: ["user1", "user2", "user3"],
            isFromCurrentUser: true
        ),
        conversation: Conversation(
            participantIds: ["user1", "user2", "user3", "user4"],
            participantNames: [
                "user1": "Alice",
                "user2": "Bob",
                "user3": "Charlie",
                "user4": "Diana"
            ],
            isGroup: true,
            groupName: "Team Chat"
        )
    )
}

#Preview("Group Message - All Read") {
    ReadReceiptDetailView(
        message: Message(
            conversationId: "conv1",
            senderId: "user1",
            senderName: "Alice",
            content: "Important announcement!",
            timestamp: Date().addingTimeInterval(-7200),
            status: .read,
            readBy: ["user1", "user2", "user3", "user4"],
            deliveredTo: ["user1", "user2", "user3", "user4"],
            isFromCurrentUser: true
        ),
        conversation: Conversation(
            participantIds: ["user1", "user2", "user3", "user4"],
            participantNames: [
                "user1": "Alice",
                "user2": "Bob",
                "user3": "Charlie",
                "user4": "Diana"
            ],
            isGroup: true,
            groupName: "Team Chat"
        )
    )
}

