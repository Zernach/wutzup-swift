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
        static let primaryBlue = Color.blue
        static let messageBackground = Color(UIColor.systemGray6)
        static let myMessageBackground = Color.blue
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
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

