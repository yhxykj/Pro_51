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
        static let oppositeEdgeInset: CGFloat = 80
        static let textLeadingInset: CGFloat = 25
        static let textTrailingInset: CGFloat = 14
    }

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private var incomingLeadingConstraint: NSLayoutConstraint!
    private var incomingMaxTrailingConstraint: NSLayoutConstraint!
    private var outgoingTrailingConstraint: NSLayoutConstraint!
    private var outgoingMinLeadingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maxTextWidth = contentView.bounds.width
            - Layout.oppositeEdgeInset
            - Layout.textLeadingInset
            - Layout.textTrailingInset
        messageLabel.preferredMaxLayoutWidth = max(maxTextWidth, 0)
    }

    func configure(text: String, isIncoming: Bool) {
        messageLabel.text = text
        bubbleView.backgroundColor = isIncoming ? Layout.incomingColor : Layout.outgoingColor
        incomingLeadingConstraint.isActive = false
        incomingMaxTrailingConstraint.isActive = false
        outgoingTrailingConstraint.isActive = false
        outgoingMinLeadingConstraint.isActive = false

        if isIncoming {
            incomingLeadingConstraint.isActive = true
            incomingMaxTrailingConstraint.isActive = true
        } else {
            outgoingTrailingConstraint.isActive = true
            outgoingMinLeadingConstraint.isActive = true
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
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        bubbleView.addSubview(messageLabel)
    }

    private func setupConstraints() {
        [bubbleView, messageLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        incomingLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        incomingMaxTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Layout.oppositeEdgeInset)
        outgoingTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        outgoingMinLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: Layout.oppositeEdgeInset)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Layout.textLeadingInset),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Layout.textTrailingInset),
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ])
    }

    private static var messageFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 15) ?? .italicSystemFont(ofSize: 15)
    }
}
