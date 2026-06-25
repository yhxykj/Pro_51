//
//  AccountProfileStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import UIKit

struct AccountProfile {
    let email: String
    let displayName: String
    let avatarImageName: String
    let avatarImage: UIImage?
}

final class AccountProfileStore {
    static let shared = AccountProfileStore()

    private struct StoredProfile: Codable {
        let displayName: String
        let avatarImageData: Data?
    }

    private let defaults: UserDefaults
    private let storageKeyPrefix = "skmusic.accountProfile"
    private let defaultAvatarImageName = "avatar_19"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentProfile() -> AccountProfile {
        let email = AuthSession.currentEmail ?? AuthSession.testEmail
        return profile(for: email)
    }

    func saveCurrentProfile(displayName: String, avatarImage: UIImage?) {
        guard let currentEmail = AuthSession.currentEmail else { return }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let existingProfile = storedProfile(for: currentEmail)
        let avatarImageData = avatarImage?.jpegData(compressionQuality: 0.86) ?? existingProfile?.avatarImageData
        let profile = StoredProfile(displayName: trimmedName, avatarImageData: avatarImageData)
        guard let data = try? JSONEncoder().encode(profile) else { return }

        defaults.set(data, forKey: storageKey(for: currentEmail))
    }

    private func profile(for email: String) -> AccountProfile {
        let normalizedEmail = AuthSession.normalizedEmail(email)
        let storedProfile = storedProfile(for: normalizedEmail)
        let displayName = storedProfile?.displayName ?? defaultDisplayName(for: normalizedEmail)
        let avatarImage = storedProfile?.avatarImageData.flatMap(UIImage.init(data:))

        return AccountProfile(
            email: normalizedEmail,
            displayName: displayName,
            avatarImageName: defaultAvatarImageName,
            avatarImage: avatarImage
        )
    }

    private func storedProfile(for email: String) -> StoredProfile? {
        guard
            let data = defaults.data(forKey: storageKey(for: email)),
            let profile = try? JSONDecoder().decode(StoredProfile.self, from: data)
        else {
            return nil
        }

        return profile
    }

    private func defaultDisplayName(for email: String) -> String {
        if AuthSession.normalizedEmail(email) == AuthSession.testEmail {
            return "Music666"
        }

        let prefix = email.split(separator: "@").first.map(String.init) ?? "New User"
        let cleanedPrefix = prefix
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: " ")
        let name = cleanedPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "New User" : name.capitalized
    }

    private func storageKey(for email: String) -> String {
        "\(storageKeyPrefix).\(AuthSession.storageSafeComponent(email))"
    }
}
