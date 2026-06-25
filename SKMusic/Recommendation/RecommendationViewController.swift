//
//  RecommendationViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

final class RecommendationViewController: UIViewController, PHPickerViewControllerDelegate, UIGestureRecognizerDelegate {
    private struct RecommendationSong {
        let title: String
        let artist: String
        let note: String
        let avatarImageName: String
        let audioResourceName: String

        var blockedUser: BlockedUser {
            let displayName = artist.trimmingCharacters(in: CharacterSet(charactersIn: "- "))
            return BlockedUser(identifier: displayName, displayName: displayName, avatarImageName: avatarImageName)
        }
    }

    private struct RecommendationVideo {
        let title: String
        let coverImageName: String
        let videoResourceName: String
        let ownerName: String
        let avatarImageName: String

        init(
            title: String,
            coverImageName: String,
            videoResourceName: String,
            ownerName: String = "Annie",
            avatarImageName: String = "avatar_01"
        ) {
            self.title = title
            self.coverImageName = coverImageName
            self.videoResourceName = videoResourceName
            self.ownerName = ownerName
            self.avatarImageName = avatarImageName
        }

        var blockedUser: BlockedUser {
            BlockedUser(identifier: ownerName, displayName: ownerName, avatarImageName: avatarImageName)
        }
    }

    private let videos = [
        RecommendationVideo(
            title: "Live Crowd",
            coverImageName: "recommendation_live_crowd_cover",
            videoResourceName: "recommendation_live_crowd_video",
            ownerName: "Annie",
            avatarImageName: "avatar_01"
        ),
        RecommendationVideo(
            title: "Beach Dance",
            coverImageName: "recommendation_beach_dance_cover",
            videoResourceName: "recommendation_beach_dance_video",
            ownerName: "Bella",
            avatarImageName: "avatar_02"
        ),
        RecommendationVideo(
            title: "Sunset Skate",
            coverImageName: "recommendation_sunset_skate_cover",
            videoResourceName: "recommendation_sunset_skate_video",
            ownerName: "Chloe",
            avatarImageName: "avatar_03"
        ),
        RecommendationVideo(
            title: "Moody Stage",
            coverImageName: "recommendation_moody_stage_cover",
            videoResourceName: "recommendation_moody_stage_video",
            ownerName: "Daisy",
            avatarImageName: "avatar_04"
        ),
        RecommendationVideo(
            title: "Moody Stage Alt",
            coverImageName: "recommendation_moody_stage_alt_cover",
            videoResourceName: "recommendation_moody_stage_alt_video",
            ownerName: "Elsa",
            avatarImageName: "avatar_05"
        )
    ]

    private let songs = [
        RecommendationSong(
            title: "Best Me 50 Feet Cover",
            artist: "-Annie",
            note: "From off-key to steady singing, every practice counts.",
            avatarImageName: "avatar_01",
            audioResourceName: "best_me_50_feet_cover"
        ),
        RecommendationSong(
            title: "Flowers",
            artist: "-Miley Cyrus",
            note: "Sing out loud and sing all troubles away!",
            avatarImageName: "avatar_02",
            audioResourceName: "flowers_miley_cyrus"
        ),
        RecommendationSong(
            title: "Lady Gaga Live",
            artist: "-Lady Gaga",
            note: "Once the melody plays, happy mode turns on instantly.",
            avatarImageName: "avatar_03",
            audioResourceName: "lady_gaga_live"
        ),
        RecommendationSong(
            title: "Love Is Gone",
            artist: "-Angela",
            note: "Gather singing buddies and sing wildly all night long.",
            avatarImageName: "avatar_04",
            audioResourceName: "love_is_gone"
        ),
        RecommendationSong(
            title: "Diamonds",
            artist: "-Rihanna",
            note: "Passion beats time; sing to your heart’s content right now.",
            avatarImageName: "avatar_05",
            audioResourceName: "diamonds_rihanna_chaoshan_cover"
        ),
        RecommendationSong(
            title: "Can't Get You Out Of My Head",
            artist: "-Kylie",
            note: "Fire up the whole room with stunning high notes.",
            avatarImageName: "avatar_06",
            audioResourceName: "cant_get_you_out_of_my_head_live"
        )
    ]
    private weak var publishCardView: PublishVideoCardView?
    private weak var publishOverlayView: UIView?
    private weak var dailyCardStackView: UIStackView?
    private weak var listStackView: UIStackView?
    private var selectedPublishVideoURL: URL?
    private let usesExternalTabBar: Bool
    private let externalTabBarHeight: CGFloat = 80
    private let externalTabBarBottomInset: CGFloat = 34
    private let externalAddButtonTabBarSpacing: CGFloat = 15

    init(usesExternalTabBar: Bool = false) {
        self.usesExternalTabBar = usesExternalTabBar
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.usesExternalTabBar = false
        super.init(coder: coder)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(blockedUsersDidChange),
            name: .blockedUsersDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadContent()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        let backgroundImageView = UIImageView(image: UIImage(named: "recommendation_background"))
        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        let backButton = UIButton(type: .custom)
        configureImageButton(backButton, imageName: "back_button")
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isHidden = usesExternalTabBar
        view.addSubview(backButton)

        let contentScrollView = UIScrollView()
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.alwaysBounceVertical = true
        view.addSubview(contentScrollView)

        let contentView = UIView()
        contentScrollView.addSubview(contentView)

        let dailyTitleImageView = UIImageView(image: UIImage(named: "recommendation_daily_title"))
        dailyTitleImageView.contentMode = .scaleAspectFit
        contentView.addSubview(dailyTitleImageView)

        let coinImageView = UIImageView(image: UIImage(named: "recommendation_coin_icon"))
        coinImageView.contentMode = .scaleAspectFit
        contentView.addSubview(coinImageView)

        let cardScrollView = UIScrollView()
        cardScrollView.showsHorizontalScrollIndicator = false
        cardScrollView.alwaysBounceHorizontal = true
        contentView.addSubview(cardScrollView)

        let cardStackView = UIStackView()
        cardStackView.axis = .horizontal
        cardStackView.alignment = .fill
        cardStackView.spacing = 17
        cardScrollView.addSubview(cardStackView)
        dailyCardStackView = cardStackView

        let styleTitleImageView = UIImageView(image: UIImage(named: "recommendation_style_title"))
        styleTitleImageView.contentMode = .scaleAspectFit
        contentView.addSubview(styleTitleImageView)

        let listStackView = UIStackView()
        listStackView.axis = .vertical
        listStackView.spacing = 12
        contentView.addSubview(listStackView)
        self.listStackView = listStackView

        let bottomBarView = UIView()
        bottomBarView.backgroundColor = .white
        bottomBarView.layer.cornerRadius = 35
        bottomBarView.layer.shadowColor = UIColor.black.cgColor
        bottomBarView.layer.shadowOpacity = 0.75
        bottomBarView.layer.shadowRadius = 0
        bottomBarView.layer.shadowOffset = CGSize(width: 5, height: 5)
        bottomBarView.isHidden = usesExternalTabBar
        view.addSubview(bottomBarView)

        let bottomStackView = UIStackView()
        bottomStackView.axis = .horizontal
        bottomStackView.alignment = .center
        bottomStackView.distribution = .equalSpacing
        bottomBarView.addSubview(bottomStackView)

        ["tab_share", "tab_chat", "tab_profile"].forEach { imageName in
            let button = UIButton(type: .custom)
            configureImageButton(button, imageName: imageName)
            if imageName == "tab_chat" {
                button.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
            } else if imageName == "tab_profile" {
                button.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
            }
            bottomStackView.addArrangedSubview(button)
        }

        let addButton = UIButton(type: .custom)
        addButton.backgroundColor = .white
        addButton.layer.cornerRadius = 33
        configureImageButton(addButton, imageName: "recommendation_add_button")
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.isHidden = usesExternalTabBar
        view.addSubview(addButton)

        let externalAddButton = UIButton(type: .custom)
        configureImageButton(externalAddButton, imageName: "recommendation_home_add_button")
        externalAddButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        externalAddButton.isHidden = !usesExternalTabBar
        view.addSubview(externalAddButton)

        [
            backgroundImageView,
            backButton,
            contentScrollView,
            contentView,
            dailyTitleImageView,
            coinImageView,
            cardScrollView,
            cardStackView,
            styleTitleImageView,
            listStackView,
            bottomBarView,
            bottomStackView,
            addButton,
            externalAddButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let preferredCardScrollHeightConstraint = cardScrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.36)
        preferredCardScrollHeightConstraint.priority = .defaultHigh
        let minimumCardScrollHeightConstraint = cardScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        minimumCardScrollHeightConstraint.priority = .defaultHigh

        bottomStackView.arrangedSubviews.forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 48),
                button.heightAnchor.constraint(equalToConstant: 48)
            ])
        }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 29),

            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: -10),

            contentView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),

            dailyTitleImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            dailyTitleImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 19),
            dailyTitleImageView.widthAnchor.constraint(equalToConstant: 250),
            dailyTitleImageView.heightAnchor.constraint(equalToConstant: 37),

            coinImageView.centerYAnchor.constraint(equalTo: dailyTitleImageView.centerYAnchor),
            coinImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),
            coinImageView.widthAnchor.constraint(equalToConstant: 34),
            coinImageView.heightAnchor.constraint(equalTo: coinImageView.widthAnchor),

            cardScrollView.topAnchor.constraint(equalTo: dailyTitleImageView.bottomAnchor, constant: 27),
            cardScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 19),
            cardScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            preferredCardScrollHeightConstraint,
            cardScrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 360),
            minimumCardScrollHeightConstraint,

            cardStackView.topAnchor.constraint(equalTo: cardScrollView.contentLayoutGuide.topAnchor),
            cardStackView.leadingAnchor.constraint(equalTo: cardScrollView.contentLayoutGuide.leadingAnchor),
            cardStackView.trailingAnchor.constraint(equalTo: cardScrollView.contentLayoutGuide.trailingAnchor),
            cardStackView.bottomAnchor.constraint(equalTo: cardScrollView.contentLayoutGuide.bottomAnchor),
            cardStackView.heightAnchor.constraint(equalTo: cardScrollView.frameLayoutGuide.heightAnchor),

            styleTitleImageView.topAnchor.constraint(equalTo: cardScrollView.bottomAnchor, constant: 16),
            styleTitleImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            styleTitleImageView.widthAnchor.constraint(equalToConstant: 244),
            styleTitleImageView.heightAnchor.constraint(equalToConstant: 36),

            listStackView.topAnchor.constraint(equalTo: styleTitleImageView.bottomAnchor, constant: 10),
            listStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            listStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            listStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
            bottomBarView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.69),
            bottomBarView.heightAnchor.constraint(equalToConstant: 70),

            bottomStackView.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 41),
            bottomStackView.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -41),
            bottomStackView.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),

            addButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            addButton.widthAnchor.constraint(equalToConstant: 66),
            addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor),

            externalAddButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            externalAddButton.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -(externalTabBarBottomInset + externalTabBarHeight + externalAddButtonTabBarSpacing)
            ),
            externalAddButton.widthAnchor.constraint(equalToConstant: 68),
            externalAddButton.heightAnchor.constraint(equalToConstant: 68)
        ])

        reloadContent()
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(externalAddButton)
    }

    private func reloadContent() {
        reloadVideoCards()
        reloadSongCards()
    }

    private func reloadVideoCards() {
        guard let dailyCardStackView else { return }

        dailyCardStackView.arrangedSubviews.forEach { cardView in
            dailyCardStackView.removeArrangedSubview(cardView)
            cardView.removeFromSuperview()
        }

        currentVideos().enumerated().forEach { index, video in
            let cardView = makeDailyCardView(video, index: index)
            dailyCardStackView.addArrangedSubview(cardView)
            applyDailyCardConstraints(to: cardView)
        }
    }

    private func reloadSongCards() {
        guard let listStackView else { return }

        listStackView.arrangedSubviews.forEach { cardView in
            listStackView.removeArrangedSubview(cardView)
            cardView.removeFromSuperview()
        }

        currentSongs().enumerated().forEach { index, song in
            listStackView.addArrangedSubview(makeSongCardView(song, index: index))
        }
    }

    private func applyDailyCardConstraints(to cardView: UIView) {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.58),
            cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.32)
        ])
    }

    private func currentVideos() -> [RecommendationVideo] {
        videos.filter { !BlockedUserStore.shared.isBlocked(identifier: $0.blockedUser.identifier) }
    }

    private func currentSongs() -> [RecommendationSong] {
        songs.filter { !BlockedUserStore.shared.isBlocked(identifier: $0.blockedUser.identifier) }
    }

    private func makeDailyCardView(_ video: RecommendationVideo, index: Int) -> UIView {
        let cardView = UIView()
        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 22
        cardView.tag = index
        cardView.isUserInteractionEnabled = true
        cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(videoCardTapped(_:))))

        let coverImageView = UIImageView(image: UIImage(named: video.coverImageName))
        coverImageView.contentMode = .scaleAspectFill
        cardView.addSubview(coverImageView)

        let likeImageView = UIImageView(image: UIImage(named: "recommendation_like_icon"))
        likeImageView.contentMode = .scaleAspectFit
        cardView.addSubview(likeImageView)

        let countLabel = UILabel()
        countLabel.text = favoriteCountText(for: video)
        countLabel.textColor = .white
        countLabel.font = Self.countFont
        cardView.addSubview(countLabel)

        let playImageView = UIImageView(image: UIImage(named: "recommendation_play_icon"))
        playImageView.contentMode = .scaleAspectFit
        cardView.addSubview(playImageView)

        [coverImageView, likeImageView, countLabel, playImageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            likeImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            likeImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            likeImageView.widthAnchor.constraint(equalToConstant: 28),
            likeImageView.heightAnchor.constraint(equalTo: likeImageView.widthAnchor),

            countLabel.leadingAnchor.constraint(equalTo: likeImageView.trailingAnchor, constant: 7),
            countLabel.centerYAnchor.constraint(equalTo: likeImageView.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 48),
            countLabel.heightAnchor.constraint(equalToConstant: 24),

            playImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -19),
            playImageView.centerYAnchor.constraint(equalTo: likeImageView.centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 18),
            playImageView.heightAnchor.constraint(equalToConstant: 23)
        ])

        return cardView
    }

    private func makeSongCardView(_ song: RecommendationSong, index: Int) -> UIView {
        let cardView = UIView()
        cardView.isUserInteractionEnabled = true
        cardView.tag = index
        let cardTapGesture = UITapGestureRecognizer(target: self, action: #selector(songCardTapped(_:)))
        cardTapGesture.delegate = self
        cardView.addGestureRecognizer(cardTapGesture)

        let backgroundImageView = UIImageView(image: UIImage(named: "recommendation_list_card_background"))
        backgroundImageView.contentMode = .scaleToFill
        cardView.addSubview(backgroundImageView)

        let albumButton = UIButton(type: .custom)
        albumButton.setImage(UIImage(named: song.avatarImageName), for: .normal)
        albumButton.imageView?.contentMode = .scaleAspectFill
        albumButton.imageView?.clipsToBounds = true
        albumButton.contentHorizontalAlignment = .fill
        albumButton.contentVerticalAlignment = .fill
        albumButton.clipsToBounds = true
        albumButton.layer.cornerRadius = 27
        albumButton.tag = index
        albumButton.accessibilityLabel = "User profile"
        albumButton.addTarget(self, action: #selector(songAvatarTapped(_:)), for: .touchUpInside)
        cardView.addSubview(albumButton)

        let titleLabel = UILabel()
        titleLabel.text = song.title
        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        titleLabel.font = Self.songTitleFont
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.74
        cardView.addSubview(titleLabel)

        let artistLabel = UILabel()
        artistLabel.text = song.artist
        artistLabel.textColor = titleLabel.textColor
        artistLabel.font = Self.songArtistFont
        cardView.addSubview(artistLabel)

        let noteIconImageView = UIImageView(image: UIImage(named: "recommendation_like_icon"))
        noteIconImageView.contentMode = .scaleAspectFit
        cardView.addSubview(noteIconImageView)

        let noteLabel = UILabel()
        noteLabel.text = song.note
        noteLabel.numberOfLines = 2
        noteLabel.textColor = titleLabel.textColor
        noteLabel.font = Self.noteFont
        noteLabel.adjustsFontSizeToFitWidth = true
        noteLabel.minimumScaleFactor = 0.65
        cardView.addSubview(noteLabel)

        let playImageView = UIImageView(image: UIImage(named: "recommendation_play_icon"))
        playImageView.contentMode = .scaleAspectFit
        cardView.addSubview(playImageView)

        [
            backgroundImageView,
            albumButton,
            titleLabel,
            artistLabel,
            noteIconImageView,
            noteLabel,
            playImageView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(equalToConstant: 88),

            backgroundImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            albumButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 11),
            albumButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor, constant: -1),
            albumButton.widthAnchor.constraint(equalToConstant: 54),
            albumButton.heightAnchor.constraint(equalTo: albumButton.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: albumButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: playImageView.leadingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 19),

            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            artistLabel.heightAnchor.constraint(equalToConstant: 17),

            noteIconImageView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            noteIconImageView.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 5),
            noteIconImageView.widthAnchor.constraint(equalToConstant: 13),
            noteIconImageView.heightAnchor.constraint(equalTo: noteIconImageView.widthAnchor),

            noteLabel.leadingAnchor.constraint(equalTo: noteIconImageView.trailingAnchor, constant: 7),
            noteLabel.topAnchor.constraint(equalTo: noteIconImageView.topAnchor, constant: -2),
            noteLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            noteLabel.heightAnchor.constraint(equalToConstant: 28),

            playImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            playImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 18),
            playImageView.heightAnchor.constraint(equalToConstant: 23)
        ])

        return cardView
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func videoCardTapped(_ sender: UITapGestureRecognizer) {
        let videos = currentVideos()
        guard
            let cardView = sender.view,
            videos.indices.contains(cardView.tag)
        else {
            return
        }

        navigationController?.pushViewController(
            VideoPlayerViewController(
                tracks: videoTracks(from: videos),
                initialIndex: cardView.tag
            ),
            animated: true
        )
    }

    @objc private func songCardTapped(_ sender: UITapGestureRecognizer) {
        let songs = currentSongs()
        guard
            let cardView = sender.view,
            songs.indices.contains(cardView.tag)
        else {
            return
        }

        navigationController?.pushViewController(
            AudioPlayerViewController(tracks: audioTracks(from: songs), initialIndex: cardView.tag),
            animated: true
        )
    }

    @objc private func songAvatarTapped(_ sender: UIButton) {
        let songs = currentSongs()
        guard songs.indices.contains(sender.tag) else { return }

        let song = songs[sender.tag]
        let displayName = displayArtistName(from: song.artist)
        let profileViewController = UserProfileViewController(
            displayName: displayName,
            avatarImageName: song.avatarImageName,
            featuredTrack: AudioPlayerTrack(
                title: song.title,
                artist: displayName,
                audioURL: audioURL(for: song),
                avatarImageName: song.avatarImageName
            )
        )
        navigationController?.pushViewController(profileViewController, animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var touchedView: UIView? = touch.view
        while let view = touchedView {
            if view is UIControl {
                return false
            }
            touchedView = view.superview
        }
        return true
    }

    @objc private func messageTapped() {
        switchToMainMessageTab()
    }

    @objc private func profileTapped() {
        switchToMainProfileTab()
    }

    @objc private func addTapped() {
        let hostView = publishOverlayHostView()
        guard hostView.viewWithTag(52001) == nil else { return }

        let overlayView = UIView()
        overlayView.tag = 52001
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.50)
        let endEditingTapGesture = UITapGestureRecognizer(target: self, action: #selector(endPublishEditing))
        endEditingTapGesture.cancelsTouchesInView = false
        overlayView.addGestureRecognizer(endEditingTapGesture)
        hostView.addSubview(overlayView)
        publishOverlayView = overlayView

        let cardView = PublishVideoCardView()
        cardView.onClose = { [weak self] in
            self?.dismissPublishPopup()
        }
        cardView.onChooseVideo = { [weak self] in
            self?.choosePublishVideoTapped()
        }
        cardView.onRelease = { [weak self] values in
            self?.publishVideo(values)
        }
        publishCardView = cardView
        overlayView.addSubview(cardView)

        [
            overlayView,
            cardView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let preferredCardWidthConstraint = cardView.widthAnchor.constraint(equalToConstant: 368)
        preferredCardWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: hostView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: 31),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: overlayView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: overlayView.trailingAnchor, constant: -12),
            preferredCardWidthConstraint,
            cardView.heightAnchor.constraint(equalToConstant: 617)
        ])
    }

    @objc private func dismissPublishPopup() {
        publishCardView = nil
        selectedPublishVideoURL = nil
        publishOverlayView?.removeFromSuperview()
        publishOverlayView = nil
    }

    @objc private func endPublishEditing() {
        publishOverlayView?.endEditing(true)
    }

    @objc private func choosePublishVideoTapped() {
        publishOverlayView?.endEditing(true)

        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }
        let typeIdentifier = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            ? UTType.movie.identifier
            : provider.registeredTypeIdentifiers.first { identifier in
                identifier.contains("movie") || identifier.contains("video")
            }

        guard let typeIdentifier else { return }

        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, _ in
            guard let self, let url else { return }

            let extensionName = url.pathExtension.isEmpty ? "mov" : url.pathExtension
            let savedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(extensionName)

            do {
                if FileManager.default.fileExists(atPath: savedURL.path) {
                    try FileManager.default.removeItem(at: savedURL)
                }
                try FileManager.default.copyItem(at: url, to: savedURL)
            } catch {
                return
            }

            let thumbnail = self.makeVideoThumbnail(from: savedURL)

            DispatchQueue.main.async {
                self.selectedPublishVideoURL = savedURL
                self.publishCardView?.updateSelectedVideo(
                    name: url.lastPathComponent.isEmpty ? "Selected video" : url.lastPathComponent,
                    thumbnail: thumbnail
                )
            }
        }
    }

    private func makeVideoThumbnail(from url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 720, height: 720)

        do {
            let image = try imageGenerator.copyCGImage(
                at: CMTime(seconds: 0.1, preferredTimescale: 600),
                actualTime: nil
            )
            return UIImage(cgImage: image)
        } catch {
            return nil
        }
    }

    private func publishVideo(_ values: PublishVideoCardView.FormValues) {
        publishOverlayView?.endEditing(true)

        guard !values.releaseType.isEmpty else {
            showPublishAlert(message: "Please enter release type.")
            return
        }

        guard !values.videoTitle.isEmpty else {
            showPublishAlert(message: "Please enter video title.")
            return
        }

        guard !values.songIntroduction.isEmpty else {
            showPublishAlert(message: "Please enter song introduction.")
            return
        }

        guard selectedPublishVideoURL != nil else {
            showPublishAlert(message: "Please add MP4 audio first.")
            return
        }

        showPublishAlert(message: "Publish successful.") { [weak self] in
            self?.dismissPublishPopup()
        }
    }

    private func showPublishAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    private func publishOverlayHostView() -> UIView {
        view.window ?? navigationController?.view ?? view
    }

    @objc private func blockedUsersDidChange() {
        reloadContent()
    }

    private func audioURL(for song: RecommendationSong) -> URL? {
        if let bundledURL = Bundle.main.url(forResource: song.audioResourceName, withExtension: "mp3", subdirectory: "Mp3")
            ?? Bundle.main.url(forResource: song.audioResourceName, withExtension: "mp3") {
            return bundledURL
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }

        let fileName = "\(song.audioResourceName).mp3"
        return FileManager.default
            .enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first { $0.lastPathComponent == fileName }
    }

    private func videoURL(for video: RecommendationVideo) -> URL? {
        if let bundledURL = Bundle.main.url(forResource: video.videoResourceName, withExtension: "mp4", subdirectory: "Mp3")
            ?? Bundle.main.url(forResource: video.videoResourceName, withExtension: "mp4") {
            return bundledURL
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }

        let fileName = "\(video.videoResourceName).mp4"
        return FileManager.default
            .enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first { $0.lastPathComponent == fileName }
    }

    private func audioTracks(from songs: [RecommendationSong]) -> [AudioPlayerTrack] {
        songs.map { song in
            AudioPlayerTrack(
                title: song.title,
                artist: displayArtistName(from: song.artist),
                audioURL: audioURL(for: song),
                avatarImageName: song.avatarImageName
            )
        }
    }

    private func videoTracks(from videos: [RecommendationVideo]) -> [VideoPlayerTrack] {
        videos.map { video in
            VideoPlayerTrack(
                title: video.title,
                videoURL: videoURL(for: video),
                coverImageName: video.coverImageName,
                ownerName: video.ownerName,
                avatarImageName: video.avatarImageName
            )
        }
    }

    private func favoriteCountText(for video: RecommendationVideo) -> String {
        let item = FavoriteItem.video(
            title: video.title,
            ownerName: video.ownerName,
            coverImageName: video.coverImageName,
            videoURL: videoURL(for: video),
            avatarImageName: video.avatarImageName
        )
        return FavoriteStore.shared.isFavorite(id: item.id) ? "1" : "0"
    }

    private func displayArtistName(from artist: String) -> String {
        artist.trimmingCharacters(in: CharacterSet(charactersIn: "- "))
    }

    private static var countFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 18) ?? .italicSystemFont(ofSize: 18)
    }

    private static var songTitleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 13) ?? .italicSystemFont(ofSize: 13)
    }

    private static var songArtistFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 12) ?? .italicSystemFont(ofSize: 12)
    }

    private static var noteFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 8) ?? .italicSystemFont(ofSize: 8)
    }
}
