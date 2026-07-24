//
//  LoginViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class LoginViewController: UIViewController, UITextFieldDelegate {
    private enum Layout {
        static let topPanelHeight: CGFloat = 108
        static let horizontalInset: CGFloat = 31
        static let pink = UIColor(red: 0.94, green: 0.50, blue: 0.80, alpha: 1.0)
        static let textColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
        static let placeholderColor = UIColor(red: 0.52, green: 0.32, blue: 0.46, alpha: 0.78)
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let whitePanelView = UIView()
    private let formScrollView = UIScrollView()
    private let formContentView = UIView()
    private let backButton = UIButton(type: .custom)
    private let brandTitleImageView = UIImageView(image: UIImage(named: "register_brand_title"))
    private let logInTitleImageView = UIImageView(image: UIImage(named: "login_title"))
    private let emailLabelImageView = UIImageView(image: UIImage(named: "email_label"))
    private let passwordLabelImageView = UIImageView(image: UIImage(named: "password_label"))
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let createAccountButton = UIButton(type: .custom)
    private let continueButton = UIButton(type: .custom)
    private weak var activeTextField: UITextField?

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupKeyboardDismissal()
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.isUserInteractionEnabled = false
        view.addSubview(backgroundImageView)

        whitePanelView.backgroundColor = .white
        whitePanelView.layer.cornerRadius = 28
        whitePanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        whitePanelView.layer.masksToBounds = true
        view.addSubview(whitePanelView)

        formScrollView.showsVerticalScrollIndicator = false
        formScrollView.alwaysBounceVertical = true
        formScrollView.keyboardDismissMode = .interactive
        whitePanelView.addSubview(formScrollView)
        formScrollView.addSubview(formContentView)

        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        configureImageView(brandTitleImageView)
        configureImageView(logInTitleImageView)
        configureImageView(emailLabelImageView)
        configureImageView(passwordLabelImageView)
        formContentView.addSubview(brandTitleImageView)
        formContentView.addSubview(logInTitleImageView)
        formContentView.addSubview(emailLabelImageView)
        formContentView.addSubview(passwordLabelImageView)

        configureTextField(emailTextField, placeholder: "Please enter...")
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.returnKeyType = .next
        emailTextField.delegate = self
        formContentView.addSubview(emailTextField)

        configureTextField(passwordTextField, placeholder: "Please enter...")
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.returnKeyType = .done
        passwordTextField.delegate = self
        formContentView.addSubview(passwordTextField)

        configureImageButton(createAccountButton, imageName: "create_account_signup_prompt", accessibilityLabel: "Don't have an account yet? Sign up")
        createAccountButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        formContentView.addSubview(createAccountButton)

        configureImageButton(continueButton, imageName: "continue_button", accessibilityLabel: "Continue")
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        formContentView.addSubview(continueButton)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            whitePanelView,
            formScrollView,
            formContentView,
            backButton,
            brandTitleImageView,
            logInTitleImageView,
            emailLabelImageView,
            passwordLabelImageView,
            emailTextField,
            passwordTextField,
            createAccountButton,
            continueButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            whitePanelView.topAnchor.constraint(equalTo: view.topAnchor, constant: Layout.topPanelHeight),
            whitePanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            whitePanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            whitePanelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            formScrollView.topAnchor.constraint(equalTo: whitePanelView.topAnchor),
            formScrollView.leadingAnchor.constraint(equalTo: whitePanelView.leadingAnchor),
            formScrollView.trailingAnchor.constraint(equalTo: whitePanelView.trailingAnchor),
            formScrollView.bottomAnchor.constraint(equalTo: whitePanelView.bottomAnchor),

            formContentView.topAnchor.constraint(equalTo: formScrollView.contentLayoutGuide.topAnchor),
            formContentView.leadingAnchor.constraint(equalTo: formScrollView.contentLayoutGuide.leadingAnchor),
            formContentView.trailingAnchor.constraint(equalTo: formScrollView.contentLayoutGuide.trailingAnchor),
            formContentView.bottomAnchor.constraint(equalTo: formScrollView.contentLayoutGuide.bottomAnchor),
            formContentView.widthAnchor.constraint(equalTo: formScrollView.frameLayoutGuide.widthAnchor),
            formContentView.heightAnchor.constraint(greaterThanOrEqualTo: formScrollView.frameLayoutGuide.heightAnchor),

            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 29),

            brandTitleImageView.topAnchor.constraint(equalTo: formContentView.topAnchor, constant: 25),
            brandTitleImageView.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: Layout.horizontalInset),
            brandTitleImageView.widthAnchor.constraint(equalToConstant: 222),
            brandTitleImageView.heightAnchor.constraint(equalToConstant: 37),

            logInTitleImageView.topAnchor.constraint(equalTo: brandTitleImageView.bottomAnchor, constant: 34),
            logInTitleImageView.leadingAnchor.constraint(equalTo: brandTitleImageView.leadingAnchor),
            logInTitleImageView.widthAnchor.constraint(equalToConstant: 72),
            logInTitleImageView.heightAnchor.constraint(equalToConstant: 32),

            emailLabelImageView.topAnchor.constraint(equalTo: logInTitleImageView.bottomAnchor, constant: 37),
            emailLabelImageView.leadingAnchor.constraint(equalTo: brandTitleImageView.leadingAnchor),
            emailLabelImageView.widthAnchor.constraint(equalToConstant: 58),
            emailLabelImageView.heightAnchor.constraint(equalToConstant: 33),

            emailTextField.topAnchor.constraint(equalTo: emailLabelImageView.bottomAnchor, constant: 11),
            emailTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: Layout.horizontalInset),
            emailTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -Layout.horizontalInset),
            emailTextField.heightAnchor.constraint(equalToConstant: 47),

            passwordLabelImageView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 19),
            passwordLabelImageView.leadingAnchor.constraint(equalTo: brandTitleImageView.leadingAnchor),
            passwordLabelImageView.widthAnchor.constraint(equalToConstant: 91),
            passwordLabelImageView.heightAnchor.constraint(equalToConstant: 33),

            passwordTextField.topAnchor.constraint(equalTo: passwordLabelImageView.bottomAnchor, constant: 11),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),

            createAccountButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 43),
            createAccountButton.centerXAnchor.constraint(equalTo: formContentView.centerXAnchor),
            createAccountButton.widthAnchor.constraint(equalToConstant: 304),
            createAccountButton.heightAnchor.constraint(equalToConstant: 24),

            continueButton.topAnchor.constraint(equalTo: createAccountButton.bottomAnchor, constant: 52),
            continueButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            continueButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            continueButton.heightAnchor.constraint(equalToConstant: 64),
            formContentView.bottomAnchor.constraint(greaterThanOrEqualTo: continueButton.bottomAnchor, constant: 36)
        ])
    }

    private func configureImageView(_ imageView: UIImageView) {
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
    }

    private func configureImageButton(_ button: UIButton, imageName: String, accessibilityLabel: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.accessibilityLabel = accessibilityLabel
    }

    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = Layout.pink
        textField.layer.cornerRadius = 23.5
        textField.layer.masksToBounds = true
        textField.textColor = Layout.textColor
        textField.font = italicFont(size: 18, weight: .semibold)
        textField.leftView = makePaddingView()
        textField.leftViewMode = .always
        textField.rightView = makePaddingView()
        textField.rightViewMode = .always
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: Layout.placeholderColor,
                .font: italicFont(size: 17, weight: .semibold)
            ]
        )
    }

    private func italicFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
        guard let italicDescriptor = descriptor.withSymbolicTraits(.traitItalic) else {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }

        return UIFont(descriptor: italicDescriptor, size: size)
    }

    private func makePaddingView() -> UILabel {
        let label = UILabel()
        label.text = "    "
        return label
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func updateKeyboardInset(from notification: Notification, isHiding: Bool) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        var bottomInset: CGFloat = 0
        if isHiding == false,
           let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardFrame = view.convert(keyboardValue.cgRectValue, from: nil)
            let scrollFrame = formScrollView.convert(formScrollView.bounds, to: view)
            bottomInset = max(0, scrollFrame.maxY - keyboardFrame.minY) + 20
        }

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.formScrollView.contentInset.bottom = bottomInset
            self.formScrollView.scrollIndicatorInsets.bottom = bottomInset
            self.view.layoutIfNeeded()
        } completion: { _ in
            if isHiding == false {
                self.scrollActiveTextFieldIntoView()
            }
        }
    }

    private func scrollActiveTextFieldIntoView() {
        guard let activeTextField else { return }
        let targetRect = activeTextField.convert(
            activeTextField.bounds.insetBy(dx: 0, dy: -18),
            to: formScrollView
        )
        formScrollView.scrollRectToVisible(targetRect, animated: true)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        scrollActiveTextFieldIntoView()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeTextField === textField {
            activeTextField = nil
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }

        return true
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func signUpTapped() {
        navigationController?.pushViewController(RegisterViewController(), animated: true)
    }

    @objc private func continueTapped() {
        view.endEditing(true)
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        guard AuthSession.canSignIn(email: email, password: password) else {
            showSignInFailedAlert()
            return
        }

        AuthSession.start(email: email)
        navigationController?.setViewControllers([MainTabBarController()], animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        updateKeyboardInset(from: notification, isHiding: false)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        updateKeyboardInset(from: notification, isHiding: true)
    }

    private func showSignInFailedAlert() {
        let alert = UIAlertController(
            title: "Login failed",
            message: "Please check your email and password, or create an account first.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
