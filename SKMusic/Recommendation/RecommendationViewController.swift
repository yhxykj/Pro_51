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

final class RecommendationViewController: UIViewController, PHPickerViewControllerDelegate {
    private struct RecommendationSong {
        let title: String
        let artist: String
        let note: String
    }

    private let songs = [
        RecommendationSong(title: "Insula (Dirty Nano Remix)", artist: "-Annie", note: "More than 75% of people like it"),
        RecommendationSong(title: "Insula (Dirty Nano Remix)", artist: "-Annie", note: "More than 75% of people like it"),
        RecommendationSong(title: "Insula (Dirty Nano Remix)", artist: "-Annie", note: "More than 75% of people like it"),
        RecommendationSong(title: "Insula (Dirty Nano Remix)", artist: "-Annie", note: "More than 75% of people like it")
    ]
    private weak var publishCardView: PublishVideoCardView?
    private var selectedPublishVideoURL: URL?

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
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

        (0..<3).forEach { _ in
            cardStackView.addArrangedSubview(makeDailyCardView())
        }

        let styleTitleImageView = UIImageView(image: UIImage(named: "recommendation_style_title"))
        styleTitleImageView.contentMode = .scaleAspectFit
        contentView.addSubview(styleTitleImageView)

        let listStackView = UIStackView()
        listStackView.axis = .vertical
        listStackView.spacing = 12
        contentView.addSubview(listStackView)

        songs.forEach { song in
            listStackView.addArrangedSubview(makeSongCardView(song))
        }

        let bottomBarView = UIView()
        bottomBarView.backgroundColor = .white
        bottomBarView.layer.cornerRadius = 35
        bottomBarView.layer.shadowColor = UIColor.black.cgColor
        bottomBarView.layer.shadowOpacity = 0.75
        bottomBarView.layer.shadowRadius = 0
        bottomBarView.layer.shadowOffset = CGSize(width: 5, height: 5)
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
        view.addSubview(addButton)

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
            addButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let preferredCardScrollHeightConstraint = cardScrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.36)
        preferredCardScrollHeightConstraint.priority = .defaultHigh
        let minimumCardScrollHeightConstraint = cardScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        minimumCardScrollHeightConstraint.priority = .defaultHigh

        cardStackView.arrangedSubviews.forEach { cardView in
            cardView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.58),
                cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.32)
            ])
        }

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

            dailyTitleImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 70),
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
            addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor)
        ])

        view.bringSubviewToFront(backButton)
    }

    private func makeDailyCardView() -> UIView {
        let cardView = UIView()
        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 22
        cardView.isUserInteractionEnabled = true
        cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(videoCardTapped)))

        let coverImageView = UIImageView(image: UIImage(named: "video_cover"))
        coverImageView.contentMode = .scaleAspectFill
        cardView.addSubview(coverImageView)

        let likeImageView = UIImageView(image: UIImage(named: "recommendation_like_icon"))
        likeImageView.contentMode = .scaleAspectFit
        cardView.addSubview(likeImageView)

        let countLabel = UILabel()
        countLabel.text = "99+"
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

    private func makeSongCardView(_ song: RecommendationSong) -> UIView {
        let cardView = UIView()
        cardView.isUserInteractionEnabled = true
        cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(songCardTapped)))

        let backgroundImageView = UIImageView(image: UIImage(named: "recommendation_list_card_background"))
        backgroundImageView.contentMode = .scaleToFill
        cardView.addSubview(backgroundImageView)

        let albumImageView = UIImageView(image: UIImage(named: "record_disc"))
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.layer.cornerRadius = 6
        cardView.addSubview(albumImageView)

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
            albumImageView,
            titleLabel,
            artistLabel,
            noteIconImageView,
            noteLabel,
            playImageView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(equalToConstant: 78),

            backgroundImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            albumImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 11),
            albumImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor, constant: -1),
            albumImageView.widthAnchor.constraint(equalToConstant: 54),
            albumImageView.heightAnchor.constraint(equalTo: albumImageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 13),
            titleLabel.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: playImageView.leadingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 19),

            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            artistLabel.heightAnchor.constraint(equalToConstant: 17),

            noteIconImageView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            noteIconImageView.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 2),
            noteIconImageView.widthAnchor.constraint(equalToConstant: 13),
            noteIconImageView.heightAnchor.constraint(equalTo: noteIconImageView.widthAnchor),

            noteLabel.leadingAnchor.constraint(equalTo: noteIconImageView.trailingAnchor, constant: 7),
            noteLabel.centerYAnchor.constraint(equalTo: noteIconImageView.centerYAnchor),
            noteLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            noteLabel.heightAnchor.constraint(equalToConstant: 15),

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

    @objc private func videoCardTapped() {
        navigationController?.pushViewController(VideoPlayerViewController(coverImageName: "video_cover"), animated: true)
    }

    @objc private func songCardTapped() {
        navigationController?.pushViewController(AudioPlayerViewController(), animated: true)
    }

    @objc private func messageTapped() {
        switchToMainMessageTab()
    }

    @objc private func profileTapped() {
        switchToMainProfileTab()
    }

    @objc private func addTapped() {
        guard view.viewWithTag(52001) == nil else { return }

        let overlayView = UIView()
        overlayView.tag = 52001
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.50)
        let endEditingTapGesture = UITapGestureRecognizer(target: self, action: #selector(endPublishEditing))
        endEditingTapGesture.cancelsTouchesInView = false
        overlayView.addGestureRecognizer(endEditingTapGesture)
        view.addSubview(overlayView)

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
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

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
        view.viewWithTag(52001)?.removeFromSuperview()
    }

    @objc private func endPublishEditing() {
        view.endEditing(true)
    }

    @objc private func choosePublishVideoTapped() {
        view.endEditing(true)

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
        view.endEditing(true)

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
