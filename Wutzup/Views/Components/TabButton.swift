//
//  TabButton.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSelected ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? AppConstants.Colors.accent.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
