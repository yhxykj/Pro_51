//
//  FriendChatViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class FriendChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private struct ChatMessage {
        let text: String
        let isIncoming: Bool
    }

    private enum Layout {
        static let inputColor = UIColor(red: 249.0 / 255.0, green: 148.0 / 255.0, blue: 213.0 / 255.0, alpha: 1.0)
        static let placeholderColor = UIColor(red: 0.44, green: 0.35, blue: 0.43, alpha: 0.75)
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let chatTableView = UITableView()
    private let inputContainerView = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .custom)
    private var chatMessages = [
        ChatMessage(text: "Hi~ I am Sarah,welcome to myworld", isIncoming: true),
        ChatMessage(text: "Hi~ I am Sarah,welcome to myworld", isIncoming: false)
    ]
    private var inputBottomConstraint: NSLayoutConstraint!

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

        backButton.setImage(UIImage(named: "back_button"), for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.contentHorizontalAlignment = .fill
        backButton.contentVerticalAlignment = .fill
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        titleLabel.text = "Angela"
        titleLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
        titleLabel.font = Self.titleFont
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        view.addSubview(titleLabel)

        chatTableView.backgroundColor = .clear
        chatTableView.separatorStyle = .none
        chatTableView.showsVerticalScrollIndicator = false
        chatTableView.contentInsetAdjustmentBehavior = .never
        chatTableView.keyboardDismissMode = .onDrag
        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.register(ChatMessageTableViewCell.self, forCellReuseIdentifier: ChatMessageTableViewCell.reuseIdentifier)
        view.addSubview(chatTableView)

        inputContainerView.backgroundColor = Layout.inputColor
        inputContainerView.layer.cornerRadius = 22.5
        inputContainerView.layer.masksToBounds = true
        view.addSubview(inputContainerView)

        messageTextField.backgroundColor = .clear
        messageTextField.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
        messageTextField.font = Self.inputFont
        messageTextField.delegate = self
        messageTextField.returnKeyType = .send
        messageTextField.autocorrectionType = .no
        messageTextField.attributedPlaceholder = NSAttributedString(
            string: "Please enter...",
            attributes: [
                .foregroundColor: Layout.placeholderColor,
                .font: Self.placeholderFont
            ]
        )
        inputContainerView.addSubview(messageTextField)

        sendButton.setImage(UIImage(named: "chat_send_icon"), for: .normal)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.accessibilityLabel = "Send"
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            backButton,
            titleLabel,
            chatTableView,
            inputContainerView,
            messageTextField,
            sendButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -13)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 44),

            chatTableView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17),
            chatTableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -12),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            inputContainerView.heightAnchor.constraint(equalToConstant: 45),
            inputBottomConstraint,

            messageTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 25),
            messageTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageTextField.heightAnchor.constraint(equalToConstant: 30),

            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -21),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 31),
            sendButton.heightAnchor.constraint(equalTo: sendButton.widthAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatMessages.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageTableViewCell.reuseIdentifier, for: indexPath) as? ChatMessageTableViewCell
        else {
            return UITableViewCell()
        }

        let message = chatMessages[indexPath.row]
        cell.configure(text: message.text, isIncoming: message.isIncoming)
        return cell
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }

    @objc private func sendTapped() {
        let trimmedText = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedText.isEmpty else {
            messageTextField.resignFirstResponder()
            return
        }

        chatMessages.append(ChatMessage(text: trimmedText, isIncoming: false))
        let indexPath = IndexPath(row: chatMessages.count - 1, section: 0)
        chatTableView.insertRows(at: [indexPath], with: .automatic)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        messageTextField.text = nil
        messageTextField.resignFirstResponder()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private static var titleFont: UIFont {
        UIFont(name: "AvenirNext-HeavyItalic", size: 28) ?? .italicSystemFont(ofSize: 28)
    }

    private static var inputFont: UIFont {
        UIFont(name: "AvenirNext-BoldItalic", size: 16) ?? .italicSystemFont(ofSize: 16)
    }

    private static var placeholderFont: UIFont {
        UIFont(name: "AvenirNext-BoldItalic", size: 15) ?? .italicSystemFont(ofSize: 15)
    }
}
