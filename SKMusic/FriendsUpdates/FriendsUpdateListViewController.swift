//
//  FriendsUpdateListViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import UIKit

final class FriendsUpdateListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let allItems: [FriendsUpdateItem]
    private var visibleItems: [FriendsUpdateItem] = []

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let emptyStateContainerView = UIView()
    private let emptyStateImageView = UIImageView(image: UIImage(named: "huaban-5102107231"))
    private let emptyStateLabel = UILabel()

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(items: [FriendsUpdateItem] = FriendsUpdateData.items) {
        self.allItems = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.allItems = FriendsUpdateData.items
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        reloadItems()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(blockedUsersDidChange),
            name: .blockedUsersDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadItems()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        titleLabel.text = "Friend Updates"
        titleLabel.textColor = Self.textColor
        titleLabel.font = Self.titleFont
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        view.addSubview(titleLabel)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FriendsUpdateListCell.self, forCellReuseIdentifier: FriendsUpdateListCell.reuseIdentifier)
        view.addSubview(tableView)

        emptyStateContainerView.isHidden = true
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateContainerView.addSubview(emptyStateImageView)

        emptyStateLabel.text = "No friend updates yet"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = Self.textColor
        emptyStateLabel.font = Self.emptyFont
        emptyStateContainerView.addSubview(emptyStateLabel)
        view.addSubview(emptyStateContainerView)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            backButton,
            titleLabel,
            tableView,
            emptyStateContainerView,
            emptyStateImageView,
            emptyStateLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 21),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            titleLabel.heightAnchor.constraint(equalToConstant: 38),

            tableView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            emptyStateContainerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateContainerView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -28),
            emptyStateContainerView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            emptyStateContainerView.heightAnchor.constraint(equalToConstant: 210),

            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateContainerView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 120),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 110),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 18),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateContainerView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateContainerView.trailingAnchor, constant: -16),
            emptyStateLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func reloadItems() {
        visibleItems = allItems.filter { !BlockedUserStore.shared.isBlocked(identifier: $0.blockedUser.identifier) }
        tableView.reloadData()
        emptyStateContainerView.isHidden = !visibleItems.isEmpty
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        170
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FriendsUpdateListCell.reuseIdentifier,
                for: indexPath
            ) as? FriendsUpdateListCell
        else {
            return UITableViewCell()
        }

        let item = visibleItems[indexPath.row]
        cell.configure(with: item)
        cell.onReport = { [weak self] in
            self?.showReportBlockPopup(for: item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        openMedia(for: visibleItems[indexPath.row])
    }

    private func openMedia(for item: FriendsUpdateItem) {
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

    private func showReportBlockPopup(for item: FriendsUpdateItem) {
        guard let hostView = navigationController?.view ?? view else { return }
        presentReportBlockPopupWithoutLeavingPage(in: hostView, blockedUser: item.blockedUser)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func blockedUsersDidChange() {
        reloadItems()
    }

    private static var textColor: UIColor {
        UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 27) ?? .italicSystemFont(ofSize: 27)
    }

    private static var emptyFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
    }
}

private final class FriendsUpdateListCell: UITableViewCell {
    static let reuseIdentifier = "FriendsUpdateListCell"

    var onReport: (() -> Void)?

    private let cardView = UIView()
    private let coverImageView = UIImageView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let titleLabel = UILabel()
    private let noteLabel = UILabel()
    private let kindLabel = UILabel()
    private let likeIconImageView = UIImageView(image: UIImage(named: "friends_updates_like_icon"))
    private let likeCountLabel = UILabel()
    private let commentIconImageView = UIImageView(image: UIImage(named: "friends_updates_comment_icon"))
    private let reportButton = UIButton(type: .custom)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onReport = nil
    }

    func configure(with item: FriendsUpdateItem) {
        coverImageView.image = UIImage(named: item.coverImageName)
        avatarImageView.image = UIImage(named: item.avatarImageName)
        nameLabel.text = item.name
        titleLabel.text = item.title
        noteLabel.text = item.note
        kindLabel.text = item.mediaKind.label
        likeCountLabel.text = item.likes
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.borderColor = UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1).cgColor
        cardView.layer.borderWidth = 1
        cardView.layer.shadowColor = UIColor(red: 0.96, green: 0.41, blue: 0.76, alpha: 1).cgColor
        cardView.layer.shadowOpacity = 0.4
        cardView.layer.shadowRadius = 0
        cardView.layer.shadowOffset = CGSize(width: 3, height: 3)
        contentView.addSubview(cardView)

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 8
        cardView.addSubview(coverImageView)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderColor = UIColor(red: 0.94, green: 0.41, blue: 0.76, alpha: 1).cgColor
        avatarImageView.layer.borderWidth = 2
        cardView.addSubview(avatarImageView)

        nameLabel.textColor = Self.textColor
        nameLabel.font = Self.nameFont
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        cardView.addSubview(nameLabel)

        titleLabel.textColor = Self.textColor
        titleLabel.font = Self.titleFont
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.72
        cardView.addSubview(titleLabel)

        noteLabel.textColor = Self.textColor
        noteLabel.font = Self.noteFont
        noteLabel.numberOfLines = 2
        noteLabel.adjustsFontSizeToFitWidth = true
        noteLabel.minimumScaleFactor = 0.72
        cardView.addSubview(noteLabel)

        kindLabel.textColor = .white
        kindLabel.backgroundColor = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
        kindLabel.font = Self.kindFont
        kindLabel.textAlignment = .center
        kindLabel.layer.cornerRadius = 9
        kindLabel.clipsToBounds = true
        cardView.addSubview(kindLabel)

        likeIconImageView.contentMode = .scaleAspectFit
        cardView.addSubview(likeIconImageView)

        likeCountLabel.textColor = Self.textColor
        likeCountLabel.font = Self.smallFont
        likeCountLabel.adjustsFontSizeToFitWidth = true
        likeCountLabel.minimumScaleFactor = 0.75
        cardView.addSubview(likeCountLabel)

        commentIconImageView.contentMode = .scaleAspectFit
        cardView.addSubview(commentIconImageView)

        reportButton.setImage(UIImage(named: "friends_updates_report_icon"), for: .normal)
        reportButton.imageView?.contentMode = .scaleAspectFit
        reportButton.accessibilityLabel = "Report"
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        cardView.addSubview(reportButton)
    }

    private func setupConstraints() {
        [
            cardView,
            coverImageView,
            avatarImageView,
            nameLabel,
            titleLabel,
            noteLabel,
            kindLabel,
            likeIconImageView,
            likeCountLabel,
            commentIconImageView,
            reportButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            coverImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            coverImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            coverImageView.heightAnchor.constraint(equalToConstant: 122),
            coverImageView.widthAnchor.constraint(equalToConstant: 118),

            avatarImageView.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 13),
            avatarImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 15),
            avatarImageView.widthAnchor.constraint(equalToConstant: 38),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: reportButton.leadingAnchor, constant: -8),
            nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor, constant: 1),
            nameLabel.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 7),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),

            noteLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            noteLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            noteLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            noteLabel.heightAnchor.constraint(equalToConstant: 40),

            kindLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            kindLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            kindLabel.widthAnchor.constraint(equalToConstant: 56),
            kindLabel.heightAnchor.constraint(equalToConstant: 18),

            likeIconImageView.leadingAnchor.constraint(equalTo: kindLabel.trailingAnchor, constant: 12),
            likeIconImageView.centerYAnchor.constraint(equalTo: kindLabel.centerYAnchor),
            likeIconImageView.widthAnchor.constraint(equalToConstant: 14),
            likeIconImageView.heightAnchor.constraint(equalTo: likeIconImageView.widthAnchor),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeIconImageView.trailingAnchor, constant: 5),
            likeCountLabel.centerYAnchor.constraint(equalTo: likeIconImageView.centerYAnchor, constant: 1),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 48),
            likeCountLabel.heightAnchor.constraint(equalToConstant: 18),

            commentIconImageView.leadingAnchor.constraint(equalTo: likeCountLabel.trailingAnchor, constant: 12),
            commentIconImageView.centerYAnchor.constraint(equalTo: likeIconImageView.centerYAnchor),
            commentIconImageView.widthAnchor.constraint(equalToConstant: 14),
            commentIconImageView.heightAnchor.constraint(equalTo: commentIconImageView.widthAnchor),

            reportButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            reportButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            reportButton.widthAnchor.constraint(equalToConstant: 32),
            reportButton.heightAnchor.constraint(equalTo: reportButton.widthAnchor)
        ])

        avatarImageView.layer.cornerRadius = 19
    }

    @objc private func reportTapped() {
        onReport?()
    }

    private static var textColor: UIColor {
        UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 20) ?? .italicSystemFont(ofSize: 20)
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: 15) ?? .boldSystemFont(ofSize: 15)
    }

    private static var noteFont: UIFont {
        UIFont(name: "AvenirNext-MediumItalic", size: 12) ?? .italicSystemFont(ofSize: 12)
    }

    private static var kindFont: UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: 10) ?? .boldSystemFont(ofSize: 10)
    }

    private static var smallFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 11) ?? .italicSystemFont(ofSize: 11)
    }
}
