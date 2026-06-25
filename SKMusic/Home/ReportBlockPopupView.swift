//
//  ReportBlockPopupView.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import UIKit

final class ReportBlockPopupView: UIView {
    static let popupTag = 51001

    var onReport: (() -> Void)?
    var onBlock: (() -> Void)?

    private let cardImageView = UIImageView(image: UIImage(named: "report_popup_background"))
    private let dividerView = UIView()
    private let reportButton = UIButton(type: .custom)
    private let blockButton = UIButton(type: .custom)
    private let userIconImageView = UIImageView(image: UIImage(named: "report_popup_user_icon"))
    private let alertIconImageView = UIImageView(image: UIImage(named: "report_popup_alert_icon"))
    private let reportTextImageView = UIImageView(image: UIImage(named: "report_popup_report_text"))
    private let blockTextImageView = UIImageView(image: UIImage(named: "report_popup_block_text"))
    private let closeButton = UIButton(type: .custom)

    static func present(in hostView: UIView, onReport: (() -> Void)? = nil, onBlock: (() -> Void)? = nil) {
        guard hostView.viewWithTag(popupTag) == nil else { return }

        let popupView = ReportBlockPopupView()
        popupView.tag = popupTag
        popupView.onReport = onReport
        popupView.onBlock = onBlock
        hostView.addSubview(popupView)
        popupView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            popupView.topAnchor.constraint(equalTo: hostView.topAnchor),
            popupView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            popupView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            popupView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.46)

        cardImageView.contentMode = .scaleToFill
        addSubview(cardImageView)

        dividerView.backgroundColor = UIColor(red: 0.77, green: 0.62, blue: 0.76, alpha: 0.62)
        addSubview(dividerView)

        [reportButton, blockButton].forEach { button in
            button.backgroundColor = .clear
            addSubview(button)
        }
        reportButton.accessibilityLabel = "Report"
        blockButton.accessibilityLabel = "Block"
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        blockButton.addTarget(self, action: #selector(blockTapped), for: .touchUpInside)

        [userIconImageView, alertIconImageView, reportTextImageView, blockTextImageView].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            addSubview(imageView)
        }

        closeButton.setImage(UIImage(named: "report_popup_back_button"), for: .normal)
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.contentHorizontalAlignment = .fill
        closeButton.contentVerticalAlignment = .fill
        closeButton.accessibilityLabel = "Close"
        closeButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        addSubview(closeButton)
    }

    private func setupConstraints() {
        [
            cardImageView,
            dividerView,
            reportButton,
            blockButton,
            userIconImageView,
            alertIconImageView,
            reportTextImageView,
            blockTextImageView,
            closeButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -12),
            cardImageView.widthAnchor.constraint(equalToConstant: 278),
            cardImageView.heightAnchor.constraint(equalToConstant: 212),

            dividerView.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            dividerView.centerYAnchor.constraint(equalTo: cardImageView.centerYAnchor, constant: -4),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.heightAnchor.constraint(equalToConstant: 96),

            userIconImageView.centerXAnchor.constraint(equalTo: cardImageView.leadingAnchor, constant: 84),
            userIconImageView.topAnchor.constraint(equalTo: cardImageView.topAnchor, constant: 62),
            userIconImageView.widthAnchor.constraint(equalToConstant: 63),
            userIconImageView.heightAnchor.constraint(equalTo: userIconImageView.widthAnchor),

            alertIconImageView.centerXAnchor.constraint(equalTo: cardImageView.trailingAnchor, constant: -84),
            alertIconImageView.topAnchor.constraint(equalTo: userIconImageView.topAnchor),
            alertIconImageView.widthAnchor.constraint(equalTo: userIconImageView.widthAnchor),
            alertIconImageView.heightAnchor.constraint(equalTo: userIconImageView.heightAnchor),

            reportTextImageView.centerXAnchor.constraint(equalTo: userIconImageView.centerXAnchor),
            reportTextImageView.topAnchor.constraint(equalTo: userIconImageView.bottomAnchor, constant: 11),
            reportTextImageView.widthAnchor.constraint(equalToConstant: 68),
            reportTextImageView.heightAnchor.constraint(equalToConstant: 24),

            blockTextImageView.centerXAnchor.constraint(equalTo: alertIconImageView.centerXAnchor),
            blockTextImageView.topAnchor.constraint(equalTo: reportTextImageView.topAnchor),
            blockTextImageView.widthAnchor.constraint(equalToConstant: 58),
            blockTextImageView.heightAnchor.constraint(equalTo: reportTextImageView.heightAnchor),

            reportButton.leadingAnchor.constraint(equalTo: cardImageView.leadingAnchor),
            reportButton.topAnchor.constraint(equalTo: cardImageView.topAnchor),
            reportButton.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor),
            reportButton.bottomAnchor.constraint(equalTo: cardImageView.bottomAnchor),

            blockButton.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            blockButton.topAnchor.constraint(equalTo: cardImageView.topAnchor),
            blockButton.trailingAnchor.constraint(equalTo: cardImageView.trailingAnchor),
            blockButton.bottomAnchor.constraint(equalTo: cardImageView.bottomAnchor),

            closeButton.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: cardImageView.bottomAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 61),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
    }

    @objc private func reportTapped() {
        removeFromSuperview()
        onReport?()
    }

    @objc private func blockTapped() {
        removeFromSuperview()
        onBlock?()
    }

    @objc private func dismissTapped() {
        removeFromSuperview()
    }
}

extension UIViewController {
    func presentReportBlockPopup(in hostView: UIView? = nil, blockedUser: BlockedUser? = nil) {
        guard let targetView = hostView ?? navigationController?.view ?? parent?.view ?? view else { return }

        ReportBlockPopupView.present(
            in: targetView,
            onReport: { [weak self] in
                self?.showReportReviewAlert()
            },
            onBlock: { [weak self] in
                self?.blockUserAndReturnToFirstLevelPage(blockedUser)
            }
        )
    }

    func presentReportBlockPopupWithoutLeavingPage(in hostView: UIView? = nil, blockedUser: BlockedUser? = nil) {
        guard let targetView = hostView ?? navigationController?.view ?? parent?.view ?? view else { return }

        ReportBlockPopupView.present(
            in: targetView,
            onReport: { [weak self] in
                self?.showReportReviewAlert()
            },
            onBlock: { [weak self] in
                self?.blockUserWithoutLeavingPage(blockedUser)
            }
        )
    }

    private func showReportReviewAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "Report submitted successfully. We will review it within 24 hours.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func blockUserAndReturnToFirstLevelPage(_ user: BlockedUser?) {
        view.endEditing(true)

        if let user {
            BlockedUserStore.shared.block(user)
        }

        if let navigationController = navigationController ?? parent?.navigationController {
            if let mainTabBarController = navigationController.viewControllers.first(where: { $0 is MainTabBarController }) {
                navigationController.popToViewController(mainTabBarController, animated: true)
                return
            }

            navigationController.popToRootViewController(animated: true)
            return
        }

        dismiss(animated: true)
    }

    private func blockUserWithoutLeavingPage(_ user: BlockedUser?) {
        view.endEditing(true)

        if let user {
            BlockedUserStore.shared.block(user)
        }
    }
}
