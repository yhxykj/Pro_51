//
//  VideoPlayerViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import AVFoundation
import UIKit

final class VideoPlayerViewController: UIViewController {
    private let videoURL: URL?
    private let coverImageName: String
    private let playerView = PlayerView()
    private let coverImageView = UIImageView()
    private let playPauseButton = UIButton(type: .custom)
    private var player: AVPlayer?

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(videoURL: URL? = nil, coverImageName: String = "video_cover") {
        self.videoURL = videoURL
        self.coverImageName = coverImageName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.videoURL = nil
        self.coverImageName = "video_cover"
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupPlayerIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
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
        view.addSubview(reportButton)

        let mediaContainerView = UIView()
        mediaContainerView.backgroundColor = .black
        mediaContainerView.clipsToBounds = true
        mediaContainerView.layer.cornerRadius = 18
        view.addSubview(mediaContainerView)

        playerView.backgroundColor = .black
        mediaContainerView.addSubview(playerView)

        coverImageView.image = UIImage(named: coverImageName)
        coverImageView.contentMode = .scaleAspectFill
        mediaContainerView.addSubview(coverImageView)

        let songTitleImageView = UIImageView(image: UIImage(named: "song_title_head_clouds"))
        let artistImageView = UIImageView(image: UIImage(named: "artist_annie"))
        [songTitleImageView, artistImageView].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
        }

        let addFriendButton = UIButton(type: .custom)
        addFriendButton.backgroundColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
        addFriendButton.layer.cornerRadius = 11
        addFriendButton.setTitle("+ Add Friend", for: .normal)
        addFriendButton.setTitleColor(UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1), for: .normal)
        addFriendButton.titleLabel?.font = Self.friendButtonFont
        addFriendButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addFriendButton.titleLabel?.minimumScaleFactor = 0.78
        view.addSubview(addFriendButton)

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
        let nextButton = UIButton(type: .custom)
        let commentButton = UIButton(type: .custom)
        configureImageButton(repeatButton, imageName: "repeat_one_button", accessibilityLabel: "Repeat")
        configureImageButton(previousButton, imageName: "previous_button", accessibilityLabel: "Previous")
        configureImageButton(playPauseButton, imageName: "play_pause_button", accessibilityLabel: "Play")
        configureImageButton(nextButton, imageName: "next_button", accessibilityLabel: "Next")
        configureImageButton(commentButton, imageName: "comment_icon", accessibilityLabel: "Comment")
        playPauseButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
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

        [
            backgroundImageView,
            headerTitleImageView,
            backButton,
            reportButton,
            mediaContainerView,
            playerView,
            coverImageView,
            songTitleImageView,
            artistImageView,
            addFriendButton,
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

        [repeatButton, previousButton, playPauseButton, nextButton, commentButton].forEach { button in
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

            artistImageView.topAnchor.constraint(equalTo: songTitleImageView.bottomAnchor, constant: 2),
            artistImageView.leadingAnchor.constraint(equalTo: songTitleImageView.leadingAnchor),
            artistImageView.widthAnchor.constraint(equalToConstant: 70),
            artistImageView.heightAnchor.constraint(equalToConstant: 31),

            addFriendButton.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
            addFriendButton.leadingAnchor.constraint(equalTo: artistImageView.trailingAnchor, constant: 16),
            addFriendButton.widthAnchor.constraint(equalToConstant: 112),
            addFriendButton.heightAnchor.constraint(equalToConstant: 22),

            likeButton.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor, constant: -24),
            likeButton.widthAnchor.constraint(equalToConstant: 45),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor, constant: 8),
            likeCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: mediaContainerView.trailingAnchor),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 36),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 18),

            progressSlider.topAnchor.constraint(equalTo: artistImageView.bottomAnchor, constant: 22),
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
            controlsStackView.widthAnchor.constraint(equalTo: mediaContainerView.widthAnchor),
            controlsStackView.heightAnchor.constraint(equalToConstant: 58),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            commentCountLabel.leadingAnchor.constraint(equalTo: commentButton.trailingAnchor, constant: -5),
            commentCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: mediaContainerView.trailingAnchor),
            commentCountLabel.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor, constant: 11),
            commentCountLabel.widthAnchor.constraint(equalToConstant: 39),
            commentCountLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func setupPlayerIfNeeded() {
        guard let videoURL else {
            playerView.isHidden = true
            return
        }

        let player = AVPlayer(url: videoURL)
        self.player = player
        playerView.player = player
        coverImageView.isHidden = true
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

    @objc private func playTapped() {
        guard let player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func messageTapped() {
        switchToMainMessageTab()
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
