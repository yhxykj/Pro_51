//
//  FriendsUpdateDetailViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import AVFoundation
import UIKit

final class FriendsUpdateDetailViewController: UIViewController, UITextFieldDelegate {
    fileprivate enum Layout {
        static let pinkColor = UIColor(red: 0.99, green: 0.89, blue: 0.96, alpha: 1)
        static let accentPink = UIColor(red: 0.96, green: 0.41, blue: 0.76, alpha: 1)
        static let textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        static let sideInset: CGFloat = 28
    }

    private let item: FriendsUpdateItem
    private var isPlaying = true
    private var comments: [FriendsUpdateComment]
    private var player: AVPlayer?

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let backButton = UIButton(type: .custom)
    private let headerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let headerReportButton = UIButton(type: .custom)
    private let detailTextLabel = UILabel()
    private let playerContainerView = UIView()
    private let playbackButton = UIButton(type: .custom)
    private let waveformView = FriendsUpdateWaveformView()
    private let durationLabel = UILabel()
    private let likeIconImageView = UIImageView(image: UIImage(named: "friends_updates_like_icon"))
    private let likeCountLabel = UILabel()
    private let dividerView = UIView()
    private let commentsStackView = UIStackView()
    private let inputContainerView = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .custom)

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(item: FriendsUpdateItem) {
        self.item = item
        self.comments = []
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let fallbackItem = FriendsUpdateItem(
            note: "Soothe all day’s tiredness\nwith a single song.",
            likes: "100W",
            name: "Anni",
            detailName: "Angela",
            detailText: "This is my first time sharing a joke, I ......",
            coverImageName: "friends_updates_cover_duet",
            avatarImageName: "avatar_07",
            audioResourceName: "home_michael_buble_live"
        )
        self.item = fallbackItem
        self.comments = []
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadPersistedComments()
        reloadComments()
        setupAudioPlayer()
        updatePlaybackState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        backButton.setImage(UIImage(named: "back_button"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.contentHorizontalAlignment = .fill
        backButton.contentVerticalAlignment = .fill
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        headerView.backgroundColor = .clear
        view.addSubview(headerView)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(named: item.avatarImageName)
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.borderWidth = 2
        headerView.addSubview(avatarImageView)

        nameLabel.text = item.detailName
        nameLabel.textColor = Layout.textColor
        nameLabel.font = Self.titleFont
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        headerView.addSubview(nameLabel)

        headerReportButton.setImage(UIImage(named: "friends_update_detail_report_icon"), for: .normal)
        headerReportButton.imageView?.contentMode = .scaleAspectFit
        headerReportButton.accessibilityLabel = "Report"
        headerReportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        headerView.addSubview(headerReportButton)

        detailTextLabel.text = item.detailText
        detailTextLabel.textColor = Layout.textColor
        detailTextLabel.font = Self.bodyFont
        detailTextLabel.adjustsFontSizeToFitWidth = true
        detailTextLabel.minimumScaleFactor = 0.7
        headerView.addSubview(detailTextLabel)

        playerContainerView.backgroundColor = Layout.pinkColor
        playerContainerView.layer.cornerRadius = 32
        playerContainerView.layer.shadowColor = Layout.accentPink.cgColor
        playerContainerView.layer.shadowOpacity = 0.4
        playerContainerView.layer.shadowRadius = 0
        playerContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        headerView.addSubview(playerContainerView)

        playbackButton.imageView?.contentMode = .scaleAspectFit
        playbackButton.tintColor = Layout.textColor
        playbackButton.accessibilityLabel = "Pause"
        playbackButton.addTarget(self, action: #selector(playbackTapped), for: .touchUpInside)
        playerContainerView.addSubview(playbackButton)

        waveformView.backgroundColor = .clear
        playerContainerView.addSubview(waveformView)

        durationLabel.text = "59`"
        durationLabel.textColor = Layout.textColor
        durationLabel.font = Self.titleFont
        durationLabel.textAlignment = .right
        durationLabel.adjustsFontSizeToFitWidth = true
        durationLabel.minimumScaleFactor = 0.7
        playerContainerView.addSubview(durationLabel)

        likeIconImageView.contentMode = .scaleAspectFit
        view.addSubview(likeIconImageView)

        likeCountLabel.text = item.likes
        likeCountLabel.textColor = Layout.textColor
        likeCountLabel.font = Self.likeFont
        likeCountLabel.adjustsFontSizeToFitWidth = true
        likeCountLabel.minimumScaleFactor = 0.75
        view.addSubview(likeCountLabel)

        dividerView.backgroundColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        view.addSubview(dividerView)

        commentsStackView.axis = .vertical
        commentsStackView.spacing = 14
        view.addSubview(commentsStackView)

        inputContainerView.backgroundColor = Layout.accentPink.withAlphaComponent(0.78)
        inputContainerView.layer.cornerRadius = 22.5
        inputContainerView.layer.masksToBounds = true
        view.addSubview(inputContainerView)

        messageTextField.backgroundColor = .clear
        messageTextField.textColor = Layout.textColor
        messageTextField.font = Self.inputFont
        messageTextField.delegate = self
        messageTextField.returnKeyType = .send
        messageTextField.autocorrectionType = .no
        messageTextField.attributedPlaceholder = NSAttributedString(
            string: "Please enter...",
            attributes: [
                .foregroundColor: UIColor(red: 0.44, green: 0.35, blue: 0.43, alpha: 0.75),
                .font: Self.inputFont
            ]
        )
        inputContainerView.addSubview(messageTextField)

        sendButton.setImage(UIImage(named: "chat_send_icon"), for: .normal)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.accessibilityLabel = "Send"
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            backButton,
            headerView,
            avatarImageView,
            nameLabel,
            headerReportButton,
            detailTextLabel,
            playerContainerView,
            playbackButton,
            waveformView,
            durationLabel,
            likeIconImageView,
            likeCountLabel,
            dividerView,
            commentsStackView,
            inputContainerView,
            messageTextField,
            sendButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            headerView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 15),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -23),
            headerView.heightAnchor.constraint(equalToConstant: 270),

            avatarImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 1),
            avatarImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 6),
            avatarImageView.widthAnchor.constraint(equalToConstant: 76),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 40),
            nameLabel.widthAnchor.constraint(equalToConstant: 130),
            nameLabel.heightAnchor.constraint(equalToConstant: 35),

            headerReportButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 2),
            headerReportButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 2),
            headerReportButton.widthAnchor.constraint(equalToConstant: 28),
            headerReportButton.heightAnchor.constraint(equalTo: headerReportButton.widthAnchor),

            detailTextLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 6),
            detailTextLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            detailTextLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            detailTextLabel.heightAnchor.constraint(equalToConstant: 30),

            playerContainerView.topAnchor.constraint(equalTo: detailTextLabel.bottomAnchor, constant: 22),
            playerContainerView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 0),
            playerContainerView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 0),
            playerContainerView.heightAnchor.constraint(equalToConstant: 72),

            playbackButton.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor, constant: 20),
            playbackButton.centerYAnchor.constraint(equalTo: playerContainerView.centerYAnchor),
            playbackButton.widthAnchor.constraint(equalToConstant: 52),
            playbackButton.heightAnchor.constraint(equalTo: playbackButton.widthAnchor),

            waveformView.leadingAnchor.constraint(equalTo: playbackButton.trailingAnchor, constant: 20),
            waveformView.centerYAnchor.constraint(equalTo: playerContainerView.centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: 78),
            waveformView.heightAnchor.constraint(equalToConstant: 30),

            durationLabel.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor, constant: -19),
            durationLabel.centerYAnchor.constraint(equalTo: playerContainerView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 55),
            durationLabel.heightAnchor.constraint(equalToConstant: 34),

            likeCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -29),
            likeCountLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 65),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 25),

            likeIconImageView.trailingAnchor.constraint(equalTo: likeCountLabel.leadingAnchor, constant: -4),
            likeIconImageView.centerYAnchor.constraint(equalTo: likeCountLabel.centerYAnchor),
            likeIconImageView.widthAnchor.constraint(equalToConstant: 25),
            likeIconImageView.heightAnchor.constraint(equalTo: likeIconImageView.widthAnchor),

            dividerView.topAnchor.constraint(equalTo: likeCountLabel.bottomAnchor, constant: 10),
            dividerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            dividerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -31),
            dividerView.heightAnchor.constraint(equalToConstant: 2),

            commentsStackView.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 15),
            commentsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            commentsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            inputContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -13),
            inputContainerView.heightAnchor.constraint(equalToConstant: 45),

            messageTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 22),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            messageTextField.heightAnchor.constraint(equalToConstant: 28),

            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -19),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 31),
            sendButton.heightAnchor.constraint(equalTo: sendButton.widthAnchor)
        ])

        avatarImageView.layer.cornerRadius = 38
    }

    private func reloadComments() {
        commentsStackView.arrangedSubviews.forEach { view in
            commentsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        comments.forEach { comment in
            let commentView = FriendsUpdateDetailCommentView(
                name: comment.name,
                message: comment.message,
                avatarImageName: comment.avatarImageName,
                actionImageName: comment.isOwnedByCurrentUser ? "blacklist_delete_icon" : "friends_update_detail_report_icon",
                actionAccessibilityLabel: comment.isOwnedByCurrentUser ? "Delete" : "Report"
            )
            commentView.onReport = { [weak self] in
                self?.showCommentActionSheet(for: comment)
            }
            commentsStackView.addArrangedSubview(commentView)
        }
    }

    private func loadPersistedComments() {
        let reportedIDs = loadReportedCommentIDs()
        let visibleDefaultComments = Self.defaultComments(for: item)
            .filter { !reportedIDs.contains($0.id) }
        comments = visibleDefaultComments + loadUserComments()
    }

    private var userCommentsKey: String {
        "skmusic.friendsUpdateDetail.userComments.\(item.audioResourceName)"
    }

    private var reportedCommentsKey: String {
        "skmusic.friendsUpdateDetail.reportedComments.\(item.audioResourceName)"
    }

    private func loadUserComments() -> [FriendsUpdateComment] {
        guard let data = UserDefaults.standard.data(forKey: userCommentsKey),
              let storedComments = try? JSONDecoder().decode([FriendsUpdateComment].self, from: data) else {
            return []
        }

        return storedComments
    }

    private func saveUserComments(_ comments: [FriendsUpdateComment]) {
        guard let data = try? JSONEncoder().encode(comments) else { return }
        UserDefaults.standard.set(data, forKey: userCommentsKey)
    }

    private func loadReportedCommentIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: reportedCommentsKey) ?? [])
    }

    private func saveReportedCommentIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: reportedCommentsKey)
    }

    private static func defaultComments(for item: FriendsUpdateItem) -> [FriendsUpdateComment] {
        switch item.audioResourceName {
        case "home_michael_buble_live":
            return [
                defaultComment(item, idSuffix: "luna", name: "Luna", message: "Count me in for the duet part.", avatarImageName: "avatar_10"),
                defaultComment(item, idSuffix: "evan", name: "Evan", message: "Your voices would match this song so well.", avatarImageName: "avatar_11"),
                defaultComment(item, idSuffix: "rose", name: "Rose", message: "This has such warm rehearsal-room energy.", avatarImageName: "avatar_12")
            ]
        case "i_will_be_there":
            return [
                defaultComment(item, idSuffix: "noah", name: "Noah", message: "Adding this one to my listening queue.", avatarImageName: "avatar_13"),
                defaultComment(item, idSuffix: "ivy", name: "Ivy", message: "The hook is easy to remember.", avatarImageName: "avatar_14"),
                defaultComment(item, idSuffix: "maya", name: "Maya", message: "Would love to hear a longer version.", avatarImageName: "avatar_15")
            ]
        case "liangzi_feeling_supreme":
            return [
                defaultComment(item, idSuffix: "alex", name: "Alex", message: "These vibes make me want to sing along.", avatarImageName: "avatar_16"),
                defaultComment(item, idSuffix: "nina", name: "Nina", message: "Great track for meeting music friends.", avatarImageName: "avatar_17"),
                defaultComment(item, idSuffix: "owen", name: "Owen", message: "The chorus feels bright and uplifting.", avatarImageName: "avatar_18")
            ]
        default:
            return [
                defaultComment(item, idSuffix: "luna", name: "Luna", message: "This track has a lovely energy.", avatarImageName: "avatar_10"),
                defaultComment(item, idSuffix: "evan", name: "Evan", message: "I want to hear more from this singer.", avatarImageName: "avatar_11")
            ]
        }
    }

    private static func defaultComment(
        _ item: FriendsUpdateItem,
        idSuffix: String,
        name: String,
        message: String,
        avatarImageName: String
    ) -> FriendsUpdateComment {
        FriendsUpdateComment(
            id: "\(item.audioResourceName).\(idSuffix)",
            name: name,
            message: message,
            avatarImageName: avatarImageName,
            isOwnedByCurrentUser: false
        )
    }

    private func updatePlaybackState() {
        if isPlaying {
            playbackButton.setImage(UIImage(named: "friends_update_detail_pause_button"), for: .normal)
            playbackButton.backgroundColor = .clear
            playbackButton.layer.borderWidth = 0
            playbackButton.accessibilityLabel = "Pause"
            playAudio()
            return
        }

        playbackButton.setImage(UIImage(named: "friends_update_detail_play_button"), for: .normal)
        playbackButton.backgroundColor = .clear
        playbackButton.layer.borderWidth = 0
        playbackButton.accessibilityLabel = "Play"
        player?.pause()
    }

    private func setupAudioPlayer() {
        guard let audioURL = audioURL(forResource: item.audioResourceName) else { return }

        let asset = AVURLAsset(url: audioURL)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)

        let duration = asset.duration.seconds
        if duration.isFinite, duration > 0 {
            durationLabel.text = "\(Int(duration.rounded()))`"
        }
    }

    private func playAudio() {
        guard let player else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio playback can still proceed if the session cannot be updated.
        }

        player.play()
    }

    private func audioURL(forResource resourceName: String) -> URL? {
        if let bundledURL = Bundle.main.url(forResource: resourceName, withExtension: "mp3", subdirectory: "Mp3")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "mp3") {
            return bundledURL
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }

        let fileName = "\(resourceName).mp3"
        return FileManager.default
            .enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first { $0.lastPathComponent == fileName }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }

    @objc private func playbackTapped() {
        isPlaying.toggle()
        updatePlaybackState()
    }

    @objc private func reportTapped() {
        showReportBlockPopup(for: item.blockedUser)
    }

    private func showReportBlockPopup(for blockedUser: BlockedUser) {
        guard let hostView = navigationController?.view ?? parent?.view ?? view else { return }
        presentReportBlockPopup(in: hostView, blockedUser: blockedUser)
    }

    private func showCommentActionSheet(for comment: FriendsUpdateComment) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if comment.isOwnedByCurrentUser {
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteUserComment(comment)
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: "Report", style: .destructive) { [weak self] _ in
                self?.reportComment(comment)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(actionSheet, animated: true)
    }

    private func reportComment(_ comment: FriendsUpdateComment) {
        var reportedIDs = loadReportedCommentIDs()
        reportedIDs.insert(comment.id)
        saveReportedCommentIDs(reportedIDs)
        loadPersistedComments()
        reloadComments()
        showReportReviewAlert()
    }

    private func deleteUserComment(_ comment: FriendsUpdateComment) {
        let remainingComments = loadUserComments().filter { $0.id != comment.id }
        saveUserComments(remainingComments)
        loadPersistedComments()
        reloadComments()
    }

    private func showReportReviewAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "Report submitted successfully. We will review it within 24 hours.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func sendTapped() {
        let trimmedText = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedText.isEmpty else {
            messageTextField.resignFirstResponder()
            return
        }

        let userComment = FriendsUpdateComment(
            id: UUID().uuidString,
            name: "You",
            message: trimmedText,
            avatarImageName: "avatar_19",
            isOwnedByCurrentUser: true
        )
        var storedComments = loadUserComments()
        storedComments.append(userComment)
        saveUserComments(storedComments)
        loadPersistedComments()
        reloadComments()
        messageTextField.text = nil
        messageTextField.resignFirstResponder()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 28) ?? .italicSystemFont(ofSize: 28)
    }

    private static var bodyFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 17) ?? .italicSystemFont(ofSize: 17)
    }

    private static var likeFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 18) ?? .italicSystemFont(ofSize: 18)
    }

    private static var inputFont: UIFont {
        UIFont(name: "AvenirNext-BoldItalic", size: 15) ?? .italicSystemFont(ofSize: 15)
    }
}

private struct FriendsUpdateComment: Codable, Equatable {
    let id: String
    let name: String
    let message: String
    let avatarImageName: String
    let isOwnedByCurrentUser: Bool
}

private final class FriendsUpdateDetailCommentView: UIView {
    var onReport: (() -> Void)?

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let reportButton = UIButton(type: .custom)

    init(
        name: String,
        message: String,
        avatarImageName: String,
        actionImageName: String,
        actionAccessibilityLabel: String
    ) {
        super.init(frame: .zero)
        setupViews(
            name: name,
            message: message,
            avatarImageName: avatarImageName,
            actionImageName: actionImageName,
            actionAccessibilityLabel: actionAccessibilityLabel
        )
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews(
            name: "Angela",
            message: "This track has a lovely energy.",
            avatarImageName: "avatar_10",
            actionImageName: "friends_update_detail_report_icon",
            actionAccessibilityLabel: "Report"
        )
        setupConstraints()
    }

    private func setupViews(
        name: String,
        message: String,
        avatarImageName: String,
        actionImageName: String,
        actionAccessibilityLabel: String
    ) {
        backgroundColor = FriendsUpdateDetailViewController.Layout.pinkColor
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.68, green: 0.68, blue: 0.68, alpha: 1).cgColor
        clipsToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(named: avatarImageName)
        avatarImageView.clipsToBounds = true
        addSubview(avatarImageView)

        nameLabel.text = name
        nameLabel.textColor = FriendsUpdateDetailViewController.Layout.textColor
        nameLabel.font = Self.nameFont
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        addSubview(nameLabel)

        messageLabel.text = message
        messageLabel.textColor = nameLabel.textColor
        messageLabel.font = Self.messageFont
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.7
        addSubview(messageLabel)

        reportButton.setImage(UIImage(named: actionImageName), for: .normal)
        reportButton.imageView?.contentMode = .scaleAspectFit
        reportButton.accessibilityLabel = actionAccessibilityLabel
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        addSubview(reportButton)
    }

    private func setupConstraints() {
        [
            avatarImageView,
            nameLabel,
            messageLabel,
            reportButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 65),

            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 54),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            nameLabel.widthAnchor.constraint(equalToConstant: 82),
            nameLabel.heightAnchor.constraint(equalToConstant: 24),

            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 0),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -78),
            messageLabel.heightAnchor.constraint(equalToConstant: 22),

            reportButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            reportButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            reportButton.widthAnchor.constraint(equalToConstant: 32),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor)
        ])

        avatarImageView.layer.cornerRadius = 27
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 17) ?? .italicSystemFont(ofSize: 17)
    }

    private static var messageFont: UIFont {
        UIFont(name: "AvenirNext-BoldItalic", size: 12) ?? .italicSystemFont(ofSize: 12)
    }

    @objc private func reportTapped() {
        onReport?()
    }
}

private final class FriendsUpdateWaveformView: UIView {
    private let barHeights: [CGFloat] = [5, 12, 20, 13, 24, 15, 8, 19, 26, 14, 9, 18, 12, 7]

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1).cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)

        let centerY = rect.midY
        let spacing = rect.width / CGFloat(max(barHeights.count - 1, 1))

        barHeights.enumerated().forEach { index, height in
            let x = CGFloat(index) * spacing
            context.move(to: CGPoint(x: x, y: centerY - height / 2))
            context.addLine(to: CGPoint(x: x, y: centerY + height / 2))
        }

        context.strokePath()
    }
}
