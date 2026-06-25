//
//  FriendTableViewCell.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class FriendTableViewCell: UITableViewCell {
    static let reuseIdentifier = "FriendTableViewCell"

    var onChatTapped: (() -> Void)?

    private let avatarImageView = UIImageView(image: UIImage(named: "message_avatar"))
    private let nameLabel = UILabel()
    private let chatButton = UIButton(type: .custom)

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
        onChatTapped = nil
    }

    func configure(name: String, avatarImageName: String) {
        nameLabel.text = name
        avatarImageView.image = UIImage(named: avatarImageName) ?? UIImage(named: "message_avatar")
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 21
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)

        nameLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        nameLabel.font = Self.nameFont
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        contentView.addSubview(nameLabel)

        chatButton.setImage(UIImage(named: "tab_chat"), for: .normal)
        chatButton.imageView?.contentMode = .scaleAspectFit
        chatButton.adjustsImageWhenHighlighted = false
        chatButton.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)
        contentView.addSubview(chatButton)
    }

    private func setupConstraints() {
        [
            avatarImageView,
            nameLabel,
            chatButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 3),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 42),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 13),
            nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: chatButton.leadingAnchor, constant: -18),
            nameLabel.heightAnchor.constraint(equalToConstant: 26),

            chatButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -23),
            chatButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor, constant: 1),
            chatButton.widthAnchor.constraint(equalToConstant: 27),
            chatButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc private func chatTapped() {
        onChatTapped?()
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 18) ?? .italicSystemFont(ofSize: 18)
    }
}
