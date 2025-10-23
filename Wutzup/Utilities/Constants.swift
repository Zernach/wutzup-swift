//
//  Constants.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI

enum AppConstants {
    static let appName = "Wutzup"
    static let defaultProfileImage = "person.circle.fill"
    
    // Colors
    enum Colors {
        static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
        static let surface = Color(red: 0.11, green: 0.12, blue: 0.16)
        static let surfaceSecondary = Color(red: 0.15, green: 0.17, blue: 0.22)
        static let accent = Color(red: 0.31, green: 0.62, blue: 0.98)
        static let messageIncoming = Color(red: 0.18, green: 0.19, blue: 0.25)
        static let messageOutgoing = Color(red: 0.24, green: 0.49, blue: 0.92)
        static let messageResearch = Color(red: 0.52, green: 0.31, blue: 0.78) // Purple for research results
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        static let border = Color.white.opacity(0.08)
        static let destructive = Color.red.opacity(0.85)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3) // Bright red for errors/drafts
        static let mutedIcon = Color.white.opacity(0.65)
        static let brightGreen = Color(red: 0x72 / 255.0, green: 0xfa / 255.0, blue: 0x41 / 255.0) // #72fa41
        static let purple = Color(red: 0x88 / 255.0, green: 0x44 / 255.0, blue: 0xcc / 255.0) // #8844cc
        static let brightYellow = Color(red: 0xfb / 255.0, green: 0xff / 255.0, blue: 0x00 / 255.0) // #fbff00
    }
    
    // Sizes
    enum Sizes {
        static let profileImageSize: CGFloat = 40
        static let messageBubbleCornerRadius: CGFloat = 18
        static let inputBarHeight: CGFloat = 50
    }
    
    // Limits
    enum Limits {
        static let messageMaxLength = 1000
        static let groupNameMaxLength = 50
        static let messagesPerPage = 50
    }
}
