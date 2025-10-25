//
//  GlassTooltip.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct GlassTooltip: View {
    let isPresented: Binding<Bool>
    let onNewChat: () -> Void
    let onNewGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Menu Items
            VStack(spacing: 0) {
                // New Chat
                menuItem(
                    icon: "square.and.pencil",
                    iconColor: AppConstants.Colors.accent,
                    title: "New Chat",
                    subtitle: "Start a 1-on-1 conversation",
                    action: {
                        onNewChat()
                        isPresented.wrappedValue = false
                    }
                )
                
                Divider()
                    .background(AppConstants.Colors.border)
                
                // New Group
                menuItem(
                    icon: "person.3",
                    iconColor: AppConstants.Colors.purple,
                    title: "New Group",
                    subtitle: "Create a multi-member conversation",
                    action: {
                        onNewGroup()
                        isPresented.wrappedValue = false
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppConstants.Colors.border.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
    
    private func menuItem(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(1.0))
                        .frame(width: 36, height: 36)
                    
                    // Dark overlay for contrast
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                GlassTooltip(
                    isPresented: .constant(true),
                    onNewChat: { print("New Chat") },
                    onNewGroup: { print("New Group") }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
    }
}
