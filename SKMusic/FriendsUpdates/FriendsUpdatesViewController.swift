//
//  FriendsUpdatesViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import UIKit

enum FriendsUpdateMediaKind {
    case audio
    case video

    var label: String {
        switch self {
        case .audio:
            return "Audio"
        case .video:
            return "Video"
        }
    }
}

struct FriendsUpdateItem {
    let mediaKind: FriendsUpdateMediaKind
    let title: String
    let note: String
    let likes: String
    let name: String
    let detailName: String
    let detailText: String
    let coverImageName: String
    let avatarImageName: String
    let audioResourceName: String?
    let videoResourceName: String?

    var blockedUser: BlockedUser {
        BlockedUser(identifier: detailName, displayName: detailName, avatarImageName: avatarImageName)
    }

    var storageResourceName: String {
        audioResourceName ?? videoResourceName ?? title
    }
}

final class FriendsUpdatesViewController: UIViewController {
    private enum Layout {
        static let horizontalInset: CGFloat = 23
        static let bannerTopOffset: CGFloat = 6
        static let bannerAspectRatio: CGFloat = 324 / 689
        static let cardHeight: CGFloat = 142
        static let cardSpacing: CGFloat = 19
    }

    private let updates = FriendsUpdateData.items

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let bannerContainerView = UIView()
    private let bannerImageView = UIImageView(image: UIImage(named: "friends_updates_banner"))
    private let titleImageView = UIImageView(image: UIImage(named: "friends_updates_title"))
    private let cardsStackView = UIStackView()
    private let emptyStateContainerView = UIView()
    private let emptyStateImageView = UIImageView(image: UIImage(named: "huaban-5102107231"))
    private let emptyStateLabel = UILabel()

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        reloadCards()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(blockedUsersDidChange),
            name: .blockedUsersDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCards()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        bannerContainerView.backgroundColor = .clear
        bannerContainerView.isUserInteractionEnabled = true
        bannerContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bannerTapped)))
        contentView.addSubview(bannerContainerView)

        bannerImageView.contentMode = .scaleToFill
        bannerContainerView.addSubview(bannerImageView)

        titleImageView.contentMode = .scaleAspectFit
        bannerContainerView.addSubview(titleImageView)

        cardsStackView.axis = .vertical
        cardsStackView.spacing = Layout.cardSpacing
        contentView.addSubview(cardsStackView)

        emptyStateContainerView.isHidden = true
        emptyStateContainerView.isUserInteractionEnabled = false
        contentView.addSubview(emptyStateContainerView)

        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateContainerView.addSubview(emptyStateImageView)

        emptyStateLabel.text = "No friend updates yet"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        emptyStateLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
        emptyStateContainerView.addSubview(emptyStateLabel)
    }

    private func reloadCards() {
        cardsStackView.arrangedSubviews.forEach { view in
            cardsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let visibleUpdates = updates
            .filter { !BlockedUserStore.shared.isBlocked(identifier: $0.blockedUser.identifier) }

        emptyStateContainerView.isHidden = !visibleUpdates.isEmpty

        visibleUpdates.forEach { item in
            let cardView = FriendsUpdateCardView(item: item)
            cardView.onTap = { [weak self] in
                self?.openDetail(for: item)
            }
            cardView.onReport = { [weak self] in
                self?.showReportBlockPopup(for: item)
            }
            cardsStackView.addArrangedSubview(cardView)
        }
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            scrollView,
            contentView,
            bannerContainerView,
            bannerImageView,
            titleImageView,
            cardsStackView,
            emptyStateContainerView,
            emptyStateImageView,
            emptyStateLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            bannerContainerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: Layout.bannerTopOffset),
            bannerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            bannerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            bannerContainerView.heightAnchor.constraint(equalTo: bannerContainerView.widthAnchor, multiplier: Layout.bannerAspectRatio),

            bannerImageView.topAnchor.constraint(equalTo: bannerContainerView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: bannerContainerView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: bannerContainerView.trailingAnchor),
            bannerImageView.bottomAnchor.constraint(equalTo: bannerContainerView.bottomAnchor),

            titleImageView.topAnchor.constraint(equalTo: bannerContainerView.topAnchor, constant: 10),
            titleImageView.leadingAnchor.constraint(equalTo: bannerContainerView.leadingAnchor, constant: 13),
            titleImageView.widthAnchor.constraint(equalToConstant: 172),
            titleImageView.heightAnchor.constraint(equalToConstant: 36),

            cardsStackView.topAnchor.constraint(equalTo: bannerContainerView.bottomAnchor, constant: 20),
            cardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            cardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            cardsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -144),

            emptyStateContainerView.topAnchor.constraint(equalTo: bannerContainerView.bottomAnchor, constant: 48),
            emptyStateContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyStateContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.72),
            emptyStateContainerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -144),

            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateContainerView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 156),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 143),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 15),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateContainerView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateContainerView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateContainerView.bottomAnchor),
            emptyStateLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func openDetail(for item: FriendsUpdateItem) {
        let navigationController = navigationController ?? parent?.navigationController

        switch item.mediaKind {
        case .audio:
            navigationController?.pushViewController(FriendsUpdateDetailViewController(item: item), animated: true)
        case .video:
            let track = VideoPlayerTrack(
                title: item.title,
                videoURL: FriendsUpdateData.videoURL(for: item),
                coverImageName: item.coverImageName,
                ownerName: item.detailName,
                avatarImageName: item.avatarImageName
            )
            navigationController?.pushViewController(VideoPlayerViewController(tracks: [track]), animated: true)
        }
    }

    @objc private func bannerTapped() {
        let listViewController = FriendsUpdateListViewController(items: updates)
        (navigationController ?? parent?.navigationController)?.pushViewController(listViewController, animated: true)
    }

    @objc private func blockedUsersDidChange() {
        reloadCards()
    }

    private func showReportBlockPopup(for item: FriendsUpdateItem) {
        guard let hostView = navigationController?.view ?? parent?.view ?? view else { return }
        presentReportBlockPopup(in: hostView, blockedUser: item.blockedUser)
    }
}

private final class FriendsUpdateCardView: UIView {
    var onTap: (() -> Void)?
    var onReport: (() -> Void)?

    private let photoImageView = UIImageView()
    private let noteLabel = UILabel()
    private let likeIconImageView = UIImageView(image: UIImage(named: "friends_updates_like_icon"))
    private let likeCountLabel = UILabel()
    private let commentIconImageView = UIImageView(image: UIImage(named: "friends_updates_comment_icon"))
    private let reportButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()

    init(item: FriendsUpdateItem) {
        super.init(frame: .zero)
        setupViews(item: item)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews(item: FriendsUpdateItem(
            mediaKind: .audio,
            title: "Soothe All Day",
            note: "Soothe all day’s tiredness\nwith a single song.",
            likes: "100W",
            name: "Anni",
            detailName: "Angela",
            detailText: "This is my first time sharing a joke, I ......",
            coverImageName: "friends_updates_cover_duet",
            avatarImageName: "avatar_07",
            audioResourceName: "home_michael_buble_live",
            videoResourceName: nil
        ))
        setupConstraints()
    }

    private func setupViews(item: FriendsUpdateItem) {
        backgroundColor = .white
        isUserInteractionEnabled = true
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1).cgColor
        clipsToBounds = true

        photoImageView.contentMode = .scaleAspectFill
        photoImageView.image = UIImage(named: item.coverImageName)
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 3
        addSubview(photoImageView)

        noteLabel.text = item.note
        noteLabel.numberOfLines = 2
        noteLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        noteLabel.font = Self.noteFont
        noteLabel.adjustsFontSizeToFitWidth = true
        noteLabel.minimumScaleFactor = 0.7
        addSubview(noteLabel)

        likeIconImageView.contentMode = .scaleAspectFit
        commentIconImageView.contentMode = .scaleAspectFit
        reportButton.setImage(UIImage(named: "friends_updates_report_icon"), for: .normal)
        reportButton.imageView?.contentMode = .scaleAspectFit
        reportButton.accessibilityLabel = "Report"
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        [likeIconImageView, commentIconImageView].forEach { addSubview($0) }
        addSubview(reportButton)

        likeCountLabel.text = item.likes
        likeCountLabel.textColor = noteLabel.textColor
        likeCountLabel.font = Self.smallFont
        likeCountLabel.textAlignment = .right
        likeCountLabel.adjustsFontSizeToFitWidth = true
        likeCountLabel.minimumScaleFactor = 0.75
        addSubview(likeCountLabel)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(named: item.avatarImageName)
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderColor = UIColor(red: 0.94, green: 0.41, blue: 0.76, alpha: 1).cgColor
        avatarImageView.layer.borderWidth = 2
        addSubview(avatarImageView)

        nameLabel.text = item.name
        nameLabel.textColor = noteLabel.textColor
        nameLabel.font = Self.nameFont
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        addSubview(nameLabel)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        [
            photoImageView,
            noteLabel,
            likeIconImageView,
            likeCountLabel,
            commentIconImageView,
            reportButton,
            avatarImageView,
            nameLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 142),

            photoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            photoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            photoImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            photoImageView.widthAnchor.constraint(equalToConstant: 160),

            noteLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            noteLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 16),
            noteLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -19),
            noteLabel.heightAnchor.constraint(equalToConstant: 42),

            likeIconImageView.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 11),
            likeIconImageView.leadingAnchor.constraint(greaterThanOrEqualTo: noteLabel.leadingAnchor),
            likeIconImageView.widthAnchor.constraint(equalToConstant: 13),
            likeIconImageView.heightAnchor.constraint(equalTo: likeIconImageView.widthAnchor),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeIconImageView.trailingAnchor, constant: 4),
            likeCountLabel.centerYAnchor.constraint(equalTo: likeIconImageView.centerYAnchor, constant: 1),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 42),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 17),

            commentIconImageView.leadingAnchor.constraint(equalTo: likeCountLabel.trailingAnchor, constant: 12),
            commentIconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            commentIconImageView.centerYAnchor.constraint(equalTo: likeIconImageView.centerYAnchor),
            commentIconImageView.widthAnchor.constraint(equalToConstant: 13),
            commentIconImageView.heightAnchor.constraint(equalTo: commentIconImageView.widthAnchor),

            reportButton.leadingAnchor.constraint(equalTo: noteLabel.leadingAnchor, constant: -6),
            reportButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            reportButton.widthAnchor.constraint(equalToConstant: 32),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor),

            avatarImageView.trailingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: -6),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -17),
            avatarImageView.widthAnchor.constraint(equalToConstant: 37),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor, constant: 2),
            nameLabel.widthAnchor.constraint(equalToConstant: 45),
            nameLabel.heightAnchor.constraint(equalToConstant: 28)
        ])

        avatarImageView.layer.cornerRadius = 18.5
    }

    private static var noteFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 12) ?? .italicSystemFont(ofSize: 12)
    }

    private static var smallFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 11) ?? .italicSystemFont(ofSize: 11)
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 20) ?? .italicSystemFont(ofSize: 20)
    }

    @objc private func cardTapped() {
        onTap?()
    }

    @objc private func reportTapped() {
        onReport?()
    }
}
