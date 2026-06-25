//
//  BlockedUserStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/23.
//

import Foundation

struct BlockedUser: Codable, Equatable {
    let identifier: String
    let displayName: String
    let avatarImageName: String

    init(identifier: String, displayName: String, avatarImageName: String) {
        self.identifier = Self.normalizedIdentifier(identifier)
        self.displayName = displayName
        self.avatarImageName = avatarImageName
    }

    static func normalizedIdentifier(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension Notification.Name {
    static let blockedUsersDidChange = Notification.Name("skmusic.blockedUsersDidChange")
}

final class BlockedUserStore {
    static let shared = BlockedUserStore()

    private let storageKey = "skmusic.blockedUsers"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func allUsers() -> [BlockedUser] {
        guard
            let data = defaults.data(forKey: storageKey),
            let users = try? JSONDecoder().decode([BlockedUser].self, from: data)
        else {
            return []
        }

        return users
    }

    func isBlocked(identifier: String) -> Bool {
        let normalizedIdentifier = BlockedUser.normalizedIdentifier(identifier)
        return allUsers().contains { $0.identifier == normalizedIdentifier }
    }

    func block(_ user: BlockedUser) {
        guard !user.identifier.isEmpty else { return }

        var users = allUsers().filter { $0.identifier != user.identifier }
        users.append(user)
        save(users)
    }

    func unblock(identifier: String) {
        let normalizedIdentifier = BlockedUser.normalizedIdentifier(identifier)
        let users = allUsers().filter { $0.identifier != normalizedIdentifier }
        save(users)
    }

    private func save(_ users: [BlockedUser]) {
        if let data = try? JSONEncoder().encode(users) {
            defaults.set(data, forKey: storageKey)
        }

        NotificationCenter.default.post(name: .blockedUsersDidChange, object: nil)
    }
}
