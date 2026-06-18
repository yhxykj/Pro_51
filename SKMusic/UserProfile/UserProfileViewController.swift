//
//  UserProfileViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class UserProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView()
    private var dynamicLikes = [false, false, false]

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
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

        let avatarImageView = UIImageView(image: UIImage(named: "message_avatar"))
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.borderWidth = 12
        view.addSubview(avatarImageView)

        let nameLabel = UILabel()
        nameLabel.text = "Angela"
        nameLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        nameLabel.font = Self.nameFont
        view.addSubview(nameLabel)

        let agePillView = UIImageView(image: UIImage(named: "user_profile_pink_pill"))
        agePillView.contentMode = .scaleToFill
        agePillView.isUserInteractionEnabled = false
        view.addSubview(agePillView)

        let genderIconImageView = UIImageView(image: UIImage(named: "user_profile_female_icon"))
        genderIconImageView.contentMode = .scaleAspectFit
        view.addSubview(genderIconImageView)

        let ageLabel = UILabel()
        ageLabel.text = "24"
        ageLabel.textColor = .white
        ageLabel.font = Self.ageFont
        view.addSubview(ageLabel)

        let friendCountLabel = makeStatLabel("950")
        let friendTextLabel = makeStatLabel("friend")
        let likeCountLabel = makeStatLabel("999+")
        let likeTextLabel = makeStatLabel("like")
        [friendCountLabel, friendTextLabel, likeCountLabel, likeTextLabel].forEach { view.addSubview($0) }

        let goodFriendButton = UIButton(type: .custom)
        goodFriendButton.backgroundColor = UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        goodFriendButton.layer.cornerRadius = 16
        goodFriendButton.setTitle("Good Friend", for: .normal)
        goodFriendButton.setTitleColor(.white, for: .normal)
        goodFriendButton.titleLabel?.font = Self.goodFriendFont
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
        dynamicLikes.count
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

        cell.configure(isLiked: dynamicLikes[indexPath.row])
        cell.onLikeTapped = { [weak self, weak tableView] in
            guard let self else { return }
            dynamicLikes[indexPath.row].toggle()
            tableView?.reloadRows(at: [indexPath], with: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        navigationController?.pushViewController(AudioPlayerViewController(), animated: true)
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

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func chatTapped() {
        navigationController?.pushViewController(FriendChatViewController(), animated: true)
    }

    @objc private func callTapped() {
        navigationController?.pushViewController(VideoCallViewController(), animated: true)
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
