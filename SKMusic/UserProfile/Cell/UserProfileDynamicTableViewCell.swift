//
//  UserProfileDynamicTableViewCell.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class UserProfileDynamicTableViewCell: UITableViewCell {
    static let reuseIdentifier = "UserProfileDynamicTableViewCell"

    var onLikeTapped: (() -> Void)?

    private let cardView = UIView()
    private let albumImageView = UIImageView(image: UIImage(named: "record_disc"))
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let playImageView = UIImageView(image: UIImage(named: "recommendation_play_icon"))
    private let likeButton = UIButton(type: .custom)
    private let countLabel = UILabel()
    private let detailImageView = UIImageView(image: UIImage(named: "user_profile_detail_icon"))

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
        onLikeTapped = nil
    }

    func configure(isLiked: Bool) {
        likeButton.setImage(
            UIImage(named: isLiked ? "user_profile_liked_icon" : "user_profile_unliked_icon"),
            for: .normal
        )
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 25
        cardView.layer.borderColor = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1).cgColor
        cardView.layer.borderWidth = 1
        cardView.layer.shadowColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1).cgColor
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowRadius = 0
        cardView.layer.shadowOffset = CGSize(width: 5, height: 5)
        contentView.addSubview(cardView)

        albumImageView.contentMode = .scaleAspectFill
        albumImageView.layer.cornerRadius = 26
        albumImageView.clipsToBounds = true
        cardView.addSubview(albumImageView)

        titleLabel.text = "Insula (Dirty Nano Remix)"
        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        titleLabel.font = Self.titleFont
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.72
        cardView.addSubview(titleLabel)

        artistLabel.text = "-Annie"
        artistLabel.textColor = titleLabel.textColor
        artistLabel.font = Self.artistFont
        cardView.addSubview(artistLabel)

        playImageView.contentMode = .scaleAspectFit
        cardView.addSubview(playImageView)

        likeButton.imageView?.contentMode = .scaleAspectFit
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        contentView.addSubview(likeButton)

        countLabel.text = "100w"
        countLabel.textColor = UIColor(red: 0.20, green: 0.20, blue: 0.21, alpha: 1)
        countLabel.font = Self.countFont
        contentView.addSubview(countLabel)

        detailImageView.contentMode = .scaleAspectFit
        contentView.addSubview(detailImageView)
    }

    private func setupConstraints() {
        [
            cardView,
            albumImageView,
            titleLabel,
            artistLabel,
            playImageView,
            likeButton,
            countLabel,
            detailImageView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 55),

            albumImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15),
            albumImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            albumImageView.widthAnchor.constraint(equalToConstant: 52),
            albumImageView.heightAnchor.constraint(equalTo: albumImageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 13),
            titleLabel.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: playImageView.leadingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 18),

            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            artistLabel.heightAnchor.constraint(equalToConstant: 17),

            playImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -23),
            playImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 18),
            playImageView.heightAnchor.constraint(equalToConstant: 23),

            likeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 11),
            likeButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 17),
            likeButton.widthAnchor.constraint(equalToConstant: 22),
            likeButton.heightAnchor.constraint(equalToConstant: 22),

            countLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 3),
            countLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 39),
            countLabel.heightAnchor.constraint(equalToConstant: 18),

            detailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3),
            detailImageView.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            detailImageView.widthAnchor.constraint(equalToConstant: 34),
            detailImageView.heightAnchor.constraint(equalTo: detailImageView.widthAnchor),

            detailImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -9)
        ])
    }

    @objc private func likeTapped() {
        onLikeTapped?()
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 13) ?? .italicSystemFont(ofSize: 13)
    }

    private static var artistFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 12) ?? .italicSystemFont(ofSize: 12)
    }

    private static var countFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 9) ?? .italicSystemFont(ofSize: 9)
    }
}
