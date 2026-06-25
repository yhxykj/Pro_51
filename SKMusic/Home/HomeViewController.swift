//
//  HomeViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    private enum MediaKind {
        case video
        case audio
    }

    private enum FriendState {
        case add
        case good
    }

    private struct HomeMediaItem {
        let kind: MediaKind
        let mediaImageName: String
        let friendState: FriendState
        let videoResourceName: String?
        let blockedUser: BlockedUser

        init(
            kind: MediaKind,
            mediaImageName: String,
            friendState: FriendState,
            videoResourceName: String? = nil,
            blockedUser: BlockedUser = BlockedUser(identifier: "Annie", displayName: "Annie", avatarImageName: "avatar_01")
        ) {
            self.kind = kind
            self.mediaImageName = mediaImageName
            self.friendState = friendState
            self.videoResourceName = videoResourceName
            self.blockedUser = blockedUser
        }
    }

    private let mediaItems = [
        HomeMediaItem(
            kind: .video,
            mediaImageName: "recommendation_live_crowd_cover",
            friendState: .add,
            videoResourceName: "recommendation_live_crowd_video"
        ),
        HomeMediaItem(kind: .audio, mediaImageName: "record_disc", friendState: .add),
        HomeMediaItem(kind: .audio, mediaImageName: "record_disc", friendState: .good)
    ]

    private let mediaLayout = UICollectionViewFlowLayout()
    private lazy var mediaCollectionView = UICollectionView(frame: .zero, collectionViewLayout: mediaLayout)
    private let friendStateButton = UIButton(type: .custom)

    private var currentIndex = 0
    private var videoMediaHeightConstraint: NSLayoutConstraint!
    private var audioMediaHeightConstraint: NSLayoutConstraint!
    private var reportVideoCenterYConstraint: NSLayoutConstraint!
    private var reportAudioTopConstraint: NSLayoutConstraint!
    private var lastMediaCollectionSize = CGSize.zero

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateCurrentItem(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshMediaLayoutIfNeeded()
    }

    private func setupViews() {
        view.backgroundColor = .white

        let backgroundImageView = UIImageView(image: UIImage(named: "home_background"))
        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        let headerTitleImageView = UIImageView(image: UIImage(named: "audio_player_title"))
        headerTitleImageView.contentMode = .scaleAspectFit
        view.addSubview(headerTitleImageView)

        let reportButton = UIButton(type: .custom)
        configureImageButton(reportButton, imageName: "report_icon", accessibilityLabel: "Report")
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        view.addSubview(reportButton)

        mediaLayout.scrollDirection = .horizontal
        mediaLayout.minimumLineSpacing = 0
        mediaLayout.minimumInteritemSpacing = 0
        mediaCollectionView.backgroundColor = .clear
        mediaCollectionView.clipsToBounds = true
        mediaCollectionView.isPagingEnabled = true
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self
        mediaCollectionView.register(HomeMediaCollectionViewCell.self, forCellWithReuseIdentifier: HomeMediaCollectionViewCell.reuseIdentifier)
        view.addSubview(mediaCollectionView)

        let songTitleImageView = UIImageView(image: UIImage(named: "song_title_head_clouds"))
        let artistImageView = UIImageView(image: UIImage(named: "artist_annie"))
        [songTitleImageView, artistImageView].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
        }

        configureFriendStateButton()
        view.addSubview(friendStateButton)

        let likeButton = UIButton(type: .custom)
        configureImageButton(likeButton, imageName: "like_icon", accessibilityLabel: "Like")
        view.addSubview(likeButton)

        let likeCountLabel = UILabel()
        configureCountLabel(likeCountLabel)
        likeCountLabel.text = "99+"
        view.addSubview(likeCountLabel)

        let progressSlider = UISlider()
        configureProgressSlider(progressSlider)
        view.addSubview(progressSlider)

        let elapsedTimeLabel = UILabel()
        let totalTimeLabel = UILabel()
        configureTimeLabel(elapsedTimeLabel, text: "00:18", alignment: .left)
        configureTimeLabel(totalTimeLabel, text: "03:18", alignment: .right)
        view.addSubview(elapsedTimeLabel)
        view.addSubview(totalTimeLabel)

        let repeatButton = UIButton(type: .custom)
        let previousButton = UIButton(type: .custom)
        let playPauseButton = UIButton(type: .custom)
        let nextButton = UIButton(type: .custom)
        let commentButton = UIButton(type: .custom)
        configureImageButton(repeatButton, imageName: "repeat_one_button", accessibilityLabel: "Repeat")
        configureImageButton(previousButton, imageName: "previous_button", accessibilityLabel: "Previous")
        configureImageButton(playPauseButton, imageName: "play_pause_button", accessibilityLabel: "Play")
        configureImageButton(nextButton, imageName: "next_button", accessibilityLabel: "Next")
        configureImageButton(commentButton, imageName: "comment_icon", accessibilityLabel: "Comment")
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)

        let controlsStackView = UIStackView()
        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.distribution = .equalSpacing
        controlsStackView.setCustomSpacing(28, after: nextButton)
        [repeatButton, previousButton, playPauseButton, nextButton, commentButton].forEach { controlsStackView.addArrangedSubview($0) }
        view.addSubview(controlsStackView)

        let commentCountLabel = UILabel()
        configureCountLabel(commentCountLabel)
        commentCountLabel.text = "99+"
        view.addSubview(commentCountLabel)
        view.bringSubviewToFront(reportButton)

        [
            backgroundImageView,
            headerTitleImageView,
            reportButton,
            mediaCollectionView,
            songTitleImageView,
            artistImageView,
            friendStateButton,
            likeButton,
            likeCountLabel,
            progressSlider,
            elapsedTimeLabel,
            totalTimeLabel,
            controlsStackView,
            repeatButton,
            previousButton,
            playPauseButton,
            nextButton,
            commentButton,
            commentCountLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        videoMediaHeightConstraint = mediaCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.49)
        audioMediaHeightConstraint = mediaCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.36)
        videoMediaHeightConstraint.priority = .defaultHigh
        audioMediaHeightConstraint.priority = .defaultHigh
        reportVideoCenterYConstraint = reportButton.centerYAnchor.constraint(equalTo: headerTitleImageView.centerYAnchor)
        reportAudioTopConstraint = reportButton.topAnchor.constraint(equalTo: mediaCollectionView.bottomAnchor, constant: -39)
        let minimumMediaHeightConstraint = mediaCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        minimumMediaHeightConstraint.priority = .defaultHigh

        [repeatButton, previousButton, playPauseButton, nextButton, commentButton].forEach { button in
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 54),
                button.heightAnchor.constraint(equalToConstant: 54)
            ])
        }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerTitleImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerTitleImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            headerTitleImageView.widthAnchor.constraint(equalToConstant: 138),
            headerTitleImageView.heightAnchor.constraint(equalToConstant: 36),

            reportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            reportButton.widthAnchor.constraint(equalToConstant: 34),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor),

            mediaCollectionView.topAnchor.constraint(equalTo: headerTitleImageView.bottomAnchor, constant: 18),
            mediaCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mediaCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mediaCollectionView.heightAnchor.constraint(lessThanOrEqualToConstant: 430),
            minimumMediaHeightConstraint,

            songTitleImageView.leadingAnchor.constraint(equalTo: mediaCollectionView.leadingAnchor),
            songTitleImageView.widthAnchor.constraint(lessThanOrEqualTo: mediaCollectionView.widthAnchor, multiplier: 0.76),
            songTitleImageView.heightAnchor.constraint(equalToConstant: 40),
            mediaCollectionView.bottomAnchor.constraint(lessThanOrEqualTo: songTitleImageView.topAnchor, constant: -14),

            artistImageView.topAnchor.constraint(equalTo: songTitleImageView.bottomAnchor, constant: 2),
            artistImageView.leadingAnchor.constraint(equalTo: songTitleImageView.leadingAnchor),
            artistImageView.widthAnchor.constraint(equalToConstant: 70),
            artistImageView.heightAnchor.constraint(equalToConstant: 31),

            friendStateButton.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
            friendStateButton.leadingAnchor.constraint(equalTo: artistImageView.trailingAnchor, constant: 16),
            friendStateButton.widthAnchor.constraint(equalToConstant: 112),
            friendStateButton.heightAnchor.constraint(equalToConstant: 22),

            likeButton.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: mediaCollectionView.trailingAnchor, constant: -24),
            likeButton.widthAnchor.constraint(equalToConstant: 45),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor, constant: 8),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 36),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 18),

            progressSlider.topAnchor.constraint(equalTo: artistImageView.bottomAnchor, constant: 27),
            progressSlider.leadingAnchor.constraint(equalTo: mediaCollectionView.leadingAnchor, constant: 8),
            progressSlider.trailingAnchor.constraint(equalTo: mediaCollectionView.trailingAnchor, constant: -8),
            progressSlider.heightAnchor.constraint(equalToConstant: 22),

            elapsedTimeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: -2),
            elapsedTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            elapsedTimeLabel.widthAnchor.constraint(equalToConstant: 52),
            elapsedTimeLabel.heightAnchor.constraint(equalToConstant: 18),

            totalTimeLabel.topAnchor.constraint(equalTo: elapsedTimeLabel.topAnchor),
            totalTimeLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            totalTimeLabel.widthAnchor.constraint(equalToConstant: 52),
            totalTimeLabel.heightAnchor.constraint(equalTo: elapsedTimeLabel.heightAnchor),

            controlsStackView.topAnchor.constraint(equalTo: elapsedTimeLabel.bottomAnchor, constant: 12),
            controlsStackView.leadingAnchor.constraint(equalTo: mediaCollectionView.leadingAnchor, constant: -3),
            controlsStackView.trailingAnchor.constraint(equalTo: mediaCollectionView.trailingAnchor, constant: -18),
            controlsStackView.heightAnchor.constraint(equalToConstant: 58),
            controlsStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -144),

            commentCountLabel.leadingAnchor.constraint(equalTo: commentButton.trailingAnchor, constant: -5),
            commentCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: mediaCollectionView.trailingAnchor),
            commentCountLabel.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor, constant: 11),
            commentCountLabel.widthAnchor.constraint(equalToConstant: 39),
            commentCountLabel.heightAnchor.constraint(equalToConstant: 18)
        ])

        videoMediaHeightConstraint.isActive = true
        reportVideoCenterYConstraint.isActive = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeMediaCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? HomeMediaCollectionViewCell
        else {
            return UICollectionViewCell()
        }

        let item = mediaItems[indexPath.item]
        cell.configure(imageName: item.mediaImageName, isAudio: item.kind == .audio)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = mediaItems[indexPath.item]
        let playerViewController: UIViewController

        switch item.kind {
        case .video:
            playerViewController = VideoPlayerViewController(
                videoURL: videoURL(for: item),
                coverImageName: item.mediaImageName
            )
        case .audio:
            playerViewController = AudioPlayerViewController(isGoodFriend: item.friendState == .good)
        }

        (navigationController ?? parent?.navigationController)?.pushViewController(playerViewController, animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateIndexFromScrollPosition()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateIndexFromScrollPosition()
    }

    private func updateIndexFromScrollPosition() {
        let width = max(mediaCollectionView.bounds.width, 1)
        let index = Int((mediaCollectionView.contentOffset.x / width).rounded())
        setCurrentIndex(index, scroll: false, animated: true)
    }

    private func setCurrentIndex(_ index: Int, scroll: Bool, animated: Bool) {
        guard mediaItems.indices.contains(index) else { return }
        currentIndex = index
        updateCurrentItem(animated: animated) { [self] in
            guard scroll else { return }
            scrollToCurrentMedia(animated: animated)
        }
    }

    private func updateCurrentItem(animated: Bool, completion: (() -> Void)? = nil) {
        let item = mediaItems[currentIndex]
        let isAudio = item.kind == .audio

        videoMediaHeightConstraint.isActive = !isAudio
        audioMediaHeightConstraint.isActive = isAudio
        reportVideoCenterYConstraint.isActive = !isAudio
        reportAudioTopConstraint.isActive = isAudio
        updateFriendStateButton(item.friendState)

        let updates = {
            self.view.layoutIfNeeded()
        }

        guard animated else {
            updates()
            refreshMediaLayoutIfNeeded()
            completion?()
            return
        }

        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: updates) { [self] _ in
            refreshMediaLayoutIfNeeded()
            completion?()
        }
    }

    private func refreshMediaLayoutIfNeeded() {
        let size = mediaCollectionView.bounds.size
        guard size.width > 0, size.height > 0, size != lastMediaCollectionSize else { return }
        lastMediaCollectionSize = size
        mediaLayout.itemSize = size
        mediaLayout.invalidateLayout()
    }

    private func scrollToCurrentMedia(animated: Bool) {
        guard mediaCollectionView.numberOfItems(inSection: 0) > currentIndex else { return }
        mediaCollectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    @objc private func previousTapped() {
        let nextIndex = (currentIndex - 1 + mediaItems.count) % mediaItems.count
        setCurrentIndex(nextIndex, scroll: true, animated: true)
    }

    @objc private func nextTapped() {
        let nextIndex = (currentIndex + 1) % mediaItems.count
        setCurrentIndex(nextIndex, scroll: true, animated: true)
    }

    @objc private func messageTapped() {
        switchToMainMessageTab()
    }

    @objc private func reportTapped() {
        guard let hostView = parent?.view ?? view else { return }
        presentReportBlockPopup(in: hostView, blockedUser: mediaItems[currentIndex].blockedUser)
    }

    private func configureFriendStateButton() {
        friendStateButton.backgroundColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
        friendStateButton.layer.cornerRadius = 11
        friendStateButton.setTitleColor(UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1), for: .normal)
        friendStateButton.titleLabel?.font = Self.friendButtonFont
        friendStateButton.titleLabel?.adjustsFontSizeToFitWidth = true
        friendStateButton.titleLabel?.minimumScaleFactor = 0.78
        friendStateButton.accessibilityLabel = "Friend State"
    }

    private func updateFriendStateButton(_ state: FriendState) {
        let title = state == .add ? "+ Add Friend" : "Good Friend"
        friendStateButton.setTitle(title, for: .normal)
        friendStateButton.backgroundColor = state == .add
            ? UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
            : UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
    }

    private func videoURL(for item: HomeMediaItem) -> URL? {
        guard let videoResourceName = item.videoResourceName else { return nil }

        if let bundledURL = Bundle.main.url(forResource: videoResourceName, withExtension: "mp4", subdirectory: "Mp3")
            ?? Bundle.main.url(forResource: videoResourceName, withExtension: "mp4") {
            return bundledURL
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }

        let fileName = "\(videoResourceName).mp4"
        return FileManager.default
            .enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first { $0.lastPathComponent == fileName }
    }

    private func configureImageButton(_ button: UIButton, imageName: String, accessibilityLabel: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
        button.accessibilityLabel = accessibilityLabel
    }

    private func configureProgressSlider(_ slider: UISlider) {
        slider.minimumValue = 0
        slider.maximumValue = 198
        slider.value = 18
        slider.minimumTrackTintColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
        slider.maximumTrackTintColor = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
        slider.thumbTintColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
    }

    private func configureTimeLabel(_ label: UILabel, text: String, alignment: NSTextAlignment) {
        label.text = text
        label.textAlignment = alignment
        label.textColor = UIColor(red: 0.36, green: 0.36, blue: 0.38, alpha: 1)
        label.font = Self.timeFont
    }

    private func configureCountLabel(_ label: UILabel) {
        label.textColor = UIColor(red: 0.19, green: 0.19, blue: 0.20, alpha: 1)
        label.font = Self.countFont
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
    }

    private static var friendButtonFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 13) ?? .italicSystemFont(ofSize: 13)
    }

    private static var timeFont: UIFont {
        UIFont(name: "AvenirNext-MediumItalic", size: 11) ?? .italicSystemFont(ofSize: 11)
    }

    private static var countFont: UIFont {
        UIFont(name: "AvenirNext-Bold", size: 14) ?? .boldSystemFont(ofSize: 14)
    }
}
