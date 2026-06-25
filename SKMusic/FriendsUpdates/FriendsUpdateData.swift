//
//  FriendsUpdateData.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import Foundation

enum FriendsUpdateData {
    static let items = [
        FriendsUpdateItem(
            mediaKind: .video,
            title: "Live Crowd",
            note: "Mia posted a live crowd video from tonight's music party.",
            likes: "88W",
            name: "Mia",
            detailName: "Mia",
            detailText: "Mia posted a live crowd video from tonight's music party.",
            coverImageName: "recommendation_live_crowd_cover",
            avatarImageName: "avatar_07",
            audioResourceName: nil,
            videoResourceName: "recommendation_live_crowd_video"
        ),
        FriendsUpdateItem(
            mediaKind: .audio,
            title: "I Will Be There",
            note: "Leo shared a warm audio take for friends to listen and comment.",
            likes: "76W",
            name: "Leo",
            detailName: "Leo",
            detailText: "Leo shared a warm audio take for friends to listen and comment.",
            coverImageName: "friends_updates_cover_community",
            avatarImageName: "avatar_08",
            audioResourceName: "i_will_be_there",
            videoResourceName: nil
        ),
        FriendsUpdateItem(
            mediaKind: .video,
            title: "Sunset Skate",
            note: "Nora posted a sunset skate video with a bright chorus mood.",
            likes: "92W",
            name: "Nora",
            detailName: "Nora",
            detailText: "Nora posted a sunset skate video with a bright chorus mood.",
            coverImageName: "recommendation_sunset_skate_cover",
            avatarImageName: "avatar_09",
            audioResourceName: nil,
            videoResourceName: "recommendation_sunset_skate_video"
        )
    ]

    static func audioURL(for item: FriendsUpdateItem) -> URL? {
        guard let audioResourceName = item.audioResourceName else { return nil }
        return mediaURL(forResource: audioResourceName, fileExtension: "mp3")
    }

    static func videoURL(for item: FriendsUpdateItem) -> URL? {
        guard let videoResourceName = item.videoResourceName else { return nil }
        return mediaURL(forResource: videoResourceName, fileExtension: "mp4")
    }

    private static func mediaURL(forResource resourceName: String, fileExtension: String) -> URL? {
        if let bundledURL = Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Mp3")
            ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension) {
            return bundledURL
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }

        let fileName = "\(resourceName).\(fileExtension)"
        return FileManager.default
            .enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first { $0.lastPathComponent == fileName }
    }
}
