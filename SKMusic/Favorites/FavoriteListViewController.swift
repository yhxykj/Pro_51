//
//  FavoriteListViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import UIKit

final class FavoriteListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Filter: Int, CaseIterable {
        case all
        case music
        case video

        var title: String {
            switch self {
            case .all:
                return "All"
            case .music:
                return "Music"
            case .video:
                return "Video"
            }
        }
    }

    private let tableView = UITableView()
    private let segmentedControl = UISegmentedControl(items: Filter.allCases.map(\.title))
    private let emptyStateContainerView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateImageView = UIImageView(image: UIImage(named: "huaban-5102107231"))

    private var selectedFilter: Filter = .all
    private var favoriteItems: [FavoriteItem] = []

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        reloadFavorites()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoriteItemsDidChange),
            name: .favoriteItemsDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFavorites()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        let backgroundImageView = UIImageView(image: UIImage(named: "home_background"))
        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back_button"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "Likes"
        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        titleLabel.font = Self.titleFont
        view.addSubview(titleLabel)

        segmentedControl.selectedSegmentIndex = selectedFilter.rawValue
        segmentedControl.selectedSegmentTintColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1), .font: Self.segmentFont],
            for: .normal
        )
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: Self.segmentFont],
            for: .selected
        )
        segmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        view.addSubview(segmentedControl)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FavoriteListTableViewCell.self, forCellReuseIdentifier: FavoriteListTableViewCell.reuseIdentifier)
        view.addSubview(tableView)

        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateContainerView.addSubview(emptyStateImageView)

        emptyStateLabel.text = "No likes yet"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        emptyStateLabel.font = Self.emptyFont
        emptyStateContainerView.addSubview(emptyStateLabel)
        view.addSubview(emptyStateContainerView)

        [
            backgroundImageView,
            backButton,
            titleLabel,
            segmentedControl,
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
            titleLabel.heightAnchor.constraint(equalToConstant: 36),

            segmentedControl.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 22),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            emptyStateContainerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateContainerView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -24),
            emptyStateContainerView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            emptyStateContainerView.heightAnchor.constraint(equalToConstant: 190),

            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateContainerView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 96),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 96),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 18),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateContainerView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateContainerView.trailingAnchor, constant: -16),
            emptyStateLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func reloadFavorites() {
        let allItems = FavoriteStore.shared.items
        switch selectedFilter {
        case .all:
            favoriteItems = allItems
        case .music:
            favoriteItems = allItems.filter { $0.kind == .audio }
        case .video:
            favoriteItems = allItems.filter { $0.kind == .video }
        }

        tableView.reloadData()
        emptyStateContainerView.isHidden = !favoriteItems.isEmpty
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favoriteItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        102
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FavoriteListTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? FavoriteListTableViewCell
        else {
            return UITableViewCell()
        }

        let item = favoriteItems[indexPath.row]
        cell.configure(with: item)
        cell.onFavoriteTapped = { [weak self] in
            FavoriteStore.shared.remove(id: item.id)
            self?.reloadFavorites()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let item = favoriteItems[indexPath.row]
        switch item.kind {
        case .audio:
            let track = AudioPlayerTrack(
                title: item.title,
                artist: item.subtitle,
                audioURL: mediaURL(for: item),
                avatarImageName: item.avatarImageName
            )
            navigationController?.pushViewController(
                AudioPlayerViewController(tracks: [track], initialIndex: 0),
                animated: true
            )
        case .video:
            let track = VideoPlayerTrack(
                title: item.title,
                videoURL: mediaURL(for: item),
                coverImageName: item.artworkImageName,
                ownerName: item.subtitle,
                avatarImageName: item.avatarImageName
            )
            navigationController?.pushViewController(
                VideoPlayerViewController(tracks: [track]),
                animated: true
            )
        }
    }

    private func mediaURL(for item: FavoriteItem) -> URL? {
        guard let resourceName = item.resourceName else { return nil }

        let fileExtension = item.kind == .audio ? "mp3" : "mp4"
        if let bundledURL = Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Mp3")
            ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension) {
            return bundledURL
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }

        let fileName = "\(resourceName).\(fileExtension)"
        return FileManager.default
            .enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first { $0.lastPathComponent == fileName }
    }

    @objc private func favoriteItemsDidChange() {
        reloadFavorites()
    }

    @objc private func filterChanged() {
        selectedFilter = Filter(rawValue: segmentedControl.selectedSegmentIndex) ?? .all
        reloadFavorites()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 27) ?? .italicSystemFont(ofSize: 27)
    }

    private static var segmentFont: UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: 14) ?? .boldSystemFont(ofSize: 14)
    }

    private static var emptyFont: UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: 17) ?? .boldSystemFont(ofSize: 17)
    }
}

private final class FavoriteListTableViewCell: UITableViewCell {
    static let reuseIdentifier = "FavoriteListTableViewCell"

    var onFavoriteTapped: (() -> Void)?

    private let cardView = UIView()
    private let artworkImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let kindLabel = UILabel()
    private let favoriteButton = UIButton(type: .custom)
    private let playImageView = UIImageView(image: UIImage(named: "recommendation_play_icon"))

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
        onFavoriteTapped = nil
    }

    func configure(with item: FavoriteItem) {
        artworkImageView.image = UIImage(named: item.artworkImageName)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        kindLabel.text = item.kind == .audio ? "Music" : "Video"
        favoriteButton.setImage(UIImage(named: "like_icon"), for: .normal)
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 18
        cardView.layer.borderColor = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1).cgColor
        cardView.layer.borderWidth = 1
        cardView.layer.shadowColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1).cgColor
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowRadius = 0
        cardView.layer.shadowOffset = CGSize(width: 4, height: 4)
        contentView.addSubview(cardView)

        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 12
        cardView.addSubview(artworkImageView)

        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        titleLabel.font = Self.titleFont
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.72
        cardView.addSubview(titleLabel)

        subtitleLabel.textColor = UIColor(red: 0.42, green: 0.42, blue: 0.44, alpha: 1)
        subtitleLabel.font = Self.subtitleFont
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.75
        cardView.addSubview(subtitleLabel)

        kindLabel.textColor = .white
        kindLabel.backgroundColor = UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        kindLabel.font = Self.kindFont
        kindLabel.textAlignment = .center
        kindLabel.layer.cornerRadius = 9
        kindLabel.clipsToBounds = true
        cardView.addSubview(kindLabel)

        favoriteButton.imageView?.contentMode = .scaleAspectFit
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        cardView.addSubview(favoriteButton)

        playImageView.contentMode = .scaleAspectFit
        cardView.addSubview(playImageView)
    }

    private func setupConstraints() {
        [
            cardView,
            artworkImageView,
            titleLabel,
            subtitleLabel,
            kindLabel,
            favoriteButton,
            playImageView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            artworkImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            artworkImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            artworkImageView.widthAnchor.constraint(equalToConstant: 58),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 18),

            kindLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            kindLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 2),
            kindLabel.widthAnchor.constraint(equalToConstant: 56),
            kindLabel.heightAnchor.constraint(equalToConstant: 18),

            favoriteButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -13),
            favoriteButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor, constant: -10),
            favoriteButton.widthAnchor.constraint(equalToConstant: 34),
            favoriteButton.heightAnchor.constraint(equalTo: favoriteButton.widthAnchor),

            playImageView.centerXAnchor.constraint(equalTo: favoriteButton.centerXAnchor),
            playImageView.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor, constant: 3),
            playImageView.widthAnchor.constraint(equalToConstant: 14),
            playImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    @objc private func favoriteTapped() {
        onFavoriteTapped?()
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: 16) ?? .boldSystemFont(ofSize: 16)
    }

    private static var subtitleFont: UIFont {
        UIFont(name: "AvenirNext-Regular", size: 13) ?? .systemFont(ofSize: 13)
    }

    private static var kindFont: UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: 11) ?? .boldSystemFont(ofSize: 11)
    }
}
