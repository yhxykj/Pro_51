//
//  ViewController.swift
//  SKMusic
//
//  Created by 上包666 on 2026/6/17.
//

import UIKit

class ViewController: UIViewController {
    private enum Design {
        static let size = CGSize(width: 390, height: 844)
        static let titleFrame = CGRect(x: 31, y: 108, width: 340, height: 94)
        static let heroFrame = CGRect(x: 44, y: 234, width: 303, height: 299)
        static let agreementFrame = CGRect(x: 33, y: 621, width: 324, height: 28)
        static let signUpFrame = CGRect(x: 31, y: 681, width: 162, height: 62)
        static let logInFrame = CGRect(x: 202, y: 681, width: 162, height: 62)
    }

    private let textColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
    private let agreementTintColor = UIColor(red: 0.88, green: 0.24, blue: 0.65, alpha: 1.0)
    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let titleImageView = UIImageView(image: UIImage(named: "welcome_title"))
    private let titleDecorationView = TitleDecorationView()
    private let heroImageView = UIImageView(image: UIImage(named: "welcome_hero"))
    private let agreementContainerView = UIView()
    private let agreementCheckButton = UIButton(type: .custom)
    private let agreementPrefixLabel = UILabel()
    private let userAgreementButton = UIButton(type: .system)
    private let agreementJoinLabel = UILabel()
    private let privacyAgreementButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .custom)
    private let logInButton = UIButton(type: .custom)
    private var hasAcceptedAgreements = false

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutWelcomeContent()
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.isUserInteractionEnabled = false
        view.addSubview(backgroundImageView)

        titleImageView.contentMode = .scaleAspectFit
        titleImageView.isUserInteractionEnabled = false
        view.addSubview(titleImageView)

        titleDecorationView.backgroundColor = .clear
        titleDecorationView.isUserInteractionEnabled = false
        view.addSubview(titleDecorationView)

        heroImageView.contentMode = .scaleAspectFit
        heroImageView.isUserInteractionEnabled = false
        view.addSubview(heroImageView)

        setupAgreementViews()

        configureImageButton(signUpButton, imageName: "sign_up_button", label: "Sign up")
        configureImageButton(logInButton, imageName: "log_in_button", label: "Log in")
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        logInButton.addTarget(self, action: #selector(logInTapped), for: .touchUpInside)
        view.addSubview(signUpButton)
        view.addSubview(logInButton)
    }

    private func setupAgreementViews() {
        agreementContainerView.backgroundColor = .clear
        view.addSubview(agreementContainerView)

        agreementCheckButton.layer.borderColor = agreementTintColor.cgColor
        agreementCheckButton.layer.borderWidth = 1.4
        agreementCheckButton.layer.cornerRadius = 4
        agreementCheckButton.setTitleColor(.white, for: .normal)
        agreementCheckButton.addTarget(self, action: #selector(toggleAgreementAccepted), for: .touchUpInside)
        agreementCheckButton.accessibilityTraits = .button
        agreementContainerView.addSubview(agreementCheckButton)

        agreementPrefixLabel.text = "I agree to"
        agreementPrefixLabel.textColor = textColor
        agreementPrefixLabel.textAlignment = .left
        agreementContainerView.addSubview(agreementPrefixLabel)

        configureAgreementLinkButton(userAgreementButton, title: "User Agreement", action: #selector(userAgreementTapped))
        configureAgreementLinkButton(privacyAgreementButton, title: "Privacy Policy", action: #selector(privacyAgreementTapped))
        agreementContainerView.addSubview(userAgreementButton)

        agreementJoinLabel.text = "and"
        agreementJoinLabel.textColor = textColor
        agreementJoinLabel.textAlignment = .center
        agreementContainerView.addSubview(agreementJoinLabel)
        agreementContainerView.addSubview(privacyAgreementButton)

        updateAgreementCheckButton()
    }

    private func configureImageButton(_ button: UIButton, imageName: String, label: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = label
    }

    private func configureAgreementLinkButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(agreementTintColor, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = title
    }

    private func layoutWelcomeContent() {
        let bounds = view.bounds
        let scale = min(bounds.width / Design.size.width, bounds.height / Design.size.height)
        let contentWidth = Design.size.width * scale
        let originX = (bounds.width - contentWidth) / 2

        backgroundImageView.frame = bounds
        titleImageView.frame = scaled(Design.titleFrame, scale: scale, originX: originX)
        heroImageView.frame = scaled(Design.heroFrame, scale: scale, originX: originX)
        agreementContainerView.frame = scaled(Design.agreementFrame, scale: scale, originX: originX)
        signUpButton.frame = scaled(Design.signUpFrame, scale: scale, originX: originX)
        logInButton.frame = scaled(Design.logInFrame, scale: scale, originX: originX)

        titleDecorationView.frame = scaled(CGRect(x: 288, y: 122, width: 64, height: 24), scale: scale, originX: originX)

        let agreementFont = UIFont.systemFont(ofSize: 12.5 * scale, weight: .medium)
        let agreementLinkFont = UIFont.systemFont(ofSize: 12.5 * scale, weight: .semibold)
        agreementPrefixLabel.font = agreementFont
        userAgreementButton.titleLabel?.font = agreementLinkFont
        agreementJoinLabel.font = agreementFont
        privacyAgreementButton.titleLabel?.font = agreementLinkFont

        agreementCheckButton.frame = scaledInsideContainer(CGRect(x: 0, y: 5, width: 18, height: 18), scale: scale)
        agreementCheckButton.layer.cornerRadius = max(3, 4 * scale)
        agreementPrefixLabel.frame = scaledInsideContainer(CGRect(x: 26, y: 0, width: 62, height: 28), scale: scale)
        userAgreementButton.frame = scaledInsideContainer(CGRect(x: 90, y: 0, width: 105, height: 28), scale: scale)
        agreementJoinLabel.frame = scaledInsideContainer(CGRect(x: 196, y: 0, width: 27, height: 28), scale: scale)
        privacyAgreementButton.frame = scaledInsideContainer(CGRect(x: 226, y: 0, width: 98, height: 28), scale: scale)
    }

    private func scaled(_ frame: CGRect, scale: CGFloat, originX: CGFloat) -> CGRect {
        CGRect(
            x: originX + frame.minX * scale,
            y: frame.minY * scale,
            width: frame.width * scale,
            height: frame.height * scale
        ).integral
    }

    private func scaledInsideContainer(_ frame: CGRect, scale: CGFloat) -> CGRect {
        CGRect(
            x: frame.minX * scale,
            y: frame.minY * scale,
            width: frame.width * scale,
            height: frame.height * scale
        ).integral
    }

    @objc private func toggleAgreementAccepted() {
        hasAcceptedAgreements.toggle()
        updateAgreementCheckButton()
    }

    @objc private func signUpTapped() {
        guard guardAgreementAccepted() else { return }

        navigationController?.pushViewController(RegisterViewController(), animated: true)
    }

    @objc private func logInTapped() {
        guard guardAgreementAccepted() else { return }

        navigationController?.pushViewController(LoginViewController(), animated: true)
    }

    @objc private func userAgreementTapped() {
        presentAppDocument(.userAgreement)
    }

    @objc private func privacyAgreementTapped() {
        presentAppDocument(.privacyPolicy)
    }

    private func updateAgreementCheckButton() {
        agreementCheckButton.backgroundColor = hasAcceptedAgreements ? agreementTintColor : .clear
        agreementCheckButton.setTitle(hasAcceptedAgreements ? "✓" : "", for: .normal)
        agreementCheckButton.accessibilityValue = hasAcceptedAgreements ? "Selected" : "Not selected"
    }

    @discardableResult
    private func guardAgreementAccepted() -> Bool {
        guard hasAcceptedAgreements else {
            let alert = UIAlertController(
                title: nil,
                message: "Please agree to the User Agreement and Privacy Policy first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return false
        }

        return true
    }

}

private final class TitleDecorationView: UIView {
    override func draw(_ rect: CGRect) {
        UIColor(red: 0.24, green: 0.22, blue: 0.23, alpha: 0.62).setStroke()

        let markWidth = rect.width / 3
        let strokeWidth = max(1.1, rect.height * 0.06)

        for index in 0..<3 {
            let startX = CGFloat(index) * markWidth + markWidth * 0.72
            let centerX = CGFloat(index) * markWidth + markWidth * 0.28
            let topY = rect.height * 0.2
            let midY = rect.height * 0.52
            let bottomY = rect.height * 0.84

            let path = UIBezierPath()
            path.move(to: CGPoint(x: startX, y: topY))
            path.addCurve(
                to: CGPoint(x: centerX, y: midY),
                controlPoint1: CGPoint(x: startX - markWidth * 0.05, y: topY + rect.height * 0.18),
                controlPoint2: CGPoint(x: centerX + markWidth * 0.08, y: midY - rect.height * 0.12)
            )
            path.addCurve(
                to: CGPoint(x: startX, y: bottomY),
                controlPoint1: CGPoint(x: centerX + markWidth * 0.08, y: midY + rect.height * 0.12),
                controlPoint2: CGPoint(x: startX - markWidth * 0.05, y: bottomY - rect.height * 0.18)
            )
            path.lineWidth = strokeWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }
    }
}
