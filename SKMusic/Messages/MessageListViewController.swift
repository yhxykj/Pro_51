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
        let peerName: String
        let avatarImageName: String
    }

    private struct FriendItem {
        let name: String
        let avatarImageName: String
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let messageHeaderButton = UIButton(type: .custom)
    private let friendHeaderButton = UIButton(type: .custom)
    private let selectedIndicatorView = UIView()
    private let tableView = UITableView()
    private let emptyStateContainerView = UIView()
    private let emptyStateImageView = UIImageView(image: UIImage(named: "huaban-5102107231"))
    private let emptyStateLabel = UILabel()
    private var messageItems: [MessageItem] = []
    private var friendItems: [FriendItem] = []

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
        reloadFriendItems()
        reloadMessageItems()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatConversationsDidChange),
            name: .chatConversationsDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFriendItems()
        reloadMessageItems()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        tableView.register(FriendTableViewCell.self, forCellReuseIdentifier: FriendTableViewCell.reuseIdentifier)
        view.addSubview(tableView)

        emptyStateContainerView.isHidden = true
        emptyStateContainerView.isUserInteractionEnabled = false
        view.addSubview(emptyStateContainerView)

        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateContainerView.addSubview(emptyStateImageView)

        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        emptyStateLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
        emptyStateContainerView.addSubview(emptyStateLabel)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            messageHeaderButton,
            friendHeaderButton,
            selectedIndicatorView,
            tableView,
            emptyStateContainerView,
            emptyStateImageView,
            emptyStateLabel
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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateContainerView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 132),
            emptyStateContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.72),

            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateContainerView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 156),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 143),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 15),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateContainerView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateContainerView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateContainerView.bottomAnchor),
            emptyStateLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedHeader == .message ? messageItems.count : friendItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        selectedHeader == .message ? 86 : 54
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedHeader == .friend {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: FriendTableViewCell.reuseIdentifier, for: indexPath) as? FriendTableViewCell
            else {
                return UITableViewCell()
            }

            let item = friendItems[indexPath.row]
            cell.configure(name: item.name, avatarImageName: item.avatarImageName)
            cell.onChatTapped = { [weak self] in
                self?.openChat(peerName: item.name, avatarImageName: item.avatarImageName)
            }
            return cell
        }

        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.reuseIdentifier, for: indexPath) as? MessageTableViewCell
        else {
            return UITableViewCell()
        }

        let item = messageItems[indexPath.row]
        cell.configure(title: item.title, subtitle: item.subtitle, avatarImageName: item.avatarImageName)
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
        if selectedHeader == .friend {
            let item = friendItems[indexPath.row]
            navigationController?.pushViewController(
                UserProfileViewController(displayName: item.name, avatarImageName: item.avatarImageName),
                animated: true
            )
        } else {
            let item = messageItems[indexPath.row]
            openChat(peerName: item.peerName, avatarImageName: item.avatarImageName)
        }
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
        updateEmptyState()

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

    private func reloadMessageItems() {
        messageItems = ChatConversationStore.shared.allConversations().filter {
            FriendStore.shared.isFriend(name: $0.peerName)
        }.map {
            MessageItem(
                title: $0.peerName,
                subtitle: $0.lastMessage,
                peerName: $0.peerName,
                avatarImageName: $0.avatarImageName ?? "message_avatar"
            )
        }
        tableView.reloadData()
        updateEmptyState()
    }

    private func openChat(peerName: String, avatarImageName: String) {
        guard FriendStore.shared.isFriend(name: peerName) else {
            showNonFriendChatPrompt()
            reloadMessageItems()
            return
        }

        let navigationController = navigationController ?? parent?.navigationController
        navigationController?.pushViewController(
            FriendChatViewController(peerName: peerName, avatarImageName: avatarImageName),
            animated: true
        )
    }

    private func showNonFriendChatPrompt() {
        NonFriendChatPromptView.present(in: navigationController?.view ?? parent?.view ?? view)
    }

    private func reloadFriendItems() {
        friendItems = FriendStore.shared.friends.map {
            FriendItem(name: $0.name, avatarImageName: $0.avatarImageName)
        }
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        switch selectedHeader {
        case .message:
            emptyStateLabel.text = "No messages yet"
            emptyStateContainerView.isHidden = !messageItems.isEmpty
        case .friend:
            emptyStateLabel.text = "No friends yet"
            emptyStateContainerView.isHidden = !friendItems.isEmpty
        }
    }

    @objc private func chatConversationsDidChange() {
        reloadMessageItems()
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
