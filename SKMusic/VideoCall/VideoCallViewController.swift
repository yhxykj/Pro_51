//
//  VideoCallViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/18.
//

import UIKit

final class VideoCallViewController: UIViewController {
    private let speakerButton = UIButton(type: .custom)
    private let micButton = UIButton(type: .custom)
    private var isSpeakerOn = true
    private var isMicOn = true

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateToggleButtons()
    }

    private func setupViews() {
        view.backgroundColor = .black

        let backgroundImageView = UIImageView(image: UIImage(named: "video_cover"))
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)

        let dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.13)
        view.addSubview(dimView)

        let bottomGradientImageView = UIImageView(image: UIImage(named: "video_call_bottom_gradient"))
        bottomGradientImageView.contentMode = .scaleToFill
        view.addSubview(bottomGradientImageView)

        let backButton = UIButton(type: .custom)
        configureImageButton(backButton, imageName: "back_button")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let nameLabel = UILabel()
        nameLabel.text = "Angela"
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.font = Self.nameFont
        view.addSubview(nameLabel)

        let endButton = UIButton(type: .custom)
        configureImageButton(endButton, imageName: "video_call_end")
        endButton.addTarget(self, action: #selector(endTapped), for: .touchUpInside)
        view.addSubview(endButton)

        configureImageButton(speakerButton, imageName: "video_call_speaker_on")
        speakerButton.addTarget(self, action: #selector(speakerTapped), for: .touchUpInside)
        view.addSubview(speakerButton)

        configureImageButton(micButton, imageName: "video_call_mic_on")
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        view.addSubview(micButton)

        [
            backgroundImageView,
            dimView,
            bottomGradientImageView,
            backButton,
            nameLabel,
            speakerButton,
            endButton,
            micButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomGradientImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomGradientImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomGradientImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomGradientImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.64),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 29),

            nameLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 150),
            nameLabel.heightAnchor.constraint(equalToConstant: 38),

            endButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -57),
            endButton.widthAnchor.constraint(equalToConstant: 87),
            endButton.heightAnchor.constraint(equalTo: endButton.widthAnchor),

            speakerButton.centerYAnchor.constraint(equalTo: endButton.centerYAnchor),
            speakerButton.trailingAnchor.constraint(equalTo: endButton.leadingAnchor, constant: -42),
            speakerButton.widthAnchor.constraint(equalToConstant: 65),
            speakerButton.heightAnchor.constraint(equalTo: speakerButton.widthAnchor),

            micButton.centerYAnchor.constraint(equalTo: endButton.centerYAnchor),
            micButton.leadingAnchor.constraint(equalTo: endButton.trailingAnchor, constant: 42),
            micButton.widthAnchor.constraint(equalTo: speakerButton.widthAnchor),
            micButton.heightAnchor.constraint(equalTo: micButton.widthAnchor)
        ])
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
    }

    private func updateToggleButtons() {
        speakerButton.setImage(
            UIImage(named: isSpeakerOn ? "video_call_speaker_on" : "video_call_speaker_off"),
            for: .normal
        )
        micButton.setImage(
            UIImage(named: isMicOn ? "video_call_mic_on" : "video_call_mic_off"),
            for: .normal
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func endTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func speakerTapped() {
        isSpeakerOn.toggle()
        updateToggleButtons()
    }

    @objc private func micTapped() {
        isMicOn.toggle()
        updateToggleButtons()
    }

    private static var nameFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 24) ?? .italicSystemFont(ofSize: 24)
    }
}
