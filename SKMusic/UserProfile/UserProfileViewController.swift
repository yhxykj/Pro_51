//
//  UserProfileViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class UserProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Gender {
        case female
        case male

        var iconImageName: String {
            switch self {
            case .female:
                return "user_profile_female_icon"
            case .male:
                return "user_profile_male_icon"
            }
        }

        var pillImageName: String {
            switch self {
            case .female:
                return "user_profile_pink_pill"
            case .male:
                return "user_profile_blue_pill"
            }
        }
    }

    private struct UserProfileData {
        let displayName: String
        let avatarImageName: String
        let age: String
        let gender: Gender
        let dynamicItems: [UserProfileDynamicItem]
    }

    private let tableView = UITableView()
    private let profileData: UserProfileData
    private var dynamicLikes: [Bool]
    private weak var likeCountLabel: UILabel?

    override var prefersStatusBarHidden: Bool {
        true
    }

    init(displayName: String = "Angela", avatarImageName: String = "", featuredTrack: AudioPlayerTrack? = nil) {
        let profileData = Self.makeProfileData(
            displayName: displayName,
            avatarImageName: avatarImageName,
            featuredTrack: featuredTrack
        )
        self.profileData = profileData
        self.dynamicLikes = Self.dynamicLikes(for: profileData)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let profileData = Self.makeProfileData(
            displayName: "Angela",
            avatarImageName: "",
            featuredTrack: nil
        )
        self.profileData = profileData
        self.dynamicLikes = Self.dynamicLikes(for: profileData)
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

        let backButton = UIButton(type: .custom)
        configureImageButton(backButton, imageName: "back_button")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let avatarImageView = UIImageView(image: UIImage(named: profileData.avatarImageName))
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.borderWidth = 12
        view.addSubview(avatarImageView)

        let nameLabel = UILabel()
        nameLabel.text = profileData.displayName
        nameLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        nameLabel.font = Self.nameFont
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.72
        view.addSubview(nameLabel)

        let agePillView = UIImageView(image: UIImage(named: profileData.gender.pillImageName))
        agePillView.contentMode = .scaleToFill
        agePillView.isUserInteractionEnabled = false
        view.addSubview(agePillView)

        let genderIconImageView = UIImageView(image: UIImage(named: profileData.gender.iconImageName))
        genderIconImageView.contentMode = .scaleAspectFit
        view.addSubview(genderIconImageView)

        let ageLabel = UILabel()
        ageLabel.text = profileData.age
        ageLabel.textColor = .white
        ageLabel.font = Self.ageFont
        view.addSubview(ageLabel)

        let friendCountLabel = makeStatLabel(Self.actualFriendCountText())
        let friendTextLabel = makeStatLabel("friend")
        let likeCountLabel = makeStatLabel(likeCountText())
        let likeTextLabel = makeStatLabel("like")
        self.likeCountLabel = likeCountLabel
        [friendCountLabel, friendTextLabel, likeCountLabel, likeTextLabel].forEach { view.addSubview($0) }

        let goodFriendButton = UIButton(type: .custom)
        goodFriendButton.layer.cornerRadius = 16
        goodFriendButton.titleLabel?.font = Self.goodFriendFont
        goodFriendButton.titleLabel?.adjustsFontSizeToFitWidth = true
        goodFriendButton.titleLabel?.minimumScaleFactor = 0.78
        configureFriendStatusButton(goodFriendButton)
        goodFriendButton.addTarget(self, action: #selector(friendStatusTapped), for: .touchUpInside)
        view.addSubview(goodFriendButton)

        let introImageView = UIImageView(image: UIImage(named: "user_profile_intro_text"))
        introImageView.contentMode = .scaleAspectFit
        view.addSubview(introImageView)

        let chatButton = UIButton(type: .custom)
        configureImageButton(chatButton, imageName: "user_profile_chat_button")
        chatButton.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)
        view.addSubview(chatButton)

        let callButton = UIButton(type: .custom)
        configureImageButton(callButton, imageName: "user_profile_call_button")
        callButton.addTarget(self, action: #selector(callTapped), for: .touchUpInside)
        view.addSubview(callButton)

        let dynamicTitleImageView = UIImageView(image: UIImage(named: "user_profile_dynamic_title"))
        dynamicTitleImageView.contentMode = .scaleAspectFit
        view.addSubview(dynamicTitleImageView)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UserProfileDynamicTableViewCell.self, forCellReuseIdentifier: UserProfileDynamicTableViewCell.reuseIdentifier)
        view.addSubview(tableView)

        [
            backgroundImageView,
            backButton,
            avatarImageView,
            nameLabel,
            agePillView,
            genderIconImageView,
            ageLabel,
            friendCountLabel,
            friendTextLabel,
            likeCountLabel,
            likeTextLabel,
            goodFriendButton,
            introImageView,
            chatButton,
            callButton,
            dynamicTitleImageView,
            tableView
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

            avatarImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: -13),
            avatarImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 28),
            avatarImageView.widthAnchor.constraint(equalToConstant: 253),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 105),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 142),
            nameLabel.heightAnchor.constraint(equalToConstant: 28),

            agePillView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            agePillView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 2),
            agePillView.widthAnchor.constraint(equalToConstant: 60),
            agePillView.heightAnchor.constraint(equalToConstant: 28),

            genderIconImageView.leadingAnchor.constraint(equalTo: agePillView.leadingAnchor, constant: 9.5),
            genderIconImageView.centerYAnchor.constraint(equalTo: agePillView.centerYAnchor),
            genderIconImageView.widthAnchor.constraint(equalToConstant: 17),
            genderIconImageView.heightAnchor.constraint(equalTo: genderIconImageView.widthAnchor),

            ageLabel.leadingAnchor.constraint(equalTo: genderIconImageView.trailingAnchor, constant: 6),
            ageLabel.centerYAnchor.constraint(equalTo: agePillView.centerYAnchor, constant: 1),
            ageLabel.heightAnchor.constraint(equalToConstant: 23),

            friendCountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 14),
            friendCountLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: 7),
            friendCountLabel.widthAnchor.constraint(equalToConstant: 56),
            friendCountLabel.heightAnchor.constraint(equalToConstant: 24),

            friendTextLabel.topAnchor.constraint(equalTo: friendCountLabel.bottomAnchor, constant: 4),
            friendTextLabel.leadingAnchor.constraint(equalTo: friendCountLabel.leadingAnchor, constant: -7),
            friendTextLabel.widthAnchor.constraint(equalToConstant: 79),
            friendTextLabel.heightAnchor.constraint(equalToConstant: 24),

            likeCountLabel.topAnchor.constraint(equalTo: friendCountLabel.topAnchor),
            likeCountLabel.leadingAnchor.constraint(equalTo: friendCountLabel.trailingAnchor, constant: 18),
            likeCountLabel.widthAnchor.constraint(equalToConstant: 66),
            likeCountLabel.heightAnchor.constraint(equalTo: friendCountLabel.heightAnchor),

            likeTextLabel.topAnchor.constraint(equalTo: friendTextLabel.topAnchor),
            likeTextLabel.leadingAnchor.constraint(equalTo: likeCountLabel.leadingAnchor, constant: 6),
            likeTextLabel.widthAnchor.constraint(equalToConstant: 52),
            likeTextLabel.heightAnchor.constraint(equalTo: friendTextLabel.heightAnchor),

            goodFriendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            goodFriendButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -20),
            goodFriendButton.widthAnchor.constraint(equalToConstant: 130),
            goodFriendButton.heightAnchor.constraint(equalToConstant: 32),

            introImageView.topAnchor.constraint(equalTo: friendTextLabel.bottomAnchor, constant: 36),
            introImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            introImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -39),
            introImageView.heightAnchor.constraint(equalToConstant: 24),

            chatButton.topAnchor.constraint(equalTo: introImageView.bottomAnchor, constant: 16),
            chatButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chatButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.43),
            chatButton.heightAnchor.constraint(equalTo: chatButton.widthAnchor, multiplier: 0.52),

            callButton.topAnchor.constraint(equalTo: chatButton.topAnchor),
            callButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            callButton.widthAnchor.constraint(equalTo: chatButton.widthAnchor),
            callButton.heightAnchor.constraint(equalTo: chatButton.heightAnchor),

            dynamicTitleImageView.topAnchor.constraint(equalTo: chatButton.bottomAnchor, constant: 11),
            dynamicTitleImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            dynamicTitleImageView.widthAnchor.constraint(equalToConstant: 92),
            dynamicTitleImageView.heightAnchor.constraint(equalToConstant: 23),

            tableView.topAnchor.constraint(equalTo: dynamicTitleImageView.bottomAnchor, constant: 17),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -22)
        ])

        avatarImageView.layer.cornerRadius = 119
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
            AudioPlayerViewController(tracks: tracks, initialIndex: indexPath.row, isGoodFriend: isProfileFriend()),
            animated: true
        )
    }

    private func makeStatLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        label.font = Self.statFont
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
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
        "\(dynamicLikes.filter { $0 }.count)"
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

    private func isProfileFriend() -> Bool {
        FriendStore.shared.isFriend(name: profileData.displayName)
    }

    private func configureFriendStatusButton(_ button: UIButton) {
        let isFriend = isProfileFriend()
        button.setTitle(isFriend ? "Good Friend" : "+ Add Friend", for: .normal)
        button.setTitleColor(isFriend ? .white : UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1), for: .normal)
        button.backgroundColor = isFriend
            ? UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
            : UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func chatTapped() {
        guard isProfileFriend() else {
            showNonFriendChatPrompt()
            return
        }

        navigationController?.pushViewController(
            FriendChatViewController(peerName: profileData.displayName, avatarImageName: profileData.avatarImageName),
            animated: true
        )
    }

    @objc private func callTapped() {
        guard isProfileFriend() else {
            showNonFriendChatPrompt()
            return
        }

        navigationController?.pushViewController(VideoCallViewController(), animated: true)
    }

    @objc private func friendStatusTapped() {
        let message = isProfileFriend()
            ? "You are already good friends."
            : "Friend request sent successfully."
        showNotice(message)
    }

    @objc private func favoriteItemsDidChange() {
        reloadFavoriteState()
    }

    private func showNotice(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showNonFriendChatPrompt() {
        NonFriendChatPromptView.present(in: navigationController?.view ?? view)
    }

    private static func makeProfileData(
        displayName: String,
        avatarImageName: String,
        featuredTrack: AudioPlayerTrack?
    ) -> UserProfileData {
        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = normalizedName.isEmpty ? "Angela" : normalizedName
        let baseData = baseProfileData(for: name)
        let profileAvatar = avatarImageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? baseData.avatarImageName
            : avatarImageName
        let profileGender = gender(forAvatarImageName: profileAvatar, fallback: baseData.gender)
        var dynamicItems = baseDynamicItems(for: name)

        if let featuredTrack {
            let featuredItem = UserProfileDynamicItem(
                title: featuredTrack.title,
                artist: "-\(name)",
                albumImageName: "record_disc",
                likeCount: "0",
                audioURL: featuredTrack.audioURL
            )
            dynamicItems = [featuredItem] + dynamicItems.filter { $0.title != featuredItem.title }
        }

        return UserProfileData(
            displayName: name,
            avatarImageName: profileAvatar,
            age: baseData.age,
            gender: profileGender,
            dynamicItems: dynamicItems
        )
    }

    private static func baseProfileData(
        for displayName: String
    ) -> (age: String, gender: Gender, avatarImageName: String) {
        switch normalized(displayName) {
        case "annie":
            return ("24", .male, "avatar_01")
        case "miley cyrus":
            return ("26", .male, "avatar_02")
        case "lady gaga":
            return ("27", .female, "avatar_03")
        case "angela":
            return ("24", .female, "avatar_04")
        case "rihanna":
            return ("25", .female, "avatar_05")
        case "kylie":
            return ("23", .female, "avatar_06")
        default:
            return ("24", .female, "message_avatar")
        }
    }

    private static func gender(forAvatarImageName avatarImageName: String, fallback: Gender) -> Gender {
        switch avatarImageName {
        case "avatar_01", "avatar_02", "avatar_08", "avatar_09", "avatar_12", "avatar_13", "avatar_17", "avatar_19":
            return .male
        case "avatar_03", "avatar_04", "avatar_05", "avatar_06", "avatar_07", "avatar_10", "avatar_11", "avatar_14", "avatar_15", "avatar_16", "avatar_18", "avatar_20", "message_avatar":
            return .female
        default:
            return fallback
        }
    }

    private static func baseDynamicItems(for displayName: String) -> [UserProfileDynamicItem] {
        let artist = "-\(displayName)"
        switch normalized(displayName) {
        case "annie":
            return [
                dynamicItem("Best Me 50 Feet Cover", artist: artist, audioResourceName: "best_me_50_feet_cover")
            ]
        case "miley cyrus":
            return [
                dynamicItem("Flowers", artist: artist, audioResourceName: "flowers_miley_cyrus")
            ]
        case "lady gaga":
            return [
                dynamicItem("Lady Gaga Live", artist: artist, audioResourceName: "lady_gaga_live")
            ]
        case "angela":
            return [
                dynamicItem("Love Is Gone", artist: artist, audioResourceName: "love_is_gone")
            ]
        case "rihanna":
            return [
                dynamicItem("Diamonds", artist: artist, audioResourceName: "diamonds_rihanna_chaoshan_cover")
            ]
        case "kylie":
            return [
                dynamicItem("Can't Get You Out Of My Head", artist: artist, audioResourceName: "cant_get_you_out_of_my_head_live")
            ]
        default:
            return []
        }
    }

    private static func dynamicItem(
        _ title: String,
        artist: String,
        audioResourceName: String
    ) -> UserProfileDynamicItem {
        UserProfileDynamicItem(
            title: title,
            artist: artist,
            albumImageName: "record_disc",
            likeCount: "0",
            audioURL: audioURL(forResource: audioResourceName)
        )
    }

    private static func actualFriendCountText() -> String {
        "0"
    }

    private static func dynamicLikes(for profileData: UserProfileData) -> [Bool] {
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

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: "- "))
            .lowercased()
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 21) ?? .italicSystemFont(ofSize: 21)
    }

    private static var ageFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 15) ?? .italicSystemFont(ofSize: 15)
    }

    private static var statFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 18) ?? .italicSystemFont(ofSize: 18)
    }

    private static var goodFriendFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 17) ?? .italicSystemFont(ofSize: 17)
    }
}
