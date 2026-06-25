//
//  BlacklistViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import UIKit

final class BlacklistViewController: UIViewController {
    private enum Layout {
        static let rowAspectRatio: CGFloat = 136 / 650
        static let rowHorizontalInset: CGFloat = 32.5
        static let rowMaximumWidth: CGFloat = 325
        static let rowTopOffset: CGFloat = 82
        static let rowSpacing: CGFloat = 18
        static let avatarSize: CGFloat = 40
        static let deleteButtonSize: CGFloat = 44
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let backButton = UIButton(type: .custom)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let emptyStateContainerView = UIView()
    private let emptyStateImageView = UIImageView(image: UIImage(named: "huaban-5102107231"))
    private let emptyLabel = UILabel()

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        reloadRows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(blockedUsersDidChange),
            name: .blockedUsersDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadRows()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        stackView.axis = .vertical
        stackView.spacing = Layout.rowSpacing
        contentView.addSubview(stackView)

        emptyStateContainerView.isUserInteractionEnabled = false
        contentView.addSubview(emptyStateContainerView)

        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateContainerView.addSubview(emptyStateImageView)

        emptyLabel.text = "No blocked users"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        emptyLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
        emptyStateContainerView.addSubview(emptyLabel)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            backButton,
            scrollView,
            contentView,
            stackView,
            emptyStateContainerView,
            emptyStateImageView,
            emptyLabel
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

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.rowTopOffset),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.rowHorizontalInset),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.rowHorizontalInset),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.rowMaximumWidth),

            emptyStateContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            emptyStateContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyStateContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.72),
            emptyStateContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateContainerView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 156),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 143),

            emptyLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 15),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyStateContainerView.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyStateContainerView.trailingAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyStateContainerView.bottomAnchor),
            emptyLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func reloadRows() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let users = BlockedUserStore.shared.allUsers()
        emptyStateContainerView.isHidden = !users.isEmpty

        users.forEach { user in
            stackView.addArrangedSubview(makeRowView(for: user))
        }
    }

    private func makeRowView(for user: BlockedUser) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = UIColor(red: 0.56, green: 0.55, blue: 0.94, alpha: 1)
        rowView.layer.cornerRadius = 7
        rowView.layer.borderColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1).cgColor
        rowView.layer.borderWidth = 1.6
        rowView.accessibilityLabel = "Blacklist"

        let avatarImageView = UIImageView(image: UIImage(named: user.avatarImageName))
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        rowView.addSubview(avatarImageView)

        let titleLabel = UILabel()
        titleLabel.text = user.displayName
        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        titleLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82
        rowView.addSubview(titleLabel)

        let deleteButton = UIButton(type: .custom)
        configureImageButton(deleteButton, imageName: "blacklist_delete_icon", accessibilityLabel: "Remove from blacklist")
        deleteButton.addAction(UIAction { [weak self] _ in
            BlockedUserStore.shared.unblock(identifier: user.identifier)
            self?.reloadRows()
        }, for: .touchUpInside)
        rowView.addSubview(deleteButton)

        [
            rowView,
            avatarImageView,
            titleLabel,
            deleteButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: Layout.rowAspectRatio),

            avatarImageView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 35),
            avatarImageView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor, constant: 1),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -14),
            titleLabel.heightAnchor.constraint(equalToConstant: 28),

            deleteButton.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -17),
            deleteButton.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: Layout.deleteButtonSize),
            deleteButton.heightAnchor.constraint(equalTo: deleteButton.widthAnchor)
        ])

        avatarImageView.layer.cornerRadius = Layout.avatarSize / 2
        return rowView
    }

    private func configureImageButton(_ button: UIButton, imageName: String, accessibilityLabel: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = accessibilityLabel
    }

    @objc private func blockedUsersDidChange() {
        reloadRows()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
