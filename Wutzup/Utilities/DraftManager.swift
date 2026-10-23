import Foundation

/// An instance is bound to the account that opened its view. Late view teardown
/// cannot save a previous account's text into the next account's preferences.
final class DraftManager {
    private let userDefaults: UserDefaults
    private let draftsKey: String?

    init(userID: String?, defaults: UserDefaults = .standard) {
        userDefaults = defaults
        draftsKey = userID.map { "wutzup.messageDrafts.v2." + $0 }
    }

    func saveDraft(_ text: String, for conversationId: String) {
        guard let draftsKey else { return }
        var drafts = loadAllDrafts()
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drafts.removeValue(forKey: conversationId)
        } else { drafts[conversationId] = text }
        userDefaults.set(drafts, forKey: draftsKey)
    }

    func loadDraft(for conversationId: String) -> String? { loadAllDrafts()[conversationId] }
    func removeDraft(for conversationId: String) { saveDraft("", for: conversationId) }
    func removeAllDrafts() {
        if let draftsKey { userDefaults.removeObject(forKey: draftsKey) }
    }
    func conversationIdsWithDrafts() -> [String] { Array(loadAllDrafts().keys) }
    private func loadAllDrafts() -> [String: String] {
        guard let draftsKey else { return [:] }
        return userDefaults.dictionary(forKey: draftsKey) as? [String: String] ?? [:]
    }
}
