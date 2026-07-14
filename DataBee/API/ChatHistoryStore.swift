//
//  ChatHistoryStore.swift
//  DataBee
//

import Foundation

/// Local cache of the user's chat history.
/// Cached chats are available instantly on launch; `refresh()` fetches the
/// latest from the API in the background, overwrites the cache on disk and
/// posts `didUpdate` so open screens can reload.
final class ChatHistoryStore {

    static let shared = ChatHistoryStore()
    static let didUpdate = Notification.Name("ChatHistoryStore.didUpdate")

    /// Newest chat first.
    private(set) var chats: [ChatInfo] = []

    private var isRefreshing = false

    private init() {
        loadFromDisk()
    }

    private var cacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("chat_history.json")
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode([ChatInfo].self, from: data) else { return }
        chats = cached
    }

    /// Fetches the latest chats in the background and overwrites the local cache.
    /// Failures are silent — the cached copy keeps being shown.
    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        let userId = Session.shared.currentUser?.contactID ?? "1"
        Task {
            do {
                let latest = try await APIClient.shared.getChatMessages(userId: userId)
                let ordered = Array(latest.reversed())
                if let data = try? JSONEncoder().encode(ordered) {
                    try? data.write(to: cacheURL, options: .atomic)
                }
                await MainActor.run {
                    self.chats = ordered
                    self.isRefreshing = false
                    NotificationCenter.default.post(name: Self.didUpdate, object: nil)
                }
            } catch {
                print("Failed to refresh chat history: \(error.localizedDescription)")
                await MainActor.run { self.isRefreshing = false }
            }
        }
    }

    /// Removes the cache on logout so the next user never sees these chats.
    func clear() {
        chats = []
        try? FileManager.default.removeItem(at: cacheURL)
    }
}
