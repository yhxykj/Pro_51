//
//  VideoPlayerViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import AVFoundation
import UIKit

struct VideoPlayerTrack {
    let title: String
    let videoURL: URL?
    let coverImageName: String
    let ownerName: String
    let avatarImageName: String

    init(
        title: String = "Live Crowd",
        videoURL: URL?,
        coverImageName: String,
        ownerName: String = "Annie",
        avatarImageName: String = "avatar_01"
    ) {
        self.title = title
        self.videoURL = videoURL
        self.coverImageName = coverImageName
        self.ownerName = ownerName
        self.avatarImageName = avatarImageName
    }

    var blockedUser: BlockedUser {
        BlockedUser(identifier: ownerName, displayName: ownerName, avatarImageName: avatarImageName)
    }
}

final class VideoPlayerViewController: UIViewController {
    private let tracks: [VideoPlayerTrack]
    private var currentIndex: Int
    private var currentTrack: VideoPlayerTrack {
        tracks[currentIndex]
    }

    private let playerView = PlayerView()
    private let coverImageView = UIImageView()
    private let playPauseButton = UIButton(type: .custom)
    private let progressSlider = UISlider()
    private let elapsedTimeLabel = UILabel()
    private let totalTimeLabel = UILabel()
    private weak var ownerNameLabel: UILabel?
    private weak var friendButton: UIButton?
    private weak var likeButton: UIButton?
    private weak var likeCountLabel: UILabel?
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemEndObserver: NSObjectProtocol?
    private var isScrubbing = false
    private var wasPlayingBeforeScrubbing = false

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(videoURL: URL? = nil, coverImageName: String = "video_cover") {
        self.tracks = [VideoPlayerTrack(videoURL: videoURL, coverImageName: coverImageName)]
        self.currentIndex = 0
        super.init(nibName: nil, bundle: nil)
    }

    init(tracks: [VideoPlayerTrack], initialIndex: Int = 0) {
        let resolvedTracks = tracks.isEmpty
            ? [VideoPlayerTrack(videoURL: nil, coverImageName: "video_cover")]
            : tracks

        self.tracks = resolvedTracks
        self.currentIndex = min(max(initialIndex, 0), resolvedTracks.count - 1)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.tracks = [VideoPlayerTrack(videoURL: nil, coverImageName: "video_cover")]
        self.currentIndex = 0
        super.init(coder: coder)
    }

    deinit {
        removeTimeObserver()
        removeItemEndObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureCurrentTrack(autoplay: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
        updatePlayPauseButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        updatePlayPauseButton()
    }

    private func setupViews() {
        view.backgroundColor = .white

        let backgroundImageView = UIImageView(image: UIImage(named: "home_background"))
        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        let headerTitleImageView = UIImageView(image: UIImage(named: "audio_player_title"))
        headerTitleImageView.contentMode = .scaleAspectFit
        view.addSubview(headerTitleImageView)

        let backButton = UIButton(type: .custom)
        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let reportButton = UIButton(type: .custom)
        configureImageButton(reportButton, imageName: "report_icon", accessibilityLabel: "Report")
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        view.addSubview(reportButton)

        let mediaContainerView = UIView()
        mediaContainerView.backgroundColor = .black
        mediaContainerView.clipsToBounds = true
        mediaContainerView.layer.cornerRadius = 18
        view.addSubview(mediaContainerView)

        playerView.backgroundColor = .black
        mediaContainerView.addSubview(playerView)

        coverImageView.image = UIImage(named: currentTrack.coverImageName)
        coverImageView.contentMode = .scaleAspectFill
        mediaContainerView.addSubview(coverImageView)

        let songTitleImageView = UIImageView(image: UIImage(named: "song_title_head_clouds"))
        songTitleImageView.contentMode = .scaleAspectFit
        view.addSubview(songTitleImageView)

        let ownerNameLabel = UILabel()
        configureOwnerNameLabel(ownerNameLabel)
        ownerNameLabel.text = currentTrack.ownerName
        ownerNameLabel.isUserInteractionEnabled = true
        ownerNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ownerNameTapped)))
        view.addSubview(ownerNameLabel)
        self.ownerNameLabel = ownerNameLabel

        let addFriendButton = UIButton(type: .custom)
        addFriendButton.backgroundColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
        addFriendButton.layer.cornerRadius = 11
        addFriendButton.setTitle("+ Add Friend", for: .normal)
        addFriendButton.setTitleColor(UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1), for: .normal)
        addFriendButton.titleLabel?.font = Self.friendButtonFont
        addFriendButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addFriendButton.titleLabel?.minimumScaleFactor = 0.78
        addFriendButton.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
        view.addSubview(addFriendButton)
        self.friendButton = addFriendButton

        let likeButton = UIButton(type: .custom)
        configureImageButton(likeButton, imageName: "unlike_icon", accessibilityLabel: "Not Liked")
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        view.addSubview(likeButton)
        self.likeButton = likeButton

        let likeCountLabel = UILabel()
        configureCountLabel(likeCountLabel)
        likeCountLabel.text = "0"
        view.addSubview(likeCountLabel)
        self.likeCountLabel = likeCountLabel

        configureProgressSlider(progressSlider)
        view.addSubview(progressSlider)

        configureTimeLabel(elapsedTimeLabel, text: "00:00", alignment: .left)
        configureTimeLabel(totalTimeLabel, text: "00:00", alignment: .right)
        view.addSubview(elapsedTimeLabel)
        view.addSubview(totalTimeLabel)

        let previousButton = UIButton(type: .custom)
        let nextButton = UIButton(type: .custom)
        configureImageButton(previousButton, imageName: "previous_button", accessibilityLabel: "Previous")
        configureImageButton(playPauseButton, imageName: "player_control_play_button", accessibilityLabel: "Play")
        configureImageButton(nextButton, imageName: "next_button", accessibilityLabel: "Next")
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        let controlsStackView = UIStackView()
        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.distribution = .equalSpacing
        [previousButton, playPauseButton, nextButton].forEach { controlsStackView.addArrangedSubview($0) }
        view.addSubview(controlsStackView)

        [
            backgroundImageView,
            headerTitleImageView,
            backButton,
            reportButton,
            mediaContainerView,
            playerView,
            coverImageView,
            songTitleImageView,
            ownerNameLabel,
            addFriendButton,
            likeButton,
            likeCountLabel,
            progressSlider,
            elapsedTimeLabel,
            totalTimeLabel,
            controlsStackView,
            previousButton,
            playPauseButton,
            nextButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        [previousButton, playPauseButton, nextButton].forEach { button in
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 54),
                button.heightAnchor.constraint(equalToConstant: 54)
            ])
        }

        let mediaHeightConstraint = mediaContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.49)
        mediaHeightConstraint.priority = .defaultHigh
        let minimumMediaHeightConstraint = mediaContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220)
        minimumMediaHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerTitleImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerTitleImageView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            headerTitleImageView.widthAnchor.constraint(equalToConstant: 138),
            headerTitleImageView.heightAnchor.constraint(equalToConstant: 36),

            backButton.centerYAnchor.constraint(equalTo: headerTitleImageView.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 29),

            reportButton.centerYAnchor.constraint(equalTo: headerTitleImageView.centerYAnchor),
            reportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            reportButton.widthAnchor.constraint(equalToConstant: 34),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor),

            mediaContainerView.topAnchor.constraint(equalTo: headerTitleImageView.bottomAnchor, constant: 18),
            mediaContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mediaContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mediaContainerView.heightAnchor.constraint(lessThanOrEqualToConstant: 430),
            mediaHeightConstraint,
            minimumMediaHeightConstraint,

            playerView.topAnchor.constraint(equalTo: mediaContainerView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: mediaContainerView.bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: mediaContainerView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: mediaContainerView.bottomAnchor),

            songTitleImageView.topAnchor.constraint(equalTo: mediaContainerView.bottomAnchor, constant: 14),
            songTitleImageView.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor),
            songTitleImageView.widthAnchor.constraint(lessThanOrEqualTo: mediaContainerView.widthAnchor, multiplier: 0.76),
            songTitleImageView.heightAnchor.constraint(equalToConstant: 40),

            ownerNameLabel.topAnchor.constraint(equalTo: songTitleImageView.bottomAnchor, constant: 2),
            ownerNameLabel.leadingAnchor.constraint(equalTo: songTitleImageView.leadingAnchor),
            ownerNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 142),
            ownerNameLabel.heightAnchor.constraint(equalToConstant: 31),

            addFriendButton.centerYAnchor.constraint(equalTo: ownerNameLabel.centerYAnchor),
            addFriendButton.leadingAnchor.constraint(equalTo: ownerNameLabel.trailingAnchor, constant: 16),
            addFriendButton.trailingAnchor.constraint(lessThanOrEqualTo: likeButton.leadingAnchor, constant: -12),
            addFriendButton.widthAnchor.constraint(equalToConstant: 112),
            addFriendButton.heightAnchor.constraint(equalToConstant: 22),

            likeButton.centerYAnchor.constraint(equalTo: ownerNameLabel.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: likeCountLabel.leadingAnchor, constant: -4),
            likeButton.widthAnchor.constraint(equalToConstant: 45),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor),

            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor, constant: 8),
            likeCountLabel.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor, constant: -8),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 54),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 18),

            progressSlider.topAnchor.constraint(equalTo: ownerNameLabel.bottomAnchor, constant: 22),
            progressSlider.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor, constant: 8),
            progressSlider.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor, constant: -8),
            progressSlider.heightAnchor.constraint(equalToConstant: 22),

            elapsedTimeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: -2),
            elapsedTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            elapsedTimeLabel.widthAnchor.constraint(equalToConstant: 52),
            elapsedTimeLabel.heightAnchor.constraint(equalToConstant: 18),

            totalTimeLabel.topAnchor.constraint(equalTo: elapsedTimeLabel.topAnchor),
            totalTimeLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            totalTimeLabel.widthAnchor.constraint(equalToConstant: 52),
            totalTimeLabel.heightAnchor.constraint(equalTo: elapsedTimeLabel.heightAnchor),

            controlsStackView.topAnchor.constraint(equalTo: elapsedTimeLabel.bottomAnchor, constant: 10),
            controlsStackView.centerXAnchor.constraint(equalTo: mediaContainerView.centerXAnchor),
            controlsStackView.widthAnchor.constraint(equalToConstant: 220),
            controlsStackView.widthAnchor.constraint(lessThanOrEqualTo: mediaContainerView.widthAnchor),
            controlsStackView.heightAnchor.constraint(equalToConstant: 58),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func configureCurrentTrack(autoplay: Bool) {
        coverImageView.image = UIImage(named: currentTrack.coverImageName)
        ownerNameLabel?.text = currentTrack.ownerName
        updateFriendButton()
        resetProgress()
        removeTimeObserver()
        removeItemEndObserver()

        guard let videoURL = currentTrack.videoURL else {
            player?.replaceCurrentItem(with: nil)
            playerView.isHidden = true
            coverImageView.isHidden = false
            updatePlayPauseButton()
            updateLikeButton()
            return
        }

        configureAudioSession()

        let playerItem = AVPlayerItem(url: videoURL)

        if let player {
            player.replaceCurrentItem(with: playerItem)
            player.isMuted = false
            player.volume = 1
        } else {
            let player = AVPlayer(playerItem: playerItem)
            player.isMuted = false
            player.volume = 1
            self.player = player
            playerView.player = player
        }

        playerView.isHidden = false
        coverImageView.isHidden = true
        addTimeObserver()
        observeEnd(of: playerItem)
        updateProgress()

        if autoplay {
            player?.play()
        }

        updatePlayPauseButton()
        updateLikeButton()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            return
        }
    }

    private func addTimeObserver() {
        guard timeObserverToken == nil, let player else { return }

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func removeTimeObserver() {
        guard let timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }

    private func observeEnd(of item: AVPlayerItem) {
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.playerDidFinishPlaying()
        }
    }

    private func removeItemEndObserver() {
        guard let itemEndObserver else { return }
        NotificationCenter.default.removeObserver(itemEndObserver)
        self.itemEndObserver = nil
    }

    private func resetProgress() {
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        elapsedTimeLabel.text = "00:00"
        totalTimeLabel.text = "00:00"
    }

    private func updateProgress() {
        let current = sanitizedSeconds(player?.currentTime().seconds ?? 0)
        let duration = currentDuration()
        let sliderMaximum = max(duration, 1)

        progressSlider.maximumValue = Float(sliderMaximum)

        if !isScrubbing {
            progressSlider.value = Float(min(max(current, 0), sliderMaximum))
        }

        elapsedTimeLabel.text = formattedTime(current)
        totalTimeLabel.text = duration > 0 ? formattedTime(duration) : "00:00"
    }

    private func currentDuration() -> Double {
        if let itemDuration = player?.currentItem?.duration.seconds {
            let seconds = sanitizedSeconds(itemDuration)
            if seconds > 0 {
                return seconds
            }
        }

        if let assetDuration = player?.currentItem?.asset.duration.seconds {
            let seconds = sanitizedSeconds(assetDuration)
            if seconds > 0 {
                return seconds
            }
        }

        return 0
    }

    private func sanitizedSeconds(_ value: Double) -> Double {
        guard value.isFinite, !value.isNaN, value > 0 else { return 0 }
        return value
    }

    private func formattedTime(_ seconds: Double) -> String {
        let roundedSeconds = max(Int(seconds.rounded()), 0)
        let minutes = roundedSeconds / 60
        let seconds = roundedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func configureImageButton(_ button: UIButton, imageName: String, accessibilityLabel: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
        button.accessibilityLabel = accessibilityLabel
    }

    private func configureProgressSlider(_ slider: UISlider) {
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.minimumTrackTintColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
        slider.maximumTrackTintColor = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
        slider.thumbTintColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
        slider.addTarget(self, action: #selector(progressTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(progressValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(progressTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
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

    private func configureOwnerNameLabel(_ label: UILabel) {
        label.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        label.font = Self.ownerNameFont
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        label.lineBreakMode = .byTruncatingTail
    }

    @objc private func progressTouchDown() {
        guard player != nil else { return }
        isScrubbing = true
        wasPlayingBeforeScrubbing = player?.timeControlStatus == .playing || (player?.rate ?? 0) > 0
        player?.pause()
        updatePlayPauseButton()
    }

    @objc private func progressValueChanged() {
        elapsedTimeLabel.text = formattedTime(Double(progressSlider.value))
    }

    @objc private func progressTouchUp() {
        guard let player else {
            isScrubbing = false
            return
        }

        let seconds = Double(progressSlider.value)
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        isScrubbing = false

        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else { return }
            self.updateProgress()

            if self.wasPlayingBeforeScrubbing {
                self.player?.play()
            }

            self.wasPlayingBeforeScrubbing = false
            self.updatePlayPauseButton()
        }
    }

    @objc private func playTapped() {
        guard let player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            let duration = currentDuration()
            let current = sanitizedSeconds(player.currentTime().seconds)

            if duration > 0, current >= duration - 0.2 {
                player.seek(to: .zero)
            }

            player.play()
        }
        updatePlayPauseButton()
    }

    @objc private func previousTapped() {
        guard tracks.count > 1 else {
            player?.seek(to: .zero)
            updateProgress()
            return
        }

        currentIndex = (currentIndex - 1 + tracks.count) % tracks.count
        configureCurrentTrack(autoplay: true)
    }

    @objc private func nextTapped() {
        guard tracks.count > 1 else {
            player?.seek(to: .zero)
            updateProgress()
            return
        }

        currentIndex = (currentIndex + 1) % tracks.count
        configureCurrentTrack(autoplay: true)
    }

    private func playerDidFinishPlaying() {
        player?.seek(to: .zero)
        updateProgress()
        updatePlayPauseButton()
    }

    private func updatePlayPauseButton() {
        let isPlaying = player?.timeControlStatus == .playing || (player?.rate ?? 0) > 0
        let imageName = isPlaying ? "play_pause_button" : "player_control_play_button"
        playPauseButton.setImage(UIImage(named: imageName), for: .normal)
        playPauseButton.accessibilityLabel = isPlaying ? "Pause" : "Play"
    }

    private func currentFavoriteItem() -> FavoriteItem {
        FavoriteItem.video(
            title: currentTrack.title,
            ownerName: currentTrack.ownerName,
            coverImageName: currentTrack.coverImageName,
            videoURL: currentTrack.videoURL,
            avatarImageName: currentTrack.avatarImageName
        )
    }

    private func isLiked() -> Bool {
        FavoriteStore.shared.isFavorite(id: currentFavoriteItem().id)
    }

    private func updateLikeButton() {
        let liked = isLiked()
        let imageName = liked ? "like_icon" : "unlike_icon"
        likeButton?.setImage(UIImage(named: imageName), for: .normal)
        likeButton?.accessibilityLabel = liked ? "Liked" : "Not Liked"
        likeCountLabel?.text = liked ? "1" : "0"
    }

    @objc private func likeTapped() {
        FavoriteStore.shared.toggle(currentFavoriteItem())
        updateLikeButton()
    }

    @objc private func addFriendTapped() {
        let message = isCurrentOwnerFriend()
            ? "You are already good friends."
            : "Friend request sent successfully."
        showNotice(message)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func reportTapped() {
        guard let hostView = navigationController?.view ?? view else { return }
        presentReportBlockPopup(in: hostView, blockedUser: currentTrack.blockedUser)
    }

    @objc private func ownerNameTapped() {
        let profileViewController = UserProfileViewController(
            displayName: currentTrack.ownerName,
            avatarImageName: currentTrack.avatarImageName
        )
        navigationController?.pushViewController(profileViewController, animated: true)
    }

    private func showNotice(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func isCurrentOwnerFriend() -> Bool {
        FriendStore.shared.isFriend(name: currentTrack.ownerName)
    }

    private func updateFriendButton() {
        let isFriend = isCurrentOwnerFriend()
        friendButton?.setTitle(isFriend ? "Good Friend" : "+ Add Friend", for: .normal)
        friendButton?.setTitleColor(isFriend ? .white : UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1), for: .normal)
        friendButton?.backgroundColor = isFriend
            ? UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
            : UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
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

    private static var ownerNameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 20) ?? .italicSystemFont(ofSize: 20)
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    private var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("PlayerView layer must be AVPlayerLayer.")
        }

        layer.videoGravity = .resizeAspectFill
        return layer
    }
}
