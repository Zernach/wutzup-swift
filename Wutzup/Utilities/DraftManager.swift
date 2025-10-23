//
//  DraftManager.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

/// Manages persistent storage of draft messages for conversations
final class DraftManager {
    static let shared = DraftManager()
    
    private let userDefaults = UserDefaults.standard
    private let draftsKey = "wutzup_message_drafts"
    
    private init() {}
    
    /// Save a draft message for a conversation
    /// - Parameters:
    ///   - text: The draft message text
    ///   - conversationId: The ID of the conversation
    func saveDraft(_ text: String, for conversationId: String) {
        var drafts = loadAllDrafts()
        
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // If text is empty, remove the draft
            drafts.removeValue(forKey: conversationId)
        } else {
            // Save non-empty draft
            drafts[conversationId] = text
        }
        
        userDefaults.set(drafts, forKey: draftsKey)
        
        #if DEBUG
        #endif
    }
    
    /// Load a draft message for a conversation
    /// - Parameter conversationId: The ID of the conversation
    /// - Returns: The draft text, or nil if no draft exists
    func loadDraft(for conversationId: String) -> String? {
        let drafts = loadAllDrafts()
        let draft = drafts[conversationId]
        
        #if DEBUG
        if let draft = draft {
        }
        #endif
        
        return draft
    }
    
    /// Remove a draft message for a conversation
    /// - Parameter conversationId: The ID of the conversation
    func removeDraft(for conversationId: String) {
        var drafts = loadAllDrafts()
        drafts.removeValue(forKey: conversationId)
        userDefaults.set(drafts, forKey: draftsKey)
        
        #if DEBUG
        #endif
    }
    
    /// Remove all draft messages (useful for cleanup)
    func removeAllDrafts() {
        userDefaults.removeObject(forKey: draftsKey)
        
        #if DEBUG
        #endif
    }
    
    /// Get all conversation IDs that have drafts
    func conversationIdsWithDrafts() -> [String] {
        Array(loadAllDrafts().keys)
    }
    
    // MARK: - Private Helpers
    
    private func loadAllDrafts() -> [String: String] {
        userDefaults.dictionary(forKey: draftsKey) as? [String: String] ?? [:]
    }
}

