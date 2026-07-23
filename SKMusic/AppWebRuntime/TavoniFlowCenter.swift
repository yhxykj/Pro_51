import Network
import UIKit
import UserNotifications

@MainActor
final class TavoniFlowCenter {
    static let prime = TavoniFlowCenter()

    private let routeConfig = TavoniRouteConfig.activeConfig
    private var hasIgnited = false
    private var askedNotification = false
    private var passedNetworkGate = false
    private var reachabilityWatch: NWPathMonitor?
    private let reachabilityQueue = DispatchQueue(label: "tavoni.flow.monitor")
    private var entryPortal = ""
    private(set) var coverWindow: UIWindow?

    var isSigninBusy = false

    private init() {}

    func ignite(in windowScene: UIWindowScene) {
        guard hasIgnited == false else { return }
        hasIgnited = true

        TavoniAdjustBridge.prepareBridge()
        raiseSplashWindow(in: windowScene)
        TavoniOrderBridge.store.observeTransactions()
        beginGateFlow()
    }

    func absorbPushToken(_ deviceToken: Data) {
        TavoniLocalVault.savePushMark(deviceToken)
    }

    func notePushTokenFailure(_ error: Error) {
        if routeConfig.traceSwitch {
            print("Tavoni push registration failed: \(error.localizedDescription)")
        }
    }

    func beginTapSignin() {
        guard isSigninBusy == false else { return }
        isSigninBusy = true
        TavoniWaitHUD.raise()

        TavoniAdjustBridge.fetchAdid { [weak self] adid in
            Task { @MainActor in
                self?.submitTapSignin(adid: adid)
            }
        }
    }

    func resetToSignin() {
        TavoniLocalVault.removeSessionToken()
        isSigninBusy = false
        TavoniWaitHUD.lower()
        showSigninPanel()
    }

    private func raiseSplashWindow(in windowScene: UIWindowScene) {
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .normal + 1
        window.rootViewController = TavoniLaunchPanelController(assetName: routeConfig.splashAsset)
        window.makeKeyAndVisible()
        coverWindow = window
    }

    private func beginGateFlow() {
        TavoniWaitHUD.raise()
        awaitReachabilityGate()
    }

    private func awaitReachabilityGate() {
        guard passedNetworkGate == false else { return }
        reachabilityWatch?.cancel()

        let monitor = NWPathMonitor()
        reachabilityWatch = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }

            Task { @MainActor in
                guard let self, self.passedNetworkGate == false else { return }
                self.passedNetworkGate = true
                self.reachabilityWatch?.cancel()
                self.reachabilityWatch = nil

                TavoniWaitHUD.raise()
                self.requestAuroraProbe { shouldKeepOverlay in
                    if shouldKeepOverlay == false {
                        self.dropCoverWindow()
                    }
                }
            }
        }
        monitor.start(queue: reachabilityQueue)
    }

    private func requestAuroraProbe(completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = [
            "qavrnt": TimeZone.current.identifier,
            "qavrnk": TavoniDeviceProbe.keyboardMarks,
            "qavrng": routeConfig.traceSwitch ? 1 : 0,
            "qavrnd": TavoniDeviceProbe.hasCarrierSignal() ? 1 : 0,
            "qavrnn": TavoniDeviceProbe.isTunnelActive() ? 1 : 0
        ]

        TavoniPostClient.tunnel.post(
            path: TavoniRouteConfig.routeMap.auroraProbe,
            parameters: parameters
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let payload):
                self.askNotificationAfterProbe()
                self.handleAuroraPayload(payload, completion: completion)
            case .failure(let error):
                if self.routeConfig.traceSwitch {
                    print("Tavoni aurora failed: \(error.localizedDescription)")
                }
                completion(false)
            }
        }
    }

    private func handleAuroraPayload(_ payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let signinFlag = payload["loginFlag"] as? Int else {
            completion(false)
            return
        }

        if let entryValue = payload["openValue"] as? String {
            entryPortal = entryValue
        }

        switch signinFlag {
        case 0:
            let regionGate = payload["locationFlag"] as? Int
            if regionGate == 0 {
                showSigninPanel()
                completion(true)
            } else {
                TavoniWaitHUD.lower()
                completion(false)
            }
        case 1:
            if TavoniLocalVault.sessionToken?.isEmpty == false, !entryPortal.isEmpty {
                showBoundCanvas()
                completion(true)
            } else {
                showSigninPanel()
                completion(true)
            }
        default:
            completion(false)
        }
    }

    private func askNotificationAfterProbe() {
        guard askedNotification == false else { return }
        askedNotification = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    private func submitTapSignin(adid: String) {
        let parameters: [String: Any] = [
            "qavrna": adid,
            "qavrnd": TavoniLocalVault.sessionToken ?? "",
            "qavrnn": TavoniLocalVault.deviceStamp
        ]

        TavoniPostClient.tunnel.post(
            path: TavoniRouteConfig.routeMap.tapSigninRoute,
            parameters: parameters
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let payload):
                if let serverSessionText = payload["token"] as? String {
                    TavoniLocalVault.sessionToken = serverSessionText
                }
                if let secretText = payload["password"] as? String {
                    TavoniLocalVault.secretText = secretText
                }

                if self.entryPortal.isEmpty {
                    self.requestAuroraProbe { _ in
                        self.isSigninBusy = false
                    }
                } else {
                    self.showBoundCanvas()
                    self.isSigninBusy = false
                }
            case .failure(let error):
                if self.routeConfig.traceSwitch {
                    print("Tavoni signin failed: \(error.localizedDescription)")
                }
                self.isSigninBusy = false
                TavoniWaitHUD.lower()
                TavoniWaitHUD.toast("Login failed")
            }
        }
    }

    private func showSigninPanel() {
        isSigninBusy = false
        TavoniWaitHUD.lower()

        let controller = TavoniSigninPanelController(assetName: routeConfig.signinAsset)
        controller.hidesBottomBarWhenPushed = true
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.setNavigationBarHidden(true, animated: false)
        coverWindow?.rootViewController = navigationController
    }

    private func showBoundCanvas() {
        guard let sessionText = TavoniLocalVault.sessionToken, !sessionText.isEmpty else {
            showSigninPanel()
            return
        }
        guard !entryPortal.isEmpty else {
            TavoniWaitHUD.lower()
            isSigninBusy = false
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let payload: [String: Any] = [
            "token": sessionText,
            "timestamp": timestamp
        ]

        guard let payloadText = TavoniJSONCodec.text(from: payload),
              let encryptedText = try? TavoniCipherBox.encryptHexText(payloadText, routeConfig: routeConfig) else {
            TavoniWaitHUD.lower()
            isSigninBusy = false
            return
        }

        let urlText = "\(entryPortal)/?openParams=\(encryptedText)&appId=\(routeConfig.clientMark)"
        let controller = TavoniCanvasController(firstURLText: urlText)
        controller.hidesBottomBarWhenPushed = true
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.setNavigationBarHidden(true, animated: false)

        TavoniWaitHUD.raise()
        coverWindow?.rootViewController = navigationController
    }

    private func dropCoverWindow() {
        TavoniWaitHUD.lower()
        coverWindow?.isHidden = true
        coverWindow = nil
    }
}

final class TavoniLaunchPanelController: UIViewController {
    private let assetName: String

    init(assetName: String) {
        self.assetName = assetName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.assetName = TavoniRouteConfig.activeConfig.splashAsset
        super.init(coder: coder)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let imageView = UIImageView(image: UIImage(named: assetName))
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

final class TavoniSigninPanelController: UIViewController {
    private let assetName: String
    private let posterImageView = UIImageView()
    private let signinButton = UIButton(type: .system)

    init(assetName: String) {
        self.assetName = assetName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.assetName = TavoniRouteConfig.activeConfig.signinAsset
        super.init(coder: coder)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        composeSigninPanel()
        applySigninLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TavoniFlowCenter.prime.isSigninBusy = false
        TavoniWaitHUD.lower()
    }

    private func composeSigninPanel() {
        view.backgroundColor = .black

        posterImageView.image = UIImage(named: assetName)
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        view.addSubview(posterImageView)

        signinButton.setTitle("Log In", for: .normal)
        signinButton.setTitleColor(.white, for: .normal)
        signinButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        signinButton.backgroundColor = UIColor(red: 0.94, green: 0.49, blue: 0.80, alpha: 1)
        signinButton.layer.cornerRadius = 29
        signinButton.clipsToBounds = true
        signinButton.addTarget(self, action: #selector(signinTapped), for: .touchUpInside)
        view.addSubview(signinButton)
    }

    private func applySigninLayout() {
        [posterImageView, signinButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: view.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            signinButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            signinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            signinButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -56),
            signinButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    @objc private func signinTapped() {
        TavoniFlowCenter.prime.beginTapSignin()
    }
}
