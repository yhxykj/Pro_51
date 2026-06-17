//
//  RegisterViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class RegisterViewController: UIViewController, UITextFieldDelegate {
    private enum Layout {
        static let topPanelHeight: CGFloat = 108
        static let horizontalInset: CGFloat = 31
        static let pink = UIColor(red: 0.94, green: 0.50, blue: 0.80, alpha: 1.0)
        static let textColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
        static let placeholderColor = UIColor(red: 0.52, green: 0.32, blue: 0.46, alpha: 0.78)
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let whitePanelView = UIView()
    private let backButton = UIButton(type: .custom)
    private let brandTitleImageView = UIImageView(image: UIImage(named: "register_brand_title"))
    private let signUpTitleImageView = UIImageView(image: UIImage(named: "register_sign_up_title"))
    private let emailLabelImageView = UIImageView(image: UIImage(named: "email_label"))
    private let passwordLabelImageView = UIImageView(image: UIImage(named: "password_label"))
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let existingAccountButton = UIButton(type: .custom)
    private let continueButton = UIButton(type: .custom)

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupKeyboardDismissal()
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

        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        configureImageView(brandTitleImageView)
        configureImageView(signUpTitleImageView)
        configureImageView(emailLabelImageView)
        configureImageView(passwordLabelImageView)
        whitePanelView.addSubview(brandTitleImageView)
        whitePanelView.addSubview(signUpTitleImageView)
        whitePanelView.addSubview(emailLabelImageView)
        whitePanelView.addSubview(passwordLabelImageView)

        configureTextField(emailTextField, placeholder: "Please enter...")
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.returnKeyType = .next
        emailTextField.delegate = self
        whitePanelView.addSubview(emailTextField)

        configureTextField(passwordTextField, placeholder: "Please enter...")
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.returnKeyType = .done
        passwordTextField.delegate = self
        whitePanelView.addSubview(passwordTextField)

        configureImageButton(existingAccountButton, imageName: "existing_account_login_prompt", accessibilityLabel: "Already have an account? Log in")
        existingAccountButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        whitePanelView.addSubview(existingAccountButton)

        configureImageButton(continueButton, imageName: "continue_button", accessibilityLabel: "Continue")
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        whitePanelView.addSubview(continueButton)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            whitePanelView,
            backButton,
            brandTitleImageView,
            signUpTitleImageView,
            emailLabelImageView,
            passwordLabelImageView,
            emailTextField,
            passwordTextField,
            existingAccountButton,
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

            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 29),

            brandTitleImageView.topAnchor.constraint(equalTo: whitePanelView.topAnchor, constant: 25),
            brandTitleImageView.leadingAnchor.constraint(equalTo: whitePanelView.leadingAnchor, constant: Layout.horizontalInset),
            brandTitleImageView.widthAnchor.constraint(equalToConstant: 222),
            brandTitleImageView.heightAnchor.constraint(equalToConstant: 37),

            signUpTitleImageView.topAnchor.constraint(equalTo: brandTitleImageView.bottomAnchor, constant: 34),
            signUpTitleImageView.leadingAnchor.constraint(equalTo: brandTitleImageView.leadingAnchor),
            signUpTitleImageView.widthAnchor.constraint(equalToConstant: 89),
            signUpTitleImageView.heightAnchor.constraint(equalToConstant: 32),

            emailLabelImageView.topAnchor.constraint(equalTo: signUpTitleImageView.bottomAnchor, constant: 37),
            emailLabelImageView.leadingAnchor.constraint(equalTo: brandTitleImageView.leadingAnchor),
            emailLabelImageView.widthAnchor.constraint(equalToConstant: 58),
            emailLabelImageView.heightAnchor.constraint(equalToConstant: 33),

            emailTextField.topAnchor.constraint(equalTo: emailLabelImageView.bottomAnchor, constant: 11),
            emailTextField.leadingAnchor.constraint(equalTo: whitePanelView.leadingAnchor, constant: Layout.horizontalInset),
            emailTextField.trailingAnchor.constraint(equalTo: whitePanelView.trailingAnchor, constant: -Layout.horizontalInset),
            emailTextField.heightAnchor.constraint(equalToConstant: 47),

            passwordLabelImageView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 19),
            passwordLabelImageView.leadingAnchor.constraint(equalTo: brandTitleImageView.leadingAnchor),
            passwordLabelImageView.widthAnchor.constraint(equalToConstant: 91),
            passwordLabelImageView.heightAnchor.constraint(equalToConstant: 33),

            passwordTextField.topAnchor.constraint(equalTo: passwordLabelImageView.bottomAnchor, constant: 11),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),

            existingAccountButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 43),
            existingAccountButton.centerXAnchor.constraint(equalTo: whitePanelView.centerXAnchor),
            existingAccountButton.widthAnchor.constraint(equalToConstant: 281),
            existingAccountButton.heightAnchor.constraint(equalToConstant: 24),

            continueButton.topAnchor.constraint(equalTo: existingAccountButton.bottomAnchor, constant: 120),
            continueButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            continueButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            continueButton.heightAnchor.constraint(equalToConstant: 64),
            continueButton.bottomAnchor.constraint(lessThanOrEqualTo: whitePanelView.safeAreaLayoutGuide.bottomAnchor, constant: -36)
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

    @objc private func loginTapped() {
        navigationController?.pushViewController(LoginViewController(), animated: true)
    }

    @objc private func continueTapped() {
        view.endEditing(true)
        navigationController?.pushViewController(EditProfileViewController(), animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
