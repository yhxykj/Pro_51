//
//  MyProfileViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class MyProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private struct ProfileData {
        let displayName: String
        let avatarImageName: String
        let avatarImage: UIImage?
        let dynamicItems: [UserProfileDynamicItem]
    }

    private let tableView = UITableView()
    private let profileData: ProfileData
    private var dynamicLikes: [Bool]
    private weak var likeCountLabel: UILabel?

    override var prefersStatusBarHidden: Bool {
        true
    }

    init() {
        let profileData = MyProfileViewController.makeProfileData()
        self.profileData = profileData
        self.dynamicLikes = MyProfileViewController.dynamicLikes(for: profileData)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let profileData = MyProfileViewController.makeProfileData()
        self.profileData = profileData
        self.dynamicLikes = MyProfileViewController.dynamicLikes(for: profileData)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoriteItemsDidChange),
            name: .favoriteItemsDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFavoriteState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        let backgroundImageView = UIImageView(image: UIImage(named: "user_profile_background"))
        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        let contentPanelView = UIView()
        contentPanelView.backgroundColor = .white
        contentPanelView.layer.cornerRadius = 18
        contentPanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(contentPanelView)

        let settingsButton = UIButton(type: .custom)
        configureImageButton(settingsButton, imageName: "my_profile_settings_button")
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        view.addSubview(settingsButton)

        let avatarImageView = UIImageView(image: profileData.avatarImage ?? UIImage(named: profileData.avatarImageName))
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.borderWidth = 6
        view.addSubview(avatarImageView)

        let friendCountLabel = makeCenteredLabel(Self.actualFriendCountText(), font: Self.statFont)
        let friendTextLabel = makeCenteredLabel("friend", font: Self.statFont)
        let likeCountLabel = makeCenteredLabel(likeCountText(), font: Self.statFont)
        let likeTextLabel = makeCenteredLabel("like", font: Self.statFont)
        self.likeCountLabel = likeCountLabel
        [likeCountLabel, likeTextLabel].forEach { label in
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(likesTapped)))
        }
        [friendCountLabel, friendTextLabel, likeCountLabel, likeTextLabel].forEach { view.addSubview($0) }

        let nameLabel = makeCenteredLabel(profileData.displayName, font: Self.nameFont)
        view.addSubview(nameLabel)

        let introImageView = UIImageView(image: UIImage(named: "user_profile_intro_text"))
        introImageView.contentMode = .scaleAspectFit
        view.addSubview(introImageView)

        let getCoinsButton = UIButton(type: .custom)
        getCoinsButton.setBackgroundImage(UIImage(named: "my_profile_get_coins_button"), for: .normal)
        getCoinsButton.addTarget(self, action: #selector(getCoinsTapped), for: .touchUpInside)
        view.addSubview(getCoinsButton)

        let dynamicTitleImageView = UIImageView(image: UIImage(named: "user_profile_dynamic_title"))
        dynamicTitleImageView.contentMode = .scaleAspectFit
        view.addSubview(dynamicTitleImageView)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UserProfileDynamicTableViewCell.self, forCellReuseIdentifier: UserProfileDynamicTableViewCell.reuseIdentifier)
        view.addSubview(tableView)

        [
            backgroundImageView,
            contentPanelView,
            settingsButton,
            avatarImageView,
            friendCountLabel,
            friendTextLabel,
            likeCountLabel,
            likeTextLabel,
            nameLabel,
            introImageView,
            getCoinsButton,
            dynamicTitleImageView,
            tableView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let panelTopConstraint = contentPanelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 122)
        panelTopConstraint.priority = .defaultHigh
        let getCoinsHeightConstraint = getCoinsButton.heightAnchor.constraint(equalTo: getCoinsButton.widthAnchor, multiplier: 237 / 1064)
        getCoinsHeightConstraint.priority = .defaultHigh
        let tableBottomConstraint = tableView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -132)
        tableBottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            panelTopConstraint,
            contentPanelView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 76),
            contentPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentPanelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            settingsButton.widthAnchor.constraint(equalToConstant: 56),
            settingsButton.heightAnchor.constraint(equalToConstant: 56),

            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 53),
            avatarImageView.widthAnchor.constraint(equalToConstant: 136),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            friendCountLabel.topAnchor.constraint(equalTo: contentPanelView.topAnchor, constant: 39),
            friendCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            friendCountLabel.widthAnchor.constraint(equalToConstant: 82),
            friendCountLabel.heightAnchor.constraint(equalToConstant: 24),

            friendTextLabel.topAnchor.constraint(equalTo: friendCountLabel.bottomAnchor, constant: 6),
            friendTextLabel.centerXAnchor.constraint(equalTo: friendCountLabel.centerXAnchor),
            friendTextLabel.widthAnchor.constraint(equalTo: friendCountLabel.widthAnchor),
            friendTextLabel.heightAnchor.constraint(equalToConstant: 27),

            likeCountLabel.topAnchor.constraint(equalTo: friendCountLabel.topAnchor),
            likeCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),
            likeCountLabel.widthAnchor.constraint(equalTo: friendCountLabel.widthAnchor),
            likeCountLabel.heightAnchor.constraint(equalTo: friendCountLabel.heightAnchor),

            likeTextLabel.topAnchor.constraint(equalTo: friendTextLabel.topAnchor),
            likeTextLabel.centerXAnchor.constraint(equalTo: likeCountLabel.centerXAnchor),
            likeTextLabel.widthAnchor.constraint(equalTo: likeCountLabel.widthAnchor),
            likeTextLabel.heightAnchor.constraint(equalTo: friendTextLabel.heightAnchor),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            nameLabel.heightAnchor.constraint(equalToConstant: 34),

            introImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 19),
            introImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 53),
            introImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -53),
            introImageView.heightAnchor.constraint(equalToConstant: 25),

            getCoinsButton.topAnchor.constraint(equalTo: introImageView.bottomAnchor, constant: 27),
            getCoinsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            getCoinsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            getCoinsHeightConstraint,
            getCoinsButton.heightAnchor.constraint(lessThanOrEqualToConstant: 78),

            dynamicTitleImageView.topAnchor.constraint(equalTo: getCoinsButton.bottomAnchor, constant: 24),
            dynamicTitleImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            dynamicTitleImageView.widthAnchor.constraint(equalToConstant: 110),
            dynamicTitleImageView.heightAnchor.constraint(equalToConstant: 34),

            tableView.topAnchor.constraint(equalTo: dynamicTitleImageView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.heightAnchor.constraint(equalToConstant: 196),
            tableBottomConstraint
        ])

        avatarImageView.layer.cornerRadius = 68
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        profileData.dynamicItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        98
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: UserProfileDynamicTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? UserProfileDynamicTableViewCell
        else {
            return UITableViewCell()
        }

        cell.layoutMargins = .zero
        cell.separatorInset = .zero
        let item = displayedDynamicItem(at: indexPath.row)
        cell.configure(item: item, isLiked: dynamicLikes[indexPath.row])
        cell.onLikeTapped = { [weak self] in
            guard let self else { return }
            guard indexPath.row < dynamicLikes.count else { return }
            FavoriteStore.shared.toggle(favoriteItem(for: profileData.dynamicItems[indexPath.row]))
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let tracks = profileData.dynamicItems.map {
            AudioPlayerTrack(
                title: $0.title,
                artist: profileData.displayName,
                audioURL: $0.audioURL,
                avatarImageName: profileData.avatarImageName
            )
        }
        navigationController?.pushViewController(
            AudioPlayerViewController(tracks: tracks, initialIndex: indexPath.row, isGoodFriend: true),
            animated: true
        )
    }

    private func makeCenteredLabel(_ text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        label.font = font
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
    }

    private func displayedDynamicItem(at index: Int) -> UserProfileDynamicItem {
        let item = profileData.dynamicItems[index]
        let isLiked = index < dynamicLikes.count && dynamicLikes[index]
        return UserProfileDynamicItem(
            title: item.title,
            artist: item.artist,
            albumImageName: item.albumImageName,
            likeCount: isLiked ? "1" : "0",
            audioURL: item.audioURL
        )
    }

    private func likeCountText() -> String {
        "\(FavoriteStore.shared.count)"
    }

    private func favoriteItem(for item: UserProfileDynamicItem) -> FavoriteItem {
        FavoriteItem.audio(
            title: item.title,
            artist: profileData.displayName,
            artworkImageName: item.albumImageName,
            audioURL: item.audioURL,
            avatarImageName: profileData.avatarImageName
        )
    }

    private func reloadFavoriteState() {
        dynamicLikes = Self.dynamicLikes(for: profileData)
        likeCountLabel?.text = likeCountText()
        tableView.reloadData()
    }

    @objc private func settingsTapped() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func getCoinsTapped() {
        navigationController?.pushViewController(RechargeViewController(), animated: true)
    }

    @objc private func likesTapped() {
        navigationController?.pushViewController(FavoriteListViewController(), animated: true)
    }

    @objc private func favoriteItemsDidChange() {
        reloadFavoriteState()
    }

    private static func makeProfileData() -> ProfileData {
        let accountProfile = AccountProfileStore.shared.currentProfile()
        return ProfileData(
            displayName: accountProfile.displayName,
            avatarImageName: accountProfile.avatarImageName,
            avatarImage: accountProfile.avatarImage,
            dynamicItems: AuthSession.isCurrentTestAccount ? testAccountDynamicItems() : []
        )
    }

    private static func testAccountDynamicItems() -> [UserProfileDynamicItem] {
        [
            UserProfileDynamicItem(
                title: "Feeling Supreme Livehouse",
                artist: "-Music666",
                albumImageName: "record_disc",
                likeCount: "0",
                audioURL: audioURL(forResource: "liangzi_feeling_supreme_livehouse")
            )
        ]
    }

    private static func actualFriendCountText() -> String {
        "\(FriendStore.shared.count)"
    }

    private static func dynamicLikes(for profileData: ProfileData) -> [Bool] {
        profileData.dynamicItems.map { item in
            let favoriteItem = FavoriteItem.audio(
                title: item.title,
                artist: profileData.displayName,
                artworkImageName: item.albumImageName,
                audioURL: item.audioURL,
                avatarImageName: profileData.avatarImageName
            )
            return FavoriteStore.shared.isFavorite(id: favoriteItem.id)
        }
    }

    private static func audioURL(forResource resourceName: String) -> URL? {
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

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 27) ?? .italicSystemFont(ofSize: 27)
    }

    private static var statFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 17) ?? .italicSystemFont(ofSize: 17)
    }
}
