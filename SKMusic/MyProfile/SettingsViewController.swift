//
//  SettingsViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import UIKit

final class SettingsViewController: UIViewController {
    private enum Layout {
        static let rowAspectRatio: CGFloat = 136 / 650
        static let rowHorizontalInset: CGFloat = 32.5
        static let rowMaximumWidth: CGFloat = 325
        static let rowTopOffset: CGFloat = 78
        static let rowSpacing: CGFloat = 18
        static let logoutBottomOffset: CGFloat = -14
    }

    private enum SettingItem: Int, CaseIterable {
        case blacklist
        case privacyAgreement
        case userAgreement
        case contactUs
        case communityGuidelines
        case deleteAccount

        var imageName: String {
            switch self {
            case .blacklist:
                return "settings_blacklist_button"
            case .privacyAgreement:
                return "settings_privacy_agreement_button"
            case .userAgreement:
                return "settings_user_agreement_button"
            case .contactUs:
                return "settings_contact_us_button"
            case .communityGuidelines:
                return "settings_community_guidelines_button"
            case .deleteAccount:
                return "settings_delete_account_button"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .blacklist:
                return "Blacklist"
            case .privacyAgreement:
                return "Privacy agreement"
            case .userAgreement:
                return "User agreement"
            case .contactUs:
                return "Contact Us"
            case .communityGuidelines:
                return "Community Guidelines"
            case .deleteAccount:
                return "Deletion of account"
            }
        }
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let backButton = UIButton(type: .custom)
    private let itemButtons = SettingItem.allCases.map { _ in UIButton(type: .custom) }
    private let logoutButton = UIButton(type: .custom)

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        for (index, item) in SettingItem.allCases.enumerated() {
            let button = itemButtons[index]
            configureImageButton(button, imageName: item.imageName, accessibilityLabel: item.accessibilityLabel)
            button.tag = item.rawValue
            button.addTarget(self, action: #selector(settingItemTapped(_:)), for: .touchUpInside)
            view.addSubview(button)
        }

        configureImageButton(logoutButton, imageName: "settings_logout_button", accessibilityLabel: "Log out")
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
    }

    private func setupConstraints() {
        let views: [UIView] = [backgroundImageView, backButton, logoutButton] + itemButtons.map { $0 as UIView }
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 21),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        var previousButton: UIButton?
        for button in itemButtons {
            let widthConstraint = button.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -(Layout.rowHorizontalInset * 2))
            widthConstraint.priority = .defaultHigh

            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                widthConstraint,
                button.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.rowMaximumWidth),
                button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: Layout.rowAspectRatio)
            ])

            if let previousButton {
                button.topAnchor.constraint(equalTo: previousButton.bottomAnchor, constant: Layout.rowSpacing).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.rowTopOffset).isActive = true
            }

            previousButton = button
        }

        let logoutWidthConstraint = logoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -(Layout.rowHorizontalInset * 2))
        logoutWidthConstraint.priority = .defaultHigh
        let logoutBottomConstraint = logoutButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: Layout.logoutBottomOffset
        )
        logoutBottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutWidthConstraint,
            logoutButton.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.rowMaximumWidth),
            logoutButton.heightAnchor.constraint(equalTo: logoutButton.widthAnchor, multiplier: Layout.rowAspectRatio),
            logoutBottomConstraint
        ])

        if let lastButton = itemButtons.last {
            logoutButton.topAnchor.constraint(greaterThanOrEqualTo: lastButton.bottomAnchor, constant: 42).isActive = true
        }
    }

    private func configureImageButton(_ button: UIButton, imageName: String, accessibilityLabel: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.accessibilityLabel = accessibilityLabel
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func settingItemTapped(_ sender: UIButton) {
        guard let item = SettingItem(rawValue: sender.tag) else { return }

        switch item {
        case .blacklist:
            navigationController?.pushViewController(BlacklistViewController(), animated: true)
        case .deleteAccount:
            showDeleteAccountConfirmation()
        default:
            showPendingAlert(title: item.accessibilityLabel)
        }
    }

    @objc private func logoutTapped() {
        returnToWelcome()
    }

    private func showDeleteAccountConfirmation() {
        let alert = UIAlertController(
            title: "Deletion of account",
            message: "Are you sure you want to delete this account?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.returnToWelcome()
        })
        present(alert, animated: true)
    }

    private func showPendingAlert(title: String) {
        let alert = UIAlertController(
            title: title,
            message: "Content is not configured yet.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func returnToWelcome() {
        AuthSession.end()
        navigationController?.setViewControllers([ViewController()], animated: true)
    }
}
