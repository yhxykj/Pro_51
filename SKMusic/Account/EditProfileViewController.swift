//
//  EditProfileViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import PhotosUI
import UIKit

final class EditProfileViewController: UIViewController, UITextFieldDelegate, PHPickerViewControllerDelegate {
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
    private let avatarButton = UIButton(type: .custom)
    private let nicknameLabelImageView = UIImageView(image: UIImage(named: "nickname_label"))
    private let nicknameTextField = UITextField()
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
        configureImageView(nicknameLabelImageView)
        whitePanelView.addSubview(brandTitleImageView)
        whitePanelView.addSubview(signUpTitleImageView)
        whitePanelView.addSubview(nicknameLabelImageView)

        configureImageButton(avatarButton, imageName: "avatar_picker", accessibilityLabel: "Choose avatar")
        avatarButton.imageView?.contentMode = .scaleAspectFill
        avatarButton.clipsToBounds = true
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        whitePanelView.addSubview(avatarButton)

        configureTextField(nicknameTextField, placeholder: "Please enter...")
        nicknameTextField.textContentType = .nickname
        nicknameTextField.returnKeyType = .done
        nicknameTextField.delegate = self
        whitePanelView.addSubview(nicknameTextField)

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
            avatarButton,
            nicknameLabelImageView,
            nicknameTextField,
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

            avatarButton.topAnchor.constraint(equalTo: signUpTitleImageView.bottomAnchor, constant: 24),
            avatarButton.centerXAnchor.constraint(equalTo: whitePanelView.centerXAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: 132),
            avatarButton.heightAnchor.constraint(equalTo: avatarButton.widthAnchor),

            nicknameLabelImageView.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 31),
            nicknameLabelImageView.centerXAnchor.constraint(equalTo: whitePanelView.centerXAnchor),
            nicknameLabelImageView.widthAnchor.constraint(equalToConstant: 95),
            nicknameLabelImageView.heightAnchor.constraint(equalToConstant: 33),

            nicknameTextField.topAnchor.constraint(equalTo: nicknameLabelImageView.bottomAnchor, constant: 14),
            nicknameTextField.leadingAnchor.constraint(equalTo: whitePanelView.leadingAnchor, constant: Layout.horizontalInset),
            nicknameTextField.trailingAnchor.constraint(equalTo: whitePanelView.trailingAnchor, constant: -Layout.horizontalInset),
            nicknameTextField.heightAnchor.constraint(equalToConstant: 47),

            continueButton.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 158),
            continueButton.leadingAnchor.constraint(equalTo: nicknameTextField.leadingAnchor),
            continueButton.trailingAnchor.constraint(equalTo: nicknameTextField.trailingAnchor),
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
        view.endEditing(true)
        return true
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }

            DispatchQueue.main.async {
                self?.avatarButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func avatarTapped() {
        view.endEditing(true)

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func continueTapped() {
        view.endEditing(true)
        navigationController?.setViewControllers([MainTabBarController()], animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
