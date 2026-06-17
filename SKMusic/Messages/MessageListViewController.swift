//
//  MessageListViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class MessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private enum HeaderSelection {
        case message
        case friend
    }

    private struct MessageItem {
        let title: String
        let subtitle: String
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let messageHeaderButton = UIButton(type: .custom)
    private let friendHeaderButton = UIButton(type: .custom)
    private let selectedIndicatorView = UIView()
    private let tableView = UITableView()
    private let messageItems = [
        MessageItem(title: "Massages", subtitle: "This is my first time sharin ........"),
        MessageItem(title: "Massages", subtitle: "This is my first time sharin ........"),
        MessageItem(title: "Massages", subtitle: "This is my first time sharin ........")
    ]

    private var selectedHeader: HeaderSelection = .message
    private var selectedIndicatorCenterXConstraint: NSLayoutConstraint!
    private weak var openCell: MessageTableViewCell?

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

        configureHeaderButton(
            messageHeaderButton,
            normalImageName: "message_header_normal",
            selectedImageName: "message_header_selected",
            accessibilityLabel: "Message"
        )
        configureHeaderButton(
            friendHeaderButton,
            normalImageName: "friend_header_normal",
            selectedImageName: "friend_header_selected",
            accessibilityLabel: "Friend"
        )
        messageHeaderButton.isSelected = true

        [messageHeaderButton, friendHeaderButton].forEach { button in
            button.backgroundColor = .clear
            view.addSubview(button)
        }
        messageHeaderButton.addTarget(self, action: #selector(messageHeaderTapped), for: .touchUpInside)
        friendHeaderButton.addTarget(self, action: #selector(friendHeaderTapped), for: .touchUpInside)

        selectedIndicatorView.backgroundColor = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1)
        selectedIndicatorView.layer.cornerRadius = 3
        selectedIndicatorView.clipsToBounds = true
        selectedIndicatorView.isUserInteractionEnabled = false
        view.addSubview(selectedIndicatorView)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            messageHeaderButton,
            friendHeaderButton,
            selectedIndicatorView,
            tableView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        selectedIndicatorCenterXConstraint = selectedIndicatorView.centerXAnchor.constraint(equalTo: messageHeaderButton.centerXAnchor)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            messageHeaderButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            messageHeaderButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            messageHeaderButton.widthAnchor.constraint(equalToConstant: 116),
            messageHeaderButton.heightAnchor.constraint(equalToConstant: 52),

            friendHeaderButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 55),
            friendHeaderButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 151),
            friendHeaderButton.widthAnchor.constraint(equalToConstant: 74),
            friendHeaderButton.heightAnchor.constraint(equalToConstant: 48),

            selectedIndicatorView.topAnchor.constraint(equalTo: view.topAnchor, constant: 96),
            selectedIndicatorCenterXConstraint,
            selectedIndicatorView.widthAnchor.constraint(equalToConstant: 6),
            selectedIndicatorView.heightAnchor.constraint(equalToConstant: 6),

            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 110),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        86
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.reuseIdentifier, for: indexPath) as? MessageTableViewCell
        else {
            return UITableViewCell()
        }

        let item = messageItems[indexPath.row]
        cell.configure(title: item.title, subtitle: item.subtitle)
        cell.onWillOpen = { [weak self, weak cell] in
            guard let self, let cell else { return }
            if self.openCell !== cell {
                self.openCell?.close(animated: true)
            }
            self.openCell = cell
        }
        cell.onDidClose = { [weak self, weak cell] in
            guard let self, let cell else { return }
            if self.openCell === cell {
                self.openCell = nil
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let openCell {
            openCell.close(animated: true)
            return
        }

        let navigationController = navigationController ?? parent?.navigationController
        navigationController?.pushViewController(FriendChatViewController(), animated: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        closeOpenCell()
    }

    private func setHeaderSelection(_ selection: HeaderSelection, animated: Bool) {
        guard selectedHeader != selection else { return }

        selectedHeader = selection
        closeOpenCell()
        selectedIndicatorCenterXConstraint.isActive = false
        selectedIndicatorCenterXConstraint = selectedIndicatorView.centerXAnchor.constraint(
            equalTo: selection == .message ? messageHeaderButton.centerXAnchor : friendHeaderButton.centerXAnchor
        )
        selectedIndicatorCenterXConstraint.isActive = true

        messageHeaderButton.isSelected = selection == .message
        friendHeaderButton.isSelected = selection == .friend
        tableView.reloadData()

        let updates = {
            self.view.layoutIfNeeded()
        }

        guard animated else {
            updates()
            return
        }

        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut], animations: updates)
    }

    @objc private func messageHeaderTapped() {
        setHeaderSelection(.message, animated: true)
    }

    @objc private func friendHeaderTapped() {
        setHeaderSelection(.friend, animated: true)
    }

    private func closeOpenCell() {
        openCell?.close(animated: true)
        openCell = nil
    }

    private func configureHeaderButton(
        _ button: UIButton,
        normalImageName: String,
        selectedImageName: String,
        accessibilityLabel: String
    ) {
        button.setImage(UIImage(named: normalImageName), for: .normal)
        button.setImage(UIImage(named: selectedImageName), for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
        button.accessibilityLabel = accessibilityLabel
    }
}
