//
//  ChatConversationStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import Foundation

struct ChatMessageRecord: Codable, Equatable {
    let text: String
    let isIncoming: Bool
}

struct ChatConversationRecord: Codable, Equatable {
    let peerName: String
    let avatarImageName: String?
    let lastMessage: String
    let updatedAt: Date
}

extension Notification.Name {
    static let chatConversationsDidChange = Notification.Name("skmusic.chatConversationsDidChange")
}

final class ChatConversationStore {
    static let shared = ChatConversationStore()

    private static let messagesStorageKeyPrefix = "friend_chat_messages"
    private let conversationsStorageKeyPrefix = "skmusic.chat_conversations"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func allConversations() -> [ChatConversationRecord] {
        guard
            let data = defaults.data(forKey: conversationsStorageKey()),
            let conversations = try? JSONDecoder().decode([ChatConversationRecord].self, from: data)
        else {
            return []
        }

        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    func loadMessages(for peerName: String) -> [ChatMessageRecord] {
        guard
            let data = defaults.data(forKey: Self.messagesStorageKey(for: peerName)),
            let messages = try? JSONDecoder().decode([ChatMessageRecord].self, from: data)
        else {
            return []
        }

        return messages
    }

    func saveMessages(_ messages: [ChatMessageRecord], for peerName: String, avatarImageName: String) {
        guard FriendStore.shared.isFriend(name: peerName) else { return }

        guard let data = try? JSONEncoder().encode(messages) else { return }
        defaults.set(data, forKey: Self.messagesStorageKey(for: peerName))

        guard let lastMessage = messages.last else { return }
        upsertConversation(peerName: peerName, avatarImageName: avatarImageName, lastMessage: lastMessage.text)
    }

    static func normalizedPeerName(_ peerName: String) -> String {
        let trimmedName = peerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Angela" : trimmedName
    }

    private func upsertConversation(peerName: String, avatarImageName: String, lastMessage: String) {
        let normalizedPeerName = Self.normalizedPeerName(peerName)
        let record = ChatConversationRecord(
            peerName: normalizedPeerName,
            avatarImageName: normalizedAvatarImageName(avatarImageName),
            lastMessage: lastMessage,
            updatedAt: Date()
        )
        var conversations = allConversations().filter { $0.peerName != normalizedPeerName }
        conversations.insert(record, at: 0)

        if let data = try? JSONEncoder().encode(conversations) {
            defaults.set(data, forKey: conversationsStorageKey())
        }

        NotificationCenter.default.post(name: .chatConversationsDidChange, object: nil)
    }

    private func conversationsStorageKey() -> String {
        [
            conversationsStorageKeyPrefix,
            Self.storageSafeComponent(AuthSession.currentEmail ?? "guest")
        ].joined(separator: "_")
    }

    private func normalizedAvatarImageName(_ avatarImageName: String) -> String {
        let trimmedName = avatarImageName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "message_avatar" : trimmedName
    }

    private static func messagesStorageKey(for peerName: String) -> String {
        [
            messagesStorageKeyPrefix,
            storageSafeComponent(AuthSession.currentEmail ?? "guest"),
            storageSafeComponent(normalizedPeerName(peerName))
        ].joined(separator: "_")
    }

    private static func storageSafeComponent(_ text: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let normalized = text.lowercased().unicodeScalars.map { scalar -> Character in
            allowedCharacters.contains(scalar) ? Character(scalar) : "_"
        }
        let value = String(normalized).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return value.isEmpty ? "unknown" : value
    }
}
