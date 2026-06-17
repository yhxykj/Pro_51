//
//  HomeMediaCollectionViewCell.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class HomeMediaCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "HomeMediaCollectionViewCell"

    private let mediaImageView = UIImageView()
    private var videoConstraints: [NSLayoutConstraint] = []
    private var audioConstraints: [NSLayoutConstraint] = []
    private var didSetupViews = false

    func configure(imageName: String, isAudio: Bool) {
        setupIfNeeded()
        mediaImageView.image = UIImage(named: imageName)
        mediaImageView.contentMode = isAudio ? .scaleAspectFit : .scaleAspectFill
        mediaImageView.layer.cornerRadius = isAudio ? 0 : 18
        mediaImageView.clipsToBounds = !isAudio

        NSLayoutConstraint.deactivate(isAudio ? videoConstraints : audioConstraints)
        NSLayoutConstraint.activate(isAudio ? audioConstraints : videoConstraints)
    }

    private func setupIfNeeded() {
        guard !didSetupViews else { return }

        didSetupViews = true
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        mediaImageView.backgroundColor = .clear
        contentView.addSubview(mediaImageView)
    }

    private func setupConstraints() {
        mediaImageView.translatesAutoresizingMaskIntoConstraints = false

        videoConstraints = [
            mediaImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mediaImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mediaImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mediaImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        audioConstraints = [
            mediaImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mediaImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            mediaImageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.84),
            mediaImageView.heightAnchor.constraint(equalTo: mediaImageView.widthAnchor),
            mediaImageView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor, multiplier: 0.96)
        ]

        NSLayoutConstraint.activate(videoConstraints)
    }
}
