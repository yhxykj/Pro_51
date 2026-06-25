//
//  MessageTableViewCell.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class MessageTableViewCell: UITableViewCell {
    static let reuseIdentifier = "MessageTableViewCell"

    var onWillOpen: (() -> Void)?
    var onDidClose: (() -> Void)?

    private let cardView = UIView()
    private let avatarImageView = UIImageView(image: UIImage(named: "message_avatar"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let deleteButton = UIButton(type: .custom)
    private let revealOffset: CGFloat = 82
    private var currentOffset: CGFloat = 0
    private var gestureStartOffset: CGFloat = 0
    private var cardLeadingConstraint: NSLayoutConstraint!
    private var cardTrailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onWillOpen = nil
        onDidClose = nil
        close(animated: false)
    }

    func configure(title: String, subtitle: String, avatarImageName: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        avatarImageView.image = UIImage(named: avatarImageName) ?? UIImage(named: "message_avatar")
    }

    func close(animated: Bool) {
        setCardOffset(0, animated: animated)
        onDidClose?()
    }

    private func open(animated: Bool) {
        onWillOpen?()
        setCardOffset(-revealOffset, animated: animated)
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        contentView.clipsToBounds = false

        deleteButton.backgroundColor = UIColor(red: 0.82, green: 0.02, blue: 0.02, alpha: 1)
        deleteButton.layer.cornerRadius = 26
        deleteButton.clipsToBounds = true
        deleteButton.setImage(UIImage(named: "message_delete_icon"), for: .normal)
        deleteButton.imageView?.contentMode = .scaleAspectFit
        deleteButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)

        cardView.backgroundColor = UIColor(red: 0.52, green: 0.50, blue: 0.95, alpha: 1)
        cardView.layer.cornerRadius = 21
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 29
        avatarImageView.clipsToBounds = true
        cardView.addSubview(avatarImageView)

        titleLabel.textColor = .white
        titleLabel.font = Self.titleFont
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        cardView.addSubview(titleLabel)

        subtitleLabel.textColor = .white
        subtitleLabel.font = Self.subtitleFont
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.75
        cardView.addSubview(subtitleLabel)
    }

    private func setupConstraints() {
        [
            deleteButton,
            cardView,
            avatarImageView,
            titleLabel,
            subtitleLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        cardLeadingConstraint = cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        cardTrailingConstraint = cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

        NSLayoutConstraint.activate([
            deleteButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 52),
            deleteButton.heightAnchor.constraint(equalTo: deleteButton.widthAnchor),

            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardLeadingConstraint,
            cardTrailingConstraint,
            cardView.heightAnchor.constraint(equalToConstant: 74),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            avatarImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 58),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -18),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        cardView.addGestureRecognizer(panGesture)
    }

    private func setCardOffset(_ offset: CGFloat, animated: Bool) {
        let limitedOffset = min(0, max(-revealOffset, offset))
        currentOffset = limitedOffset
        cardLeadingConstraint.constant = limitedOffset
        cardTrailingConstraint.constant = limitedOffset

        let updates = {
            self.contentView.layoutIfNeeded()
        }

        guard animated else {
            updates()
            return
        }

        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: updates)
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: contentView)

        switch recognizer.state {
        case .began:
            gestureStartOffset = currentOffset
        case .changed:
            guard abs(translation.x) >= abs(translation.y) else { return }
            let nextOffset = gestureStartOffset + translation.x
            if currentOffset == 0, nextOffset < 0 {
                onWillOpen?()
            }
            setCardOffset(nextOffset, animated: false)
        case .ended, .cancelled, .failed:
            let velocity = recognizer.velocity(in: contentView).x
            if currentOffset < -revealOffset / 2 || velocity < -180 {
                open(animated: true)
            } else {
                close(animated: true)
            }
        default:
            break
        }
    }

    @objc private func deleteTapped() {
        close(animated: true)
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 21) ?? .italicSystemFont(ofSize: 21)
    }

    private static var subtitleFont: UIFont {
        UIFont(name: "AvenirNext-BoldItalic", size: 15) ?? .italicSystemFont(ofSize: 15)
    }
}
