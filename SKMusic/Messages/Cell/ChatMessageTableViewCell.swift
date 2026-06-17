//
//  ChatMessageTableViewCell.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class ChatMessageTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ChatMessageTableViewCell"

    private enum Layout {
        static let incomingColor = UIColor(red: 154.0 / 255.0, green: 152.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
        static let outgoingColor = UIColor(red: 255.0 / 255.0, green: 152.0 / 255.0, blue: 152.0 / 255.0, alpha: 1.0)
    }

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private var incomingLeadingConstraint: NSLayoutConstraint!
    private var outgoingTrailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(text: String, isIncoming: Bool) {
        messageLabel.text = text
        bubbleView.backgroundColor = isIncoming ? Layout.incomingColor : Layout.outgoingColor
        incomingLeadingConstraint.isActive = false
        outgoingTrailingConstraint.isActive = false

        if isIncoming {
            incomingLeadingConstraint.isActive = true
        } else {
            outgoingTrailingConstraint.isActive = true
        }
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        bubbleView.layer.cornerRadius = 5
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.10
        bubbleView.layer.shadowRadius = 4
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.addSubview(bubbleView)

        messageLabel.textColor = .white
        messageLabel.font = Self.messageFont
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.6
        bubbleView.addSubview(messageLabel)
    }

    private func setupConstraints() {
        [bubbleView, messageLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        incomingLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        outgoingTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.widthAnchor.constraint(equalToConstant: 214),
            bubbleView.heightAnchor.constraint(equalToConstant: 36),
            bubbleView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -29),

            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 25),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            messageLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private static var messageFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 11) ?? .italicSystemFont(ofSize: 11)
    }
}
