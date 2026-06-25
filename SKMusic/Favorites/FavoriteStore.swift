//
//  FavoriteStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import Foundation

extension Notification.Name {
    static let favoriteItemsDidChange = Notification.Name("favoriteItemsDidChange")
}

enum FavoriteItemKind: String, Codable {
    case audio
    case video
}

struct FavoriteItem: Codable, Equatable {
    let id: String
    let kind: FavoriteItemKind
    let title: String
    let subtitle: String
    let artworkImageName: String
    let resourceName: String?
    let avatarImageName: String
    let addedAt: Date

    static func audio(
        title: String,
        artist: String,
        artworkImageName: String = "record_disc",
        audioURL: URL?,
        avatarImageName: String
    ) -> FavoriteItem {
        let resourceName = Self.resourceName(from: audioURL)
        return FavoriteItem(
            id: makeID(kind: .audio, resourceName: resourceName, title: title, subtitle: artist),
            kind: .audio,
            title: title,
            subtitle: artist,
            artworkImageName: artworkImageName,
            resourceName: resourceName,
            avatarImageName: avatarImageName,
            addedAt: Date()
        )
    }

    static func video(
        title: String,
        ownerName: String,
        coverImageName: String,
        videoURL: URL?,
        avatarImageName: String
    ) -> FavoriteItem {
        let resourceName = Self.resourceName(from: videoURL)
        return FavoriteItem(
            id: makeID(kind: .video, resourceName: resourceName, title: title, subtitle: ownerName),
            kind: .video,
            title: title,
            subtitle: ownerName,
            artworkImageName: coverImageName,
            resourceName: resourceName,
            avatarImageName: avatarImageName,
            addedAt: Date()
        )
    }

    private static func resourceName(from url: URL?) -> String? {
        url?.deletingPathExtension().lastPathComponent
    }

    private static func makeID(
        kind: FavoriteItemKind,
        resourceName: String?,
        title: String,
        subtitle: String
    ) -> String {
        let rawIdentifier = resourceName ?? "\(title)-\(subtitle)"
        return "\(kind.rawValue):\(storageToken(rawIdentifier))"
    }

    private static func storageToken(_ text: String) -> String {
        text.lowercased().map { character in
            character.isLetter || character.isNumber ? String(character) : "_"
        }.joined()
    }
}

final class FavoriteStore {
    static let shared = FavoriteStore()

    private let defaults: UserDefaults
    private let legacyStorageKey = "skmusic.favoriteItems"
    private let storageKeyPrefix = "skmusic.favoriteItems"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var items: [FavoriteItem] {
        loadItems()
    }

    var count: Int {
        items.count
    }

    func isFavorite(id: String) -> Bool {
        items.contains { $0.id == id }
    }

    @discardableResult
    func toggle(_ item: FavoriteItem) -> Bool {
        isFavorite(id: item.id) ? remove(id: item.id) : add(item)
    }

    @discardableResult
    func add(_ item: FavoriteItem) -> Bool {
        var currentItems = loadItems()
        guard !currentItems.contains(where: { $0.id == item.id }) else {
            return true
        }

        currentItems.insert(item, at: 0)
        saveItems(currentItems)
        return true
    }

    @discardableResult
    func remove(id: String) -> Bool {
        let currentItems = loadItems()
        let updatedItems = currentItems.filter { $0.id != id }
        guard updatedItems.count != currentItems.count else {
            return false
        }

        saveItems(updatedItems)
        return false
    }

    private func loadItems() -> [FavoriteItem] {
        migrateLegacyItemsIfNeeded()

        guard
            let data = defaults.data(forKey: storageKey),
            let items = try? JSONDecoder().decode([FavoriteItem].self, from: data)
        else {
            return []
        }

        return items.sorted { $0.addedAt > $1.addedAt }
    }

    private func saveItems(_ items: [FavoriteItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }

        defaults.set(data, forKey: storageKey)
        NotificationCenter.default.post(name: .favoriteItemsDidChange, object: nil)
    }

    private var storageKey: String {
        "\(storageKeyPrefix).\(AuthSession.storageSafeComponent(AuthSession.currentEmail ?? "guest"))"
    }

    private func migrateLegacyItemsIfNeeded() {
        guard AuthSession.isCurrentTestAccount else { return }
        guard defaults.data(forKey: storageKey) == nil else { return }
        guard let legacyData = defaults.data(forKey: legacyStorageKey) else { return }

        defaults.set(legacyData, forKey: storageKey)
    }
}
