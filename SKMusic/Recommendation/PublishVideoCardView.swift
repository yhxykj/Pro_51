//
//  PublishVideoCardView.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class PublishVideoCardView: UIView, UITextViewDelegate {
    struct FormValues {
        let releaseType: String
        let videoTitle: String
        let songIntroduction: String
    }

    var onClose: (() -> Void)?
    var onChooseVideo: (() -> Void)?
    var onRelease: ((FormValues) -> Void)?

    private weak var releaseTypeField: UITextField?
    private weak var videoTitleField: UITextField?
    private weak var introductionTextView: UITextView?
    private let uploadHintLabel = UILabel()
    private let uploadPreviewImageView = UIImageView()
    private let uploadAddImageView = UIImageView(image: UIImage(named: "recommendation_add_button"))
    private let introductionPlaceholderLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func updateSelectedVideo(name: String, thumbnail: UIImage?) {
        uploadHintLabel.text = name.isEmpty ? "Selected video" : name
        uploadHintLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        uploadPreviewImageView.image = thumbnail
        uploadPreviewImageView.isHidden = thumbnail == nil
        uploadAddImageView.isHidden = thumbnail != nil
    }

    func resetSelection() {
        uploadHintLabel.text = "Please add MP4 video......."
        uploadHintLabel.textColor = UIColor(red: 0.54, green: 0.54, blue: 0.55, alpha: 1)
        uploadPreviewImageView.image = nil
        uploadPreviewImageView.isHidden = true
        uploadAddImageView.isHidden = false
    }

    func textViewDidChange(_ textView: UITextView) {
        introductionPlaceholderLabel.isHidden = !textView.text.isEmpty
    }

    private func setupViews() {
        backgroundColor = .clear

        let cardImageView = UIImageView(image: UIImage(named: "recommendation_publish_card_background"))
        cardImageView.contentMode = .scaleToFill
        addSubview(cardImageView)

        let publishTitleImageView = UIImageView(image: UIImage(named: "recommendation_publish_title"))
        publishTitleImageView.contentMode = .scaleAspectFit
        addSubview(publishTitleImageView)

        let releaseTypeField = makePublishTextField(placeholder: "Plaese Type")
        self.releaseTypeField = releaseTypeField
        addSubview(releaseTypeField)

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevronImageView.tintColor = UIColor(red: 0.57, green: 0.57, blue: 0.58, alpha: 1)
        chevronImageView.contentMode = .scaleAspectFit
        releaseTypeField.addSubview(chevronImageView)

        let videoTitleField = makePublishTextField(placeholder: "video title ..........")
        self.videoTitleField = videoTitleField
        addSubview(videoTitleField)

        let introductionTextView = makePublishTextView(placeholder: "Song Introduction ..........")
        self.introductionTextView = introductionTextView
        addSubview(introductionTextView)

        let uploadView = UIView()
        uploadView.backgroundColor = .white
        uploadView.layer.cornerRadius = 14
        uploadView.clipsToBounds = true
        uploadView.isUserInteractionEnabled = true
        uploadView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(uploadTapped)))
        addSubview(uploadView)

        uploadPreviewImageView.contentMode = .scaleAspectFill
        uploadPreviewImageView.isHidden = true
        uploadView.addSubview(uploadPreviewImageView)

        uploadAddImageView.contentMode = .scaleAspectFit
        uploadView.addSubview(uploadAddImageView)

        uploadHintLabel.text = "Please add MP4 video......."
        uploadHintLabel.textColor = UIColor(red: 0.54, green: 0.54, blue: 0.55, alpha: 1)
        uploadHintLabel.font = Self.publishHintFont
        addSubview(uploadHintLabel)

        let releaseButton = UIButton(type: .custom)
        releaseButton.backgroundColor = UIColor(red: 249 / 255, green: 148 / 255, blue: 213 / 255, alpha: 1)
        releaseButton.layer.cornerRadius = 28
        releaseButton.layer.shadowColor = UIColor(red: 0.96, green: 0.38, blue: 0.75, alpha: 1).cgColor
        releaseButton.layer.shadowOpacity = 0.35
        releaseButton.layer.shadowRadius = 8
        releaseButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        releaseButton.setTitle("RELEASE", for: .normal)
        releaseButton.setTitleColor(.white, for: .normal)
        releaseButton.titleLabel?.font = Self.releaseButtonFont
        releaseButton.addTarget(self, action: #selector(releaseTapped), for: .touchUpInside)
        addSubview(releaseButton)

        let releaseCoinImageView = UIImageView(image: UIImage(named: "recommendation_coin_icon"))
        releaseCoinImageView.contentMode = .scaleAspectFit
        releaseButton.addSubview(releaseCoinImageView)

        let closeButton = UIButton(type: .custom)
        configureImageButton(closeButton, imageName: "report_popup_back_button")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        addSubview(closeButton)

        [
            cardImageView,
            publishTitleImageView,
            releaseTypeField,
            chevronImageView,
            videoTitleField,
            introductionTextView,
            uploadView,
            uploadPreviewImageView,
            uploadAddImageView,
            uploadHintLabel,
            releaseButton,
            releaseCoinImageView,
            closeButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardImageView.topAnchor.constraint(equalTo: topAnchor),
            cardImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardImageView.heightAnchor.constraint(equalToConstant: 552),

            publishTitleImageView.topAnchor.constraint(equalTo: cardImageView.topAnchor, constant: 22),
            publishTitleImageView.leadingAnchor.constraint(equalTo: cardImageView.leadingAnchor, constant: 12),
            publishTitleImageView.widthAnchor.constraint(equalToConstant: 84),
            publishTitleImageView.heightAnchor.constraint(equalToConstant: 24),

            releaseTypeField.topAnchor.constraint(equalTo: publishTitleImageView.bottomAnchor, constant: 14),
            releaseTypeField.leadingAnchor.constraint(equalTo: cardImageView.leadingAnchor, constant: 15),
            releaseTypeField.trailingAnchor.constraint(equalTo: cardImageView.trailingAnchor, constant: -15),
            releaseTypeField.heightAnchor.constraint(equalToConstant: 53),

            chevronImageView.trailingAnchor.constraint(equalTo: releaseTypeField.trailingAnchor, constant: -28),
            chevronImageView.centerYAnchor.constraint(equalTo: releaseTypeField.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 18),
            chevronImageView.heightAnchor.constraint(equalToConstant: 11),

            videoTitleField.topAnchor.constraint(equalTo: releaseTypeField.bottomAnchor, constant: 8.5),
            videoTitleField.leadingAnchor.constraint(equalTo: releaseTypeField.leadingAnchor),
            videoTitleField.trailingAnchor.constraint(equalTo: releaseTypeField.trailingAnchor),
            videoTitleField.heightAnchor.constraint(equalToConstant: 53),

            introductionTextView.topAnchor.constraint(equalTo: videoTitleField.bottomAnchor, constant: 8.5),
            introductionTextView.leadingAnchor.constraint(equalTo: releaseTypeField.leadingAnchor),
            introductionTextView.trailingAnchor.constraint(equalTo: releaseTypeField.trailingAnchor),
            introductionTextView.heightAnchor.constraint(equalToConstant: 122),

            uploadView.topAnchor.constraint(equalTo: introductionTextView.bottomAnchor, constant: 8.5),
            uploadView.leadingAnchor.constraint(equalTo: releaseTypeField.leadingAnchor),
            uploadView.trailingAnchor.constraint(equalTo: releaseTypeField.trailingAnchor),
            uploadView.heightAnchor.constraint(equalToConstant: 105),

            uploadPreviewImageView.topAnchor.constraint(equalTo: uploadView.topAnchor),
            uploadPreviewImageView.leadingAnchor.constraint(equalTo: uploadView.leadingAnchor),
            uploadPreviewImageView.trailingAnchor.constraint(equalTo: uploadView.trailingAnchor),
            uploadPreviewImageView.bottomAnchor.constraint(equalTo: uploadView.bottomAnchor),

            uploadAddImageView.centerXAnchor.constraint(equalTo: uploadView.centerXAnchor),
            uploadAddImageView.centerYAnchor.constraint(equalTo: uploadView.centerYAnchor),
            uploadAddImageView.widthAnchor.constraint(equalToConstant: 54),
            uploadAddImageView.heightAnchor.constraint(equalTo: uploadAddImageView.widthAnchor),

            uploadHintLabel.topAnchor.constraint(equalTo: uploadView.bottomAnchor, constant: 10),
            uploadHintLabel.leadingAnchor.constraint(equalTo: cardImageView.leadingAnchor, constant: 31),
            uploadHintLabel.trailingAnchor.constraint(equalTo: cardImageView.trailingAnchor, constant: -24),
            uploadHintLabel.heightAnchor.constraint(equalToConstant: 22),

            releaseButton.leadingAnchor.constraint(equalTo: releaseTypeField.leadingAnchor),
            releaseButton.trailingAnchor.constraint(equalTo: releaseTypeField.trailingAnchor),
            releaseButton.bottomAnchor.constraint(equalTo: cardImageView.bottomAnchor, constant: -38),
            releaseButton.heightAnchor.constraint(equalToConstant: 56),

            releaseCoinImageView.trailingAnchor.constraint(equalTo: releaseButton.trailingAnchor, constant: -29),
            releaseCoinImageView.centerYAnchor.constraint(equalTo: releaseButton.centerYAnchor),
            releaseCoinImageView.widthAnchor.constraint(equalToConstant: 30),
            releaseCoinImageView.heightAnchor.constraint(equalTo: releaseCoinImageView.widthAnchor),

            closeButton.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: cardImageView.bottomAnchor, constant: 34),
            closeButton.widthAnchor.constraint(equalToConstant: 61),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
    }

    private func makePublishTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 14
        textField.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        textField.font = Self.publishFieldFont
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(red: 0.54, green: 0.54, blue: 0.55, alpha: 1),
                .font: Self.publishFieldFont
            ]
        )

        let leftPaddingView = UIView()
        leftPaddingView.translatesAutoresizingMaskIntoConstraints = false
        leftPaddingView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return textField
    }

    private func makePublishTextView(placeholder: String) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 14
        textView.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        textView.font = Self.publishFieldFont
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 10, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self

        introductionPlaceholderLabel.text = placeholder
        introductionPlaceholderLabel.textColor = UIColor(red: 0.54, green: 0.54, blue: 0.55, alpha: 1)
        introductionPlaceholderLabel.font = Self.publishFieldFont
        introductionPlaceholderLabel.isUserInteractionEnabled = false
        textView.addSubview(introductionPlaceholderLabel)

        introductionPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            introductionPlaceholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 14),
            introductionPlaceholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            introductionPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -14),
            introductionPlaceholderLabel.heightAnchor.constraint(equalToConstant: 24)
        ])

        return textView
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
    }

    @objc private func uploadTapped() {
        onChooseVideo?()
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func releaseTapped() {
        endEditing(true)

        onRelease?(
            FormValues(
                releaseType: trimmedText(from: releaseTypeField),
                videoTitle: trimmedText(from: videoTitleField),
                songIntroduction: introductionTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            )
        )
    }

    private func trimmedText(from textField: UITextField?) -> String {
        textField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static var publishFieldFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 15) ?? .italicSystemFont(ofSize: 15)
    }

    private static var publishHintFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 14) ?? .italicSystemFont(ofSize: 14)
    }

    private static var releaseButtonFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
    }
}
