//
//  DateFormatter+Helpers.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

extension DateFormatter {
    static let messageTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let messageDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let lastSeen: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return DateFormatter.messageTime.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: self, to: now)
            if let days = components.day, days < 7 {
                return "\(days) days ago"
            } else {
                return DateFormatter.messageDate.string(from: self)
            }
        }
    }
}

