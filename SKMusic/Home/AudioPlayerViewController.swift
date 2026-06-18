//
//  AudioPlayerViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import AVFoundation
import UIKit

final class AudioPlayerViewController: UIViewController {
    private let audioURL: URL?
    private let friendState: FriendState
    private var player: AVPlayer?

    private enum FriendState {
        case add
        case good
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(audioURL: URL? = nil, isGoodFriend: Bool = false) {
        self.audioURL = audioURL
        self.friendState = isGoodFriend ? .good : .add
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.audioURL = nil
        self.friendState = .add
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

        let reportButton = UIButton(type: .custom)
        configureImageButton(reportButton, imageName: "report_icon", accessibilityLabel: "Report")
        view.addSubview(reportButton)

        let songTitleImageView = UIImageView(image: UIImage(named: "song_title_head_clouds"))
        let artistImageView = UIImageView(image: UIImage(named: "artist_annie"))
        [songTitleImageView, artistImageView].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
        }

        let friendButton = makeFriendButton()
        view.addSubview(friendButton)

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
        playPauseButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)

        let controlsStackView = UIStackView()
        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.distribution = .equalSpacing
        [repeatButton, previousButton, playPauseButton, nextButton, commentButton].forEach { controlsStackView.addArrangedSubview($0) }
        view.addSubview(controlsStackView)

        let commentCountLabel = UILabel()
        configureCountLabel(commentCountLabel)
        commentCountLabel.text = "99+"
        view.addSubview(commentCountLabel)

        [
            backgroundImageView,
            backButton,
            headerTitleImageView,
            discHaloView,
            discImageView,
            reportButton,
            songTitleImageView,
            artistImageView,
            friendButton,
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

            reportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            reportButton.topAnchor.constraint(equalTo: discImageView.bottomAnchor, constant: -38),
            reportButton.widthAnchor.constraint(equalToConstant: 34),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor),

            songTitleImageView.topAnchor.constraint(equalTo: discImageView.bottomAnchor, constant: 28),
            songTitleImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            songTitleImageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.76),
            songTitleImageView.heightAnchor.constraint(equalToConstant: 40),

            artistImageView.topAnchor.constraint(equalTo: songTitleImageView.bottomAnchor, constant: 2),
            artistImageView.leadingAnchor.constraint(equalTo: songTitleImageView.leadingAnchor),
            artistImageView.widthAnchor.constraint(equalToConstant: 70),
            artistImageView.heightAnchor.constraint(equalToConstant: 31),

            friendButton.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
            friendButton.leadingAnchor.constraint(equalTo: artistImageView.trailingAnchor, constant: 16),
            friendButton.widthAnchor.constraint(equalToConstant: 112),
            friendButton.heightAnchor.constraint(equalToConstant: 22),

            likeButton.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -52),
            likeButton.widthAnchor.constraint(equalToConstant: 45),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor, constant: 8),
            likeCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 36),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 18),

            progressSlider.topAnchor.constraint(equalTo: artistImageView.bottomAnchor, constant: 27),
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
            controlsStackView.widthAnchor.constraint(equalTo: progressSlider.widthAnchor),
            controlsStackView.heightAnchor.constraint(equalToConstant: 58),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            commentCountLabel.leadingAnchor.constraint(equalTo: commentButton.trailingAnchor, constant: -5),
            commentCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: progressSlider.trailingAnchor),
            commentCountLabel.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor, constant: 11),
            commentCountLabel.widthAnchor.constraint(equalToConstant: 39),
            commentCountLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func setupPlayerIfNeeded() {
        guard let audioURL else { return }

        player = AVPlayer(url: audioURL)
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
