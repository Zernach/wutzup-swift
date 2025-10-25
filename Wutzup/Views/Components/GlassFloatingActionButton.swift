//
//  GlassFloatingActionButton.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct GlassFloatingActionButton: View {
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass morphism background
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppConstants.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 24))
                    .foregroundColor(AppConstants.Colors.accent)
                    .rotationEffect(.degrees(isExpanded ? 0 : 0))
            }
            .frame(width: 56, height: 56)
            .shadow(color: AppConstants.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 4)
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
                GlassFloatingActionButton(
                    isExpanded: false,
                    action: {
                        print("Button tapped")
                    }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
    }
}
