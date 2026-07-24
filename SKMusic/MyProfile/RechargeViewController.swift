//
//  RechargeViewController.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import StoreKit
import UIKit

final class RechargeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SKPaymentTransactionObserver {
    private struct RechargePackage {
        let coins: Int
        let productID: String
        let fallbackPrice: String

        static let all: [RechargePackage] = [
            RechargePackage(coins: 3000, productID: "ygcomdlvptwhflro", fallbackPrice: "$99.99"),
            RechargePackage(coins: 1500, productID: "zasbihejsnogkxly", fallbackPrice: "$49.99"),
            RechargePackage(coins: 900, productID: "qijdfnjrbvfjbrgg", fallbackPrice: "$29.99"),
            RechargePackage(coins: 600, productID: "nmwjanngssycidpq", fallbackPrice: "$19.99"),
            RechargePackage(coins: 300, productID: "aucznsvpvdgvusuz", fallbackPrice: "$9.99"),
            RechargePackage(coins: 210, productID: "unfjdfnuerhthjqe", fallbackPrice: "$6.99"),
            RechargePackage(coins: 150, productID: "unofuejljtoidkfx", fallbackPrice: "$4.99"),
            RechargePackage(coins: 60, productID: "fossbaipkptmxxyg", fallbackPrice: "$1.99"),
            RechargePackage(coins: 30, productID: "naakzoeidwluinqr", fallbackPrice: "$0.99")
        ]
    }

    private enum Layout {
        static let horizontalInset: CGFloat = 23
        static let headerTopOffset: CGFloat = 92
        static let headerHeight: CGFloat = 176
        static let packageSpacing: CGFloat = 17
        static let packageLineSpacing: CGFloat = 19
        static let packageAspectRatio: CGFloat = 250 / 184
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "welcome_background"))
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backButton = UIButton(type: .custom)
    private let headerView = UIView()
    private let singerImageView = UIImageView(image: UIImage(named: "recharge_hero_singer"))
    private let titleImageView = UIImageView(image: UIImage(named: "recharge_get_coins_title"))
    private let balanceLabel = UILabel()
    private let headerCoinImageView = UIImageView(image: UIImage(named: "recharge_coin_icon"))
    private let featuredAudioImageView = UIImageView(image: UIImage(named: "recharge_featured_audio_label"))
    private lazy var packagesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Layout.packageSpacing
        layout.minimumLineSpacing = Layout.packageLineSpacing
        layout.estimatedItemSize = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            RechargePackageCollectionViewCell.self,
            forCellWithReuseIdentifier: RechargePackageCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()
    private var productsByID = [String: Product]()
    private var transactionUpdatesTask: Task<Void, Never>?
    private var isPurchasing = false
    private var purchasingIndexPath: IndexPath?

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        updateBalance()
        listenForTransactionUpdates()
        SKPaymentQueue.default().add(self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(coinBalanceDidChange),
            name: .coinBalanceDidChange,
            object: nil
        )

        Task { [weak self] in
            await self?.loadProducts()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
        SKPaymentQueue.default().remove(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        view.backgroundColor = .white

        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        configureImageButton(backButton, imageName: "back_button", accessibilityLabel: "Back")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        headerView.backgroundColor = .white
        headerView.layer.cornerRadius = 16
        headerView.layer.borderWidth = 1.6
        headerView.layer.borderColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1).cgColor
        contentView.addSubview(headerView)

        singerImageView.contentMode = .scaleAspectFit
        singerImageView.clipsToBounds = false
        headerView.addSubview(singerImageView)

        titleImageView.contentMode = .scaleAspectFit
        headerView.addSubview(titleImageView)

        balanceLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        balanceLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 24) ?? .italicSystemFont(ofSize: 24)
        balanceLabel.numberOfLines = 1
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.5
        headerView.addSubview(balanceLabel)

        headerCoinImageView.contentMode = .scaleAspectFit
        headerView.addSubview(headerCoinImageView)

        featuredAudioImageView.contentMode = .scaleAspectFit
        headerView.addSubview(featuredAudioImageView)

        contentView.addSubview(packagesCollectionView)
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            scrollView,
            contentView,
            backButton,
            headerView,
            singerImageView,
            titleImageView,
            balanceLabel,
            headerCoinImageView,
            featuredAudioImageView,
            packagesCollectionView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 21),
            backButton.widthAnchor.constraint(equalToConstant: 69),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.headerTopOffset),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            headerView.heightAnchor.constraint(equalToConstant: 168),

            singerImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: -9),
            singerImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            singerImageView.widthAnchor.constraint(equalToConstant: 137),
            singerImageView.heightAnchor.constraint(equalToConstant: 201),

            titleImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0),
            titleImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 169),
            titleImageView.heightAnchor.constraint(equalToConstant: 40),

            balanceLabel.topAnchor.constraint(equalTo: titleImageView.bottomAnchor, constant: 7),
            balanceLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 143),
            balanceLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -14),
            balanceLabel.heightAnchor.constraint(equalToConstant: 30),

            headerCoinImageView.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 13),
            headerCoinImageView.centerXAnchor.constraint(equalTo: balanceLabel.centerXAnchor),
            headerCoinImageView.widthAnchor.constraint(equalToConstant: 37),
            headerCoinImageView.heightAnchor.constraint(equalTo: headerCoinImageView.widthAnchor),

            featuredAudioImageView.topAnchor.constraint(equalTo: headerCoinImageView.bottomAnchor, constant: 8),
            featuredAudioImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 147),
            featuredAudioImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -17),
            featuredAudioImageView.heightAnchor.constraint(equalToConstant: 28),

            packagesCollectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 28),
            packagesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalInset),
            packagesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalInset),
            packagesCollectionView.heightAnchor.constraint(
                equalTo: packagesCollectionView.widthAnchor,
                multiplier: Layout.packageAspectRatio
            ),
            packagesCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -34)
        ])
    }

    private func loadProducts() async {
        do {
            let products = try await Product.products(for: RechargePackage.all.map(\.productID))
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            reloadPackages()
        } catch {
            showAlert(title: "Unable to load products", message: error.localizedDescription)
            reloadPackages()
        }
    }

    private func reloadPackages() {
        packagesCollectionView.reloadData()
    }

    private func priceText(for package: RechargePackage) -> String {
        productsByID[package.productID]?.displayPrice ?? package.fallbackPrice
    }

    private func updateBalance() {
        balanceLabel.text = "Balance:\(CoinBalanceStore.balance)"
    }

    private func listenForTransactionUpdates() {
        transactionUpdatesTask = Task { [weak self] in
            for await verificationResult in Transaction.updates {
                await self?.handle(verificationResult)
            }
        }
    }

    private func handle(_ verificationResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try verifiedTransaction(from: verificationResult)
            await deliver(transaction)
            await transaction.finish()
        } catch {
            showAlert(title: "Purchase verification failed", message: error.localizedDescription)
        }
    }

    private func deliver(_ transaction: Transaction) async {
        guard let package = RechargePackage.all.first(where: { $0.productID == transaction.productID }) else {
            return
        }

        if CoinBalanceStore.credit(coins: package.coins, transactionID: transaction.id) {
            updateBalance()
        }
    }

    private func verifiedTransaction(from result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            throw error
        }
    }

    private func configureImageButton(_ button: UIButton, imageName: String, accessibilityLabel: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = accessibilityLabel
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func coinBalanceDidChange() {
        updateBalance()
    }

    private func finishPurchasing() {
        isPurchasing = false
        purchasingIndexPath = nil
        packagesCollectionView.isUserInteractionEnabled = true
        reloadPackages()
    }

    private func product(for package: RechargePackage) async throws -> Product? {
        if let product = productsByID[package.productID] {
            return product
        }

        let products = try await Product.products(for: [package.productID])
        guard let product = products.first(where: { $0.id == package.productID }) else {
            return nil
        }

        productsByID[product.id] = product
        reloadPackages()
        return product
    }

    private func purchase(_ package: RechargePackage, at indexPath: IndexPath) {
        guard !isPurchasing else { return }

        isPurchasing = true
        purchasingIndexPath = indexPath
        packagesCollectionView.isUserInteractionEnabled = false
        if let cell = packagesCollectionView.cellForItem(at: indexPath) as? RechargePackageCollectionViewCell {
            cell.setLoading(true)
        }

        Task { [weak self] in
            guard let self else { return }
            var shouldFinishPurchasing = true
            defer {
                if shouldFinishPurchasing {
                    self.finishPurchasing()
                }
            }

            do {
                guard let product = try await self.product(for: package) else {
                    shouldFinishPurchasing = false
                    self.startLegacyPayment(for: package)
                    return
                }

                let result = try await product.purchase()
                switch result {
                case .success(let verificationResult):
                    let transaction = try self.verifiedTransaction(from: verificationResult)
                    await self.deliver(transaction)
                    await transaction.finish()
                    self.showAlert(title: "Purchase complete", message: "Coins have been added to your balance.")
                case .userCancelled:
                    break
                case .pending:
                    self.showAlert(title: "Purchase pending", message: "Your payment is pending approval.")
                @unknown default:
                    self.showAlert(title: "Purchase unavailable", message: "Please try again later.")
                }
            } catch {
                self.showAlert(title: "Purchase failed", message: error.localizedDescription)
            }
        }
    }

    private func startLegacyPayment(for package: RechargePackage) {
        guard SKPaymentQueue.canMakePayments() else {
            finishPurchasing()
            showAlert(title: "Purchase unavailable", message: "In-App Purchases are disabled on this device.")
            return
        }

        let payment = SKMutablePayment()
        payment.productIdentifier = package.productID
        payment.quantity = 1
        SKPaymentQueue.default().add(payment)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            switch transaction.transactionState {
            case .purchased:
                deliverLegacy(transaction)
                queue.finishTransaction(transaction)
                finishPurchasing()
                showAlert(title: "Purchase complete", message: "Coins have been added to your balance.")
            case .failed:
                queue.finishTransaction(transaction)
                finishPurchasing()
                if let error = transaction.error as? SKError, error.code == .paymentCancelled {
                    return
                }
                showAlert(
                    title: "Purchase failed",
                    message: transaction.error?.localizedDescription ?? "The payment could not be completed."
                )
            case .deferred:
                showAlert(title: "Purchase pending", message: "Your payment is pending approval.")
            case .restored:
                queue.finishTransaction(transaction)
                finishPurchasing()
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }

    private func deliverLegacy(_ transaction: SKPaymentTransaction) {
        guard
            let package = RechargePackage.all.first(where: { $0.productID == transaction.payment.productIdentifier }),
            let transactionIdentifier = transaction.transactionIdentifier
        else {
            return
        }

        CoinBalanceStore.credit(coins: package.coins, transactionIdentifier: transactionIdentifier)
        updateBalance()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        RechargePackage.all.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RechargePackageCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? RechargePackageCollectionViewCell
        else {
            return UICollectionViewCell()
        }

        let package = RechargePackage.all[indexPath.item]
        cell.configure(
            coins: package.coins,
            priceText: priceText(for: package),
            isLoading: indexPath == purchasingIndexPath
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard RechargePackage.all.indices.contains(indexPath.item) else { return }

        let package = RechargePackage.all[indexPath.item]
        purchase(package, at: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let itemWidth = (collectionView.bounds.width - (Layout.packageSpacing * 2)) / 3
        return CGSize(width: itemWidth, height: itemWidth * Layout.packageAspectRatio)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        Layout.packageSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        Layout.packageLineSpacing
    }

    private func showAlert(title: String, message: String) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private final class RechargePackageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "RechargePackageCollectionViewCell"

    private enum Layout {
        static let priceHeight: CGFloat = 34
        static let coinIconTopOffset: CGFloat = 10
        static let coinIconSize: CGFloat = 30
        static let coinCountTopSpacing: CGFloat = 5
        static let coinCountHeight: CGFloat = 22
    }

    private let cardView = UIView()
    private let coinImageView = UIImageView(image: UIImage(named: "recharge_coin_icon"))
    private let coinCountLabel = UILabel()
    private let priceBackgroundView = UIView()
    private let priceLabel = UILabel()
    private let loadingOverlayView = UIView()
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    func configure(coins: Int, priceText: String, isLoading: Bool) {
        coinCountLabel.text = "\(coins)"
        priceLabel.text = priceText
        setLoading(isLoading)
    }

    func setLoading(_ isLoading: Bool) {
        loadingOverlayView.isHidden = !isLoading
        if isLoading {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    private func setupViews() {
        cardView.backgroundColor = .white
        cardView.layer.borderWidth = 1.5
        cardView.layer.borderColor = UIColor(red: 0.93, green: 0.41, blue: 0.76, alpha: 1).cgColor
        cardView.layer.cornerRadius = 7
        cardView.clipsToBounds = true
        cardView.isUserInteractionEnabled = false
        contentView.addSubview(cardView)

        coinImageView.contentMode = .scaleAspectFit
        cardView.addSubview(coinImageView)

        coinCountLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        coinCountLabel.textAlignment = .center
        coinCountLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 19) ?? .italicSystemFont(ofSize: 19)
        coinCountLabel.adjustsFontSizeToFitWidth = true
        coinCountLabel.minimumScaleFactor = 0.7
        cardView.addSubview(coinCountLabel)

        priceBackgroundView.backgroundColor = UIColor(red: 0.94, green: 0.49, blue: 0.80, alpha: 1)
        cardView.addSubview(priceBackgroundView)

        priceLabel.textColor = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)
        priceLabel.textAlignment = .center
        priceLabel.font = UIFont(name: "AvenirNext-HeavyItalic", size: 17) ?? .italicSystemFont(ofSize: 17)
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.58
        priceBackgroundView.addSubview(priceLabel)

        loadingOverlayView.backgroundColor = UIColor(white: 1, alpha: 0.72)
        loadingOverlayView.isHidden = true
        loadingOverlayView.isUserInteractionEnabled = false
        cardView.addSubview(loadingOverlayView)

        activityIndicatorView.color = UIColor(red: 0.94, green: 0.49, blue: 0.80, alpha: 1)
        activityIndicatorView.hidesWhenStopped = true
        loadingOverlayView.addSubview(activityIndicatorView)
    }

    private func setupConstraints() {
        [
            cardView,
            coinImageView,
            coinCountLabel,
            priceBackgroundView,
            priceLabel,
            loadingOverlayView,
            activityIndicatorView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            priceBackgroundView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            priceBackgroundView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            priceBackgroundView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            priceBackgroundView.heightAnchor.constraint(equalToConstant: Layout.priceHeight),

            coinImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Layout.coinIconTopOffset),
            coinImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            coinImageView.widthAnchor.constraint(equalToConstant: Layout.coinIconSize),
            coinImageView.heightAnchor.constraint(equalTo: coinImageView.widthAnchor),

            coinCountLabel.topAnchor.constraint(equalTo: coinImageView.bottomAnchor, constant: Layout.coinCountTopSpacing),
            coinCountLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            coinCountLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            coinCountLabel.heightAnchor.constraint(equalToConstant: Layout.coinCountHeight),
            coinCountLabel.bottomAnchor.constraint(lessThanOrEqualTo: priceBackgroundView.topAnchor, constant: -2),

            priceLabel.centerXAnchor.constraint(equalTo: priceBackgroundView.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: priceBackgroundView.centerYAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: priceBackgroundView.leadingAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceBackgroundView.trailingAnchor, constant: -8),
            priceLabel.heightAnchor.constraint(equalTo: priceBackgroundView.heightAnchor),

            loadingOverlayView.topAnchor.constraint(equalTo: cardView.topAnchor),
            loadingOverlayView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            loadingOverlayView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            loadingOverlayView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: loadingOverlayView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: loadingOverlayView.centerYAnchor)
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            cardView.alpha = isHighlighted ? 0.72 : 1
        }
    }
}
