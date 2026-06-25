//
//  FriendTableViewCell.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class FriendTableViewCell: UITableViewCell {
    static let reuseIdentifier = "FriendTableViewCell"

    private let avatarImageView = UIImageView(image: UIImage(named: "message_avatar"))
    private let nameLabel = UILabel()
    private let chatImageView = UIImageView(image: UIImage(named: "tab_chat"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(name: String) {
        nameLabel.text = name
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

        chatImageView.contentMode = .scaleAspectFit
        contentView.addSubview(chatImageView)
    }

    private func setupConstraints() {
        [
            avatarImageView,
            nameLabel,
            chatImageView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 3),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 42),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 13),
            nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: chatImageView.leadingAnchor, constant: -18),
            nameLabel.heightAnchor.constraint(equalToConstant: 26),

            chatImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -23),
            chatImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor, constant: 1),
            chatImageView.widthAnchor.constraint(equalToConstant: 27),
            chatImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 18) ?? .italicSystemFont(ofSize: 18)
    }
}
