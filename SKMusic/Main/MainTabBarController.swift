//
//  MainTabBarController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/17.
//

import UIKit

final class MainTabBarController: UIViewController {
    private struct TabItem {
        let viewController: UIViewController
        let iconName: String
        let selectedIconName: String
        let accessibilityLabel: String
    }

    private let contentContainerView = UIView()
    private let tabBarImageView = UIImageView(image: UIImage(named: "tab_bar_background"))
    private let tabStackView = UIStackView()
    private var tabButtons: [UIButton] = []
    private var tabs: [TabItem] = []
    private var selectedIndex = 0

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupViews()
        setupConstraints()
        selectTab(at: 0)
    }

    private func setupTabs() {
        tabs = [
            TabItem(viewController: HomeViewController(), iconName: "tab_home", selectedIconName: "tab_home_highlight", accessibilityLabel: "Home"),
            TabItem(viewController: MainContentViewController(), iconName: "tab_share", selectedIconName: "tab_share_highlight", accessibilityLabel: "Share"),
            TabItem(viewController: MessageListViewController(), iconName: "tab_chat", selectedIconName: "tab_chat_highlight", accessibilityLabel: "Chat"),
            TabItem(viewController: MainContentViewController(), iconName: "tab_profile", selectedIconName: "tab_profile_highlight", accessibilityLabel: "Profile")
        ]
    }

    private func setupViews() {
        view.backgroundColor = .white

        contentContainerView.backgroundColor = .clear
        view.addSubview(contentContainerView)

        tabBarImageView.contentMode = .scaleToFill
        tabBarImageView.isUserInteractionEnabled = true
        view.addSubview(tabBarImageView)

        tabStackView.axis = .horizontal
        tabStackView.alignment = .center
        tabStackView.distribution = .equalSpacing
        tabBarImageView.addSubview(tabStackView)

        tabButtons = tabs.enumerated().map { index, tab in
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: tab.iconName), for: .normal)
            button.setImage(UIImage(named: tab.selectedIconName), for: .selected)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityLabel = tab.accessibilityLabel
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(button)
            return button
        }
    }

    private func setupConstraints() {
        [
            contentContainerView,
            tabBarImageView,
            tabStackView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        tabButtons.forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 48),
                button.heightAnchor.constraint(equalToConstant: 48)
            ])
        }

        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tabBarImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabBarImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tabBarImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
            tabBarImageView.heightAnchor.constraint(equalToConstant: 80),

            tabStackView.leadingAnchor.constraint(equalTo: tabBarImageView.leadingAnchor, constant: 36),
            tabStackView.trailingAnchor.constraint(equalTo: tabBarImageView.trailingAnchor, constant: -36),
            tabStackView.centerYAnchor.constraint(equalTo: tabBarImageView.centerYAnchor)
        ])
    }

    private func selectTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }

        let previousViewController = children.first
        previousViewController?.willMove(toParent: nil)
        previousViewController?.view.removeFromSuperview()
        previousViewController?.removeFromParent()

        let selectedViewController = tabs[index].viewController
        addChild(selectedViewController)
        contentContainerView.addSubview(selectedViewController.view)
        selectedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectedViewController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            selectedViewController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            selectedViewController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            selectedViewController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
        selectedViewController.didMove(toParent: self)

        selectedIndex = index
        updateTabSelection()
    }

    private func updateTabSelection() {
        tabButtons.enumerated().forEach { index, button in
            button.isSelected = index == selectedIndex
        }
    }

    @objc private func tabButtonTapped(_ sender: UIButton) {
        selectTab(at: sender.tag)
    }
}

private final class MainContentViewController: UIViewController {
    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))

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
        backgroundImageView.isUserInteractionEnabled = false
        view.addSubview(backgroundImageView)
    }

    private func setupConstraints() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
