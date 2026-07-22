//
//  PublishCoinConfirmView.swift
//  SKMusic
//
//  Created by Codex on 2026/7/22.
//

import UIKit

final class PublishCoinConfirmView: UIView {
    static let popupTag = 52002

    var onConfirm: (() -> Void)?

    private let cost: Int
    private let balance: Int

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let coinPanelView = UIView()
    private let coinImageView = UIImageView(image: UIImage(named: "recommendation_coin_icon"))
    private let costLabel = UILabel()
    private let costCaptionLabel = UILabel()
    private let balanceLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let confirmButton = UIButton(type: .custom)

    static func present(in hostView: UIView, cost: Int, balance: Int, onConfirm: @escaping () -> Void) {
        guard hostView.viewWithTag(popupTag) == nil else { return }

        let popupView = PublishCoinConfirmView(cost: cost, balance: balance)
        popupView.tag = popupTag
        popupView.onConfirm = onConfirm
        hostView.addSubview(popupView)
        popupView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            popupView.topAnchor.constraint(equalTo: hostView.topAnchor),
            popupView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            popupView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            popupView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])
    }

    private init(cost: Int, balance: Int) {
        self.cost = cost
        self.balance = balance
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        self.cost = 19
        self.balance = CoinBalanceStore.balance
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.16)

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1.6
        cardView.layer.borderColor = UIColor(red: 0.94, green: 0.49, blue: 0.80, alpha: 1).cgColor
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.25
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        addSubview(cardView)

        titleLabel.text = "Ready to Release?"
        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.font = Self.heavyItalicFont(size: 23)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.72
        cardView.addSubview(titleLabel)

        messageLabel.text = "Publishing will spend \(cost) coins and send your performance into the music feed."
        messageLabel.textColor = UIColor(red: 0.34, green: 0.32, blue: 0.37, alpha: 1)
        messageLabel.textAlignment = .center
        messageLabel.font = Self.mediumItalicFont(size: 15)
        messageLabel.numberOfLines = 0
        cardView.addSubview(messageLabel)

        coinPanelView.backgroundColor = UIColor(red: 1.00, green: 0.92, blue: 0.98, alpha: 1)
        coinPanelView.layer.cornerRadius = 18
        coinPanelView.layer.borderWidth = 1
        coinPanelView.layer.borderColor = UIColor(red: 0.96, green: 0.58, blue: 0.84, alpha: 1).cgColor
        cardView.addSubview(coinPanelView)

        coinImageView.contentMode = .scaleAspectFit
        coinPanelView.addSubview(coinImageView)

        costLabel.text = "\(cost)"
        costLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        costLabel.textAlignment = .left
        costLabel.font = Self.heavyItalicFont(size: 30)
        costLabel.adjustsFontSizeToFitWidth = true
        costLabel.minimumScaleFactor = 0.65
        coinPanelView.addSubview(costLabel)

        costCaptionLabel.text = "coins to publish"
        costCaptionLabel.textColor = UIColor(red: 0.47, green: 0.43, blue: 0.50, alpha: 1)
        costCaptionLabel.textAlignment = .left
        costCaptionLabel.font = Self.mediumItalicFont(size: 13)
        costCaptionLabel.adjustsFontSizeToFitWidth = true
        costCaptionLabel.minimumScaleFactor = 0.7
        coinPanelView.addSubview(costCaptionLabel)

        balanceLabel.text = "Balance: \(balance) coins"
        balanceLabel.textColor = UIColor(red: 0.48, green: 0.44, blue: 0.52, alpha: 1)
        balanceLabel.textAlignment = .center
        balanceLabel.font = Self.mediumItalicFont(size: 13)
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.72
        cardView.addSubview(balanceLabel)

        configureSecondaryButton(cancelButton, title: "CANCEL")
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cardView.addSubview(cancelButton)

        configurePrimaryButton(confirmButton, title: "SPEND \(cost)")
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cardView.addSubview(confirmButton)
    }

    private func setupConstraints() {
        [
            cardView,
            titleLabel,
            messageLabel,
            coinPanelView,
            coinImageView,
            costLabel,
            costCaptionLabel,
            balanceLabel,
            cancelButton,
            confirmButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let preferredCardWidthConstraint = cardView.widthAnchor.constraint(equalToConstant: 326)
        preferredCardWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -8),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
            preferredCardWidthConstraint,

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 26),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 28),
            messageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -28),

            coinPanelView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 18),
            coinPanelView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            coinPanelView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            coinPanelView.heightAnchor.constraint(equalToConstant: 82),

            coinImageView.leadingAnchor.constraint(equalTo: coinPanelView.leadingAnchor, constant: 24),
            coinImageView.centerYAnchor.constraint(equalTo: coinPanelView.centerYAnchor),
            coinImageView.widthAnchor.constraint(equalToConstant: 40),
            coinImageView.heightAnchor.constraint(equalTo: coinImageView.widthAnchor),

            costLabel.leadingAnchor.constraint(equalTo: coinImageView.trailingAnchor, constant: 14),
            costLabel.topAnchor.constraint(equalTo: coinPanelView.topAnchor, constant: 14),
            costLabel.trailingAnchor.constraint(equalTo: coinPanelView.trailingAnchor, constant: -18),
            costLabel.heightAnchor.constraint(equalToConstant: 34),

            costCaptionLabel.leadingAnchor.constraint(equalTo: costLabel.leadingAnchor),
            costCaptionLabel.trailingAnchor.constraint(equalTo: costLabel.trailingAnchor),
            costCaptionLabel.topAnchor.constraint(equalTo: costLabel.bottomAnchor, constant: 1),
            costCaptionLabel.heightAnchor.constraint(equalToConstant: 20),

            balanceLabel.topAnchor.constraint(equalTo: coinPanelView.bottomAnchor, constant: 13),
            balanceLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 28),
            balanceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -28),
            balanceLabel.heightAnchor.constraint(equalToConstant: 20),

            cancelButton.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            cancelButton.widthAnchor.constraint(equalToConstant: 119),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28),

            confirmButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
            confirmButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 14),
            confirmButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            confirmButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor)
        ])
    }

    private func configurePrimaryButton(_ button: UIButton, title: String) {
        button.backgroundColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor(red: 0.96, green: 0.38, blue: 0.75, alpha: 1).cgColor
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 7
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Self.heavyItalicFont(size: 16)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.72
        button.accessibilityLabel = "Spend \(cost) coins and release"
    }

    private func configureSecondaryButton(_ button: UIButton, title: String) {
        button.backgroundColor = .white
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 1.3
        button.layer.borderColor = UIColor(red: 0.90, green: 0.58, blue: 0.80, alpha: 1).cgColor
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(red: 0.49, green: 0.43, blue: 0.52, alpha: 1), for: .normal)
        button.titleLabel?.font = Self.heavyItalicFont(size: 15)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.72
        button.accessibilityLabel = "Cancel release"
    }

    @objc private func cancelTapped() {
        removeFromSuperview()
    }

    @objc private func confirmTapped() {
        removeFromSuperview()
        onConfirm?()
    }

    private static func heavyItalicFont(size: CGFloat) -> UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: size) ?? .italicSystemFont(ofSize: size)
    }

    private static func mediumItalicFont(size: CGFloat) -> UIFont {
        UIFont(name: "AvenirNext-MediumItalic", size: size) ?? .italicSystemFont(ofSize: size)
    }
}
