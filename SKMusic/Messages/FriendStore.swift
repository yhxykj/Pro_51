//
//  FriendStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import Foundation

struct FriendRecord {
    let name: String
    let avatarImageName: String
}

final class FriendStore {
    static let shared = FriendStore()

    private init() {}

    var friends: [FriendRecord] {
        guard
            let currentEmail = AuthSession.currentEmail,
            AuthSession.normalizedEmail(currentEmail) == AuthSession.testEmail
        else {
            return []
        }

        return Self.testAccountFriends
    }

    var count: Int {
        friends.count
    }

    func isFriend(name: String) -> Bool {
        let normalizedName = Self.normalizedName(name)
        return friends.contains { Self.normalizedName($0.name) == normalizedName }
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: CharacterSet(charactersIn: "- "))
            .lowercased()
    }

    private static let testAccountFriends = [
        FriendRecord(name: "Annie", avatarImageName: "avatar_01"),
        FriendRecord(name: "Miley Cyrus", avatarImageName: "avatar_02")
    ]
}
