//
//  NonFriendChatPromptView.swift
//  SKMusic
//
//  Created by Codex on 2026/6/25.
//

import UIKit

final class NonFriendChatPromptView: UIView {
    private let dimmingView = UIView()
    private let cardImageView = UIImageView(image: UIImage(named: "non_friend_card_bg"))
    private let mascotImageView = UIImageView(image: UIImage(named: "non_friend_mascot"))
    private let titleImageView = UIImageView(image: UIImage(named: "non_friend_sorry_title"))
    private let messageImageView = UIImageView(image: UIImage(named: "non_friend_message"))
    private let confirmButton = UIButton(type: .custom)

    static func present(in hostView: UIView) {
        guard !hostView.subviews.contains(where: { $0 is NonFriendChatPromptView }) else { return }

        let promptView = NonFriendChatPromptView()
        promptView.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(promptView)

        NSLayoutConstraint.activate([
            promptView.topAnchor.constraint(equalTo: hostView.topAnchor),
            promptView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            promptView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            promptView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])

        promptView.animateIn()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setupViews() {
        backgroundColor = .clear

        dimmingView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(dimmingView)

        [cardImageView, mascotImageView, titleImageView, messageImageView].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            addSubview(imageView)
        }

        confirmButton.setBackgroundImage(UIImage(named: "non_friend_get_it_button"), for: .normal)
        confirmButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        addSubview(confirmButton)
    }

    private func setupConstraints() {
        [
            dimmingView,
            cardImageView,
            mascotImageView,
            titleImageView,
            messageImageView,
            confirmButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 4),
            cardImageView.widthAnchor.constraint(equalToConstant: 279),
            cardImageView.heightAnchor.constraint(equalToConstant: 212),

            mascotImageView.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            mascotImageView.bottomAnchor.constraint(equalTo: cardImageView.topAnchor, constant: 39),
            mascotImageView.widthAnchor.constraint(equalToConstant: 119),
            mascotImageView.heightAnchor.constraint(equalToConstant: 110),

            titleImageView.topAnchor.constraint(equalTo: cardImageView.topAnchor, constant: 54),
            titleImageView.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            titleImageView.widthAnchor.constraint(equalToConstant: 99),
            titleImageView.heightAnchor.constraint(equalToConstant: 40),

            messageImageView.topAnchor.constraint(equalTo: titleImageView.bottomAnchor, constant: -12),
            messageImageView.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            messageImageView.widthAnchor.constraint(equalToConstant: 244),
            messageImageView.heightAnchor.constraint(equalToConstant: 95),

            confirmButton.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            confirmButton.bottomAnchor.constraint(equalTo: cardImageView.bottomAnchor, constant: 16),
            confirmButton.widthAnchor.constraint(equalToConstant: 162),
            confirmButton.heightAnchor.constraint(equalToConstant: 33)
        ])
    }

    private func animateIn() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    @objc private func dismissTapped() {
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseIn]) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}
