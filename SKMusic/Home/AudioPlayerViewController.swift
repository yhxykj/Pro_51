//
//  AudioPlayerViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import AVFoundation
import UIKit

struct AudioPlayerTrack {
    let title: String
    let artist: String
    let audioURL: URL?
    let avatarImageName: String

    init(title: String, artist: String, audioURL: URL?, avatarImageName: String = "avatar_01") {
        self.title = title
        self.artist = artist
        self.audioURL = audioURL
        self.avatarImageName = avatarImageName
    }

    var blockedUser: BlockedUser {
        BlockedUser(identifier: artist, displayName: artist, avatarImageName: avatarImageName)
    }
}

final class AudioPlayerViewController: UIViewController {
    private let tracks: [AudioPlayerTrack]
    private var currentIndex: Int
    private let friendState: FriendState
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemEndObserver: NSObjectProtocol?
    private var isSeekingProgress = false
    private weak var songTitleLabel: UILabel?
    private weak var artistNameLabel: UILabel?
    private weak var progressSlider: UISlider?
    private weak var elapsedTimeLabel: UILabel?
    private weak var totalTimeLabel: UILabel?
    private weak var playPauseButton: UIButton?
    private weak var likeButton: UIButton?
    private weak var artistAvatarButton: UIButton?

    private enum FriendState {
        case add
        case good
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(audioURL: URL? = nil, isGoodFriend: Bool = false) {
        self.tracks = [
            AudioPlayerTrack(title: "Head Clouds", artist: "Annie", audioURL: audioURL)
        ]
        self.currentIndex = 0
        self.friendState = isGoodFriend ? .good : .add
        super.init(nibName: nil, bundle: nil)
    }

    init(tracks: [AudioPlayerTrack], initialIndex: Int, isGoodFriend: Bool = false) {
        let preparedTracks = tracks.isEmpty
            ? [AudioPlayerTrack(title: "Head Clouds", artist: "Annie", audioURL: nil)]
            : tracks
        self.tracks = preparedTracks
        self.currentIndex = min(max(initialIndex, 0), preparedTracks.count - 1)
        self.friendState = isGoodFriend ? .good : .add
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.tracks = [
            AudioPlayerTrack(title: "Head Clouds", artist: "Annie", audioURL: nil)
        ]
        self.currentIndex = 0
        self.friendState = .add
        super.init(coder: coder)
    }

    deinit {
        removePlayerObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupPlayerIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playLoadedAudio()
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

        let backButton = UIButton(type: .custom)
        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let headerTitleImageView = UIImageView(image: UIImage(named: "audio_player_title"))
        headerTitleImageView.contentMode = .scaleAspectFit
        view.addSubview(headerTitleImageView)

        let discHaloView = UIView()
        discHaloView.backgroundColor = UIColor.white.withAlphaComponent(0.36)
        discHaloView.layer.cornerRadius = 132
        view.addSubview(discHaloView)

        let discImageView = UIImageView(image: UIImage(named: "record_disc"))
        discImageView.contentMode = .scaleAspectFit
        view.addSubview(discImageView)

        let artistAvatarButton = UIButton(type: .custom)
        artistAvatarButton.setImage(UIImage(named: tracks[currentIndex].avatarImageName), for: .normal)
        artistAvatarButton.imageView?.contentMode = .scaleAspectFill
        artistAvatarButton.imageView?.clipsToBounds = true
        artistAvatarButton.contentHorizontalAlignment = .fill
        artistAvatarButton.contentVerticalAlignment = .fill
        artistAvatarButton.clipsToBounds = true
        artistAvatarButton.layer.borderColor = UIColor.white.cgColor
        artistAvatarButton.layer.borderWidth = 4
        artistAvatarButton.accessibilityLabel = "User profile"
        artistAvatarButton.addTarget(self, action: #selector(artistProfileTapped), for: .touchUpInside)
        view.addSubview(artistAvatarButton)
        self.artistAvatarButton = artistAvatarButton

        let reportButton = UIButton(type: .custom)
        configureImageButton(reportButton, imageName: "report_icon", accessibilityLabel: "Report")
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        view.addSubview(reportButton)

        let songTitleLabel = UILabel()
        configureSongTitleLabel(songTitleLabel)
        view.addSubview(songTitleLabel)
        self.songTitleLabel = songTitleLabel

        let artistNameLabel = UILabel()
        configureArtistNameLabel(artistNameLabel)
        artistNameLabel.isUserInteractionEnabled = true
        artistNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(artistProfileTapped)))
        view.addSubview(artistNameLabel)
        self.artistNameLabel = artistNameLabel

        let friendButton = makeFriendButton()
        view.addSubview(friendButton)

        let likeButton = UIButton(type: .custom)
        configureImageButton(likeButton, imageName: "unlike_icon", accessibilityLabel: "Not Liked")
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        view.addSubview(likeButton)
        self.likeButton = likeButton

        let likeCountLabel = UILabel()
        configureCountLabel(likeCountLabel)
        likeCountLabel.text = "99+"
        view.addSubview(likeCountLabel)

        let progressSlider = UISlider()
        configureProgressSlider(progressSlider)
        progressSlider.addTarget(self, action: #selector(progressTouchDown(_:)), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(progressValueChanged(_:)), for: .valueChanged)
        progressSlider.addTarget(
            self,
            action: #selector(progressTouchEnded(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        view.addSubview(progressSlider)
        self.progressSlider = progressSlider

        let elapsedTimeLabel = UILabel()
        let totalTimeLabel = UILabel()
        configureTimeLabel(elapsedTimeLabel, text: "00:00", alignment: .left)
        configureTimeLabel(totalTimeLabel, text: "00:00", alignment: .right)
        view.addSubview(elapsedTimeLabel)
        view.addSubview(totalTimeLabel)
        self.elapsedTimeLabel = elapsedTimeLabel
        self.totalTimeLabel = totalTimeLabel

        let previousButton = UIButton(type: .custom)
        let playPauseButton = UIButton(type: .custom)
        let nextButton = UIButton(type: .custom)
        configureImageButton(previousButton, imageName: "previous_button", accessibilityLabel: "Previous")
        configureImageButton(playPauseButton, imageName: "play_pause_button", accessibilityLabel: "Play")
        configureImageButton(nextButton, imageName: "next_button", accessibilityLabel: "Next")
        playPauseButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        self.playPauseButton = playPauseButton

        let controlsStackView = UIStackView()
        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.distribution = .equalSpacing
        [previousButton, playPauseButton, nextButton].forEach { controlsStackView.addArrangedSubview($0) }
        view.addSubview(controlsStackView)

        [
            backgroundImageView,
            backButton,
            headerTitleImageView,
            discHaloView,
            discImageView,
            artistAvatarButton,
            reportButton,
            songTitleLabel,
            artistNameLabel,
            friendButton,
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

        let discSizeConstraint = discImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.68)
        discSizeConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.centerYAnchor.constraint(equalTo: headerTitleImageView.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 29),

            headerTitleImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerTitleImageView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            headerTitleImageView.widthAnchor.constraint(equalToConstant: 138),
            headerTitleImageView.heightAnchor.constraint(equalToConstant: 36),

            discImageView.topAnchor.constraint(equalTo: headerTitleImageView.bottomAnchor, constant: 46),
            discImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            discImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            discSizeConstraint,
            discImageView.heightAnchor.constraint(equalTo: discImageView.widthAnchor),

            discHaloView.centerXAnchor.constraint(equalTo: discImageView.centerXAnchor),
            discHaloView.centerYAnchor.constraint(equalTo: discImageView.centerYAnchor),
            discHaloView.widthAnchor.constraint(equalTo: discImageView.widthAnchor, constant: 54),
            discHaloView.heightAnchor.constraint(equalTo: discHaloView.widthAnchor),

            artistAvatarButton.centerXAnchor.constraint(equalTo: discImageView.centerXAnchor),
            artistAvatarButton.centerYAnchor.constraint(equalTo: discImageView.centerYAnchor),
            artistAvatarButton.widthAnchor.constraint(equalToConstant: 154),
            artistAvatarButton.heightAnchor.constraint(equalTo: artistAvatarButton.widthAnchor),

            reportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            reportButton.topAnchor.constraint(equalTo: discImageView.bottomAnchor, constant: -38),
            reportButton.widthAnchor.constraint(equalToConstant: 34),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor),

            songTitleLabel.topAnchor.constraint(equalTo: discImageView.bottomAnchor, constant: 28),
            songTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            songTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -31),
            songTitleLabel.heightAnchor.constraint(equalToConstant: 40),

            artistNameLabel.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 0),
            artistNameLabel.leadingAnchor.constraint(equalTo: songTitleLabel.leadingAnchor),
            artistNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150),
            artistNameLabel.heightAnchor.constraint(equalToConstant: 31),

            friendButton.centerYAnchor.constraint(equalTo: artistNameLabel.centerYAnchor),
            friendButton.leadingAnchor.constraint(equalTo: artistNameLabel.trailingAnchor, constant: 16),
            friendButton.trailingAnchor.constraint(lessThanOrEqualTo: likeButton.leadingAnchor, constant: -12),
            friendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 86),
            friendButton.widthAnchor.constraint(lessThanOrEqualToConstant: 112),
            friendButton.heightAnchor.constraint(equalToConstant: 22),

            likeButton.centerYAnchor.constraint(equalTo: artistNameLabel.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -52),
            likeButton.widthAnchor.constraint(equalToConstant: 45),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor, constant: 8),
            likeCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 36),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 18),

            progressSlider.topAnchor.constraint(equalTo: artistNameLabel.bottomAnchor, constant: 27),
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 39),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -39),
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
            controlsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsStackView.widthAnchor.constraint(equalToConstant: 220),
            controlsStackView.widthAnchor.constraint(lessThanOrEqualTo: progressSlider.widthAnchor),
            controlsStackView.heightAnchor.constraint(equalToConstant: 58),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        artistAvatarButton.layer.cornerRadius = 77
    }

    private func setupPlayerIfNeeded() {
        loadTrack(at: currentIndex, shouldPlay: false)
    }

    private func loadTrack(at index: Int, shouldPlay: Bool) {
        guard tracks.indices.contains(index) else { return }

        removePlayerObservers()
        currentIndex = index

        let track = tracks[index]
        songTitleLabel?.text = track.title
        artistNameLabel?.text = track.artist
        artistAvatarButton?.setImage(UIImage(named: track.avatarImageName), for: .normal)
        updateLikeButton()
        resetProgress()

        guard let audioURL = track.audioURL else {
            player = nil
            updatePlayPauseButton()
            return
        }

        let asset = AVURLAsset(url: audioURL)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        refreshDuration(from: playerItem)
        addPeriodicTimeObserver(to: player)
        observeEnd(of: playerItem)

        if shouldPlay {
            playLoadedAudio(restart: true)
        } else {
            updatePlayPauseButton()
        }
    }

    private func playLoadedAudio(restart: Bool = false) {
        guard let player else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Playback can still work if the session cannot be configured.
        }

        if restart {
            player.seek(to: .zero)
            resetProgress()
        }
        player.play()
        updatePlayPauseButton()
    }

    private func resetProgress() {
        progressSlider?.minimumValue = 0
        progressSlider?.maximumValue = 1
        progressSlider?.value = 0
        elapsedTimeLabel?.text = "00:00"
        totalTimeLabel?.text = "00:00"
    }

    private func addPeriodicTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.syncProgress(with: time)
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.nextTapped()
        }
    }

    private func removePlayerObservers() {
        if let timeObserverToken, let player {
            player.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil

        if let itemEndObserver {
            NotificationCenter.default.removeObserver(itemEndObserver)
        }
        itemEndObserver = nil
    }

    private func syncProgress(with time: CMTime) {
        guard let item = player?.currentItem else { return }

        refreshDuration(from: item)
        let duration = seconds(from: item.duration)
        let currentSeconds = seconds(from: time)
        elapsedTimeLabel?.text = formatTime(currentSeconds)

        guard !isSeekingProgress else { return }
        let sliderMax = progressSlider?.maximumValue ?? 1
        progressSlider?.value = min(Float(currentSeconds), sliderMax)
    }

    private func refreshDuration(from item: AVPlayerItem) {
        let duration = seconds(from: item.duration)
        if duration > 0 {
            progressSlider?.maximumValue = Float(duration)
            totalTimeLabel?.text = formatTime(duration)
        }
    }

    private func seconds(from time: CMTime) -> Double {
        let seconds = time.seconds
        return seconds.isFinite && seconds > 0 ? seconds : 0
    }

    private func formatTime(_ seconds: Double) -> String {
        let safeSeconds = max(0, Int(seconds.rounded()))
        return String(format: "%02d:%02d", safeSeconds / 60, safeSeconds % 60)
    }

    private func updatePlayPauseButton() {
        let isPlaying = player?.timeControlStatus == .playing || (player?.rate ?? 0) > 0
        let imageName = isPlaying ? "play_pause_button" : "player_control_play_button"
        playPauseButton?.setImage(UIImage(named: imageName), for: .normal)
        playPauseButton?.accessibilityLabel = isPlaying ? "Pause" : "Play"
    }

    private func currentLikeStorageKey() -> String {
        let track = tracks[currentIndex]
        let identifier = track.audioURL?.lastPathComponent ?? "\(track.title)-\(track.artist)"
        return "skmusic.audioPlayer.liked.\(identifier)"
    }

    private func isCurrentTrackLiked() -> Bool {
        UserDefaults.standard.bool(forKey: currentLikeStorageKey())
    }

    private func updateLikeButton() {
        let isLiked = isCurrentTrackLiked()
        let imageName = isLiked ? "like_icon" : "unlike_icon"
        likeButton?.setImage(UIImage(named: imageName), for: .normal)
        likeButton?.accessibilityLabel = isLiked ? "Liked" : "Not Liked"
    }

    private func makeFriendButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 11
        button.setTitle(friendState == .add ? "+ Add Friend" : "Good Friend", for: .normal)
        button.setTitleColor(friendState == .add ? UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1) : .white, for: .normal)
        button.backgroundColor = friendState == .add
            ? UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
            : UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        button.titleLabel?.font = Self.friendButtonFont
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78
        button.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
        return button
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

    private func configureSongTitleLabel(_ label: UILabel) {
        label.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        label.font = Self.songTitleFont
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.48
        label.lineBreakMode = .byTruncatingTail
    }

    private func configureArtistNameLabel(_ label: UILabel) {
        label.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        label.font = Self.artistNameFont
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        label.lineBreakMode = .byTruncatingTail
    }

    @objc private func playTapped() {
        guard let player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            playLoadedAudio()
        }
        updatePlayPauseButton()
    }

    @objc private func likeTapped() {
        let newValue = !isCurrentTrackLiked()
        let key = currentLikeStorageKey()

        if newValue {
            UserDefaults.standard.set(true, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }

        updateLikeButton()
    }

    @objc private func addFriendTapped() {
        let message = friendState == .add
            ? "Friend request sent successfully."
            : "You are already good friends."
        showNotice(message)
    }

    @objc private func previousTapped() {
        guard !tracks.isEmpty else { return }

        if tracks.count == 1 {
            playLoadedAudio(restart: true)
            return
        }

        let previousIndex = (currentIndex - 1 + tracks.count) % tracks.count
        loadTrack(at: previousIndex, shouldPlay: true)
    }

    @objc private func nextTapped() {
        guard !tracks.isEmpty else { return }

        if tracks.count == 1 {
            playLoadedAudio(restart: true)
            return
        }

        let nextIndex = (currentIndex + 1) % tracks.count
        loadTrack(at: nextIndex, shouldPlay: true)
    }

    @objc private func progressTouchDown(_ slider: UISlider) {
        isSeekingProgress = true
    }

    @objc private func progressValueChanged(_ slider: UISlider) {
        elapsedTimeLabel?.text = formatTime(Double(slider.value))
    }

    @objc private func progressTouchEnded(_ slider: UISlider) {
        let seconds = Double(slider.value)
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSeekingProgress = false
                self.elapsedTimeLabel?.text = self.formatTime(seconds)
            }
        }

        if player == nil {
            isSeekingProgress = false
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func reportTapped() {
        guard let hostView = navigationController?.view ?? view else { return }
        presentReportBlockPopup(in: hostView, blockedUser: tracks[currentIndex].blockedUser)
    }

    @objc private func artistProfileTapped() {
        guard tracks.indices.contains(currentIndex) else { return }

        let track = tracks[currentIndex]
        let profileViewController = UserProfileViewController(
            displayName: track.artist,
            avatarImageName: track.avatarImageName,
            featuredTrack: track
        )
        navigationController?.pushViewController(profileViewController, animated: true)
    }

    private func showNotice(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

    private static var songTitleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 27) ?? .italicSystemFont(ofSize: 27)
    }

    private static var artistNameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 20) ?? .italicSystemFont(ofSize: 20)
    }
}
