import UIKit
import WebKit

final class TavoniCanvasController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
    private let firstURLText: String
    private let captureFallbackView = UIView()
    private let shieldView = TavoniShieldView()
    private let gateImageView = UIImageView(image: UIImage(named: TavoniRouteConfig.activeConfig.signinAsset))
    private let canvasSpinner = UIActivityIndicatorView(style: .large)
    private var canvasStartTick = Int(Date().timeIntervalSince1970 * 1000)
    private var didResetSignin = false
    private var canvasWebView: WKWebView!

    init(firstURLText: String) {
        self.firstURLText = firstURLText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.firstURLText = ""
        super.init(coder: coder)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupShieldedRoot()
        prepareCanvasView()
        loadFirstCanvas()
    }

    deinit {
        let scriptBridge = canvasWebView?.configuration.userContentController
        scriptBridge?.removeScriptMessageHandler(forName: "handlePay")
        scriptBridge?.removeScriptMessageHandler(forName: "handleSkipStore")
        scriptBridge?.removeScriptMessageHandler(forName: "Close")
        scriptBridge?.removeScriptMessageHandler(forName: "rechargePay")
        scriptBridge?.removeScriptMessageHandler(forName: "openBrowser")
    }

    private func setupShieldedRoot() {
        view.backgroundColor = .black

        captureFallbackView.backgroundColor = .black
        view.addSubview(captureFallbackView)
        pinToBounds(captureFallbackView, to: view)

        let imageView = UIImageView(image: UIImage(named: TavoniRouteConfig.activeConfig.signinAsset))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        captureFallbackView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: captureFallbackView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: captureFallbackView.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: captureFallbackView.leadingAnchor, constant: 24),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: captureFallbackView.trailingAnchor, constant: -24),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: captureFallbackView.widthAnchor, multiplier: 0.75),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: captureFallbackView.heightAnchor, multiplier: 0.5)
        ])

        view.addSubview(shieldView)
        pinToBounds(shieldView, to: view)
    }

    private func pinToBounds(_ child: UIView, to parent: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }

    private func prepareCanvasView() {
        let guardedSurface = shieldView.shieldCanvas
        guardedSurface.backgroundColor = .black

        let scriptBridge = WKUserContentController()
        scriptBridge.add(self, name: "handleSkipStore")
        scriptBridge.add(self, name: "Close")
        scriptBridge.add(self, name: "rechargePay")
        scriptBridge.add(self, name: "openBrowser")

        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController = scriptBridge

        canvasWebView = WKWebView(frame: .zero, configuration: configuration)
        canvasWebView.tintColor = .systemBlue
        canvasWebView.navigationDelegate = self
        canvasWebView.uiDelegate = self
        canvasWebView.backgroundColor = .black
        canvasWebView.scrollView.backgroundColor = .black
        canvasWebView.scrollView.contentInsetAdjustmentBehavior = .never
        canvasWebView.scrollView.bounces = false
        canvasWebView.allowsBackForwardNavigationGestures = true
        guardedSurface.addSubview(canvasWebView)

        gateImageView.contentMode = .scaleAspectFill
        gateImageView.clipsToBounds = true
        guardedSurface.addSubview(gateImageView)

        canvasSpinner.color = .white
        canvasSpinner.hidesWhenStopped = true
        guardedSurface.addSubview(canvasSpinner)

        [canvasWebView, gateImageView, canvasSpinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            canvasWebView.topAnchor.constraint(equalTo: guardedSurface.topAnchor),
            canvasWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            gateImageView.topAnchor.constraint(equalTo: guardedSurface.topAnchor),
            gateImageView.leadingAnchor.constraint(equalTo: guardedSurface.leadingAnchor),
            gateImageView.trailingAnchor.constraint(equalTo: guardedSurface.trailingAnchor),
            gateImageView.bottomAnchor.constraint(equalTo: guardedSurface.bottomAnchor),

            canvasSpinner.centerXAnchor.constraint(equalTo: guardedSurface.centerXAnchor),
            canvasSpinner.centerYAnchor.constraint(equalTo: guardedSurface.centerYAnchor)
        ])
    }

    private func loadFirstCanvas() {
        guard let url = URL(string: firstURLText) else {
            TavoniWaitHUD.lower()
            return
        }

        showCanvasLoading()
        canvasWebView.load(URLRequest(url: url))
    }

    private func showCanvasLoading() {
        canvasStartTick = Int(Date().timeIntervalSince1970 * 1000)
        gateImageView.isHidden = false
        gateImageView.alpha = 1
        shieldView.shieldCanvas.bringSubviewToFront(gateImageView)
        shieldView.shieldCanvas.bringSubviewToFront(canvasSpinner)
        canvasSpinner.startAnimating()
    }

    private func hideCanvasLoading(removeLaunchImage: Bool) {
        canvasSpinner.stopAnimating()
        guard removeLaunchImage else { return }

        UIView.animate(withDuration: 0.24, animations: {
            self.gateImageView.alpha = 0
        }) { _ in
            self.gateImageView.removeFromSuperview()
        }
    }

    private func reportCanvasTiming(canvasMillis: Int) {
        TavoniPostClient.tunnel.post(
            path: TavoniRouteConfig.routeMap.canvasTiming,
            parameters: [
                "qavrno": canvasMillis
            ]
        ) { _ in }
    }

    private func beginStoreOrder(storeProductId: String, orderMarkText: String) {
        guard !storeProductId.isEmpty, !orderMarkText.isEmpty else {
            TavoniWaitHUD.toast("Failed")
            return
        }

        TavoniOrderBridge.store.beginOrder(storeProductID: storeProductId, orderMarkText: orderMarkText)
    }

    private func openOutside(_ url: URL, callbackURLText: String? = nil) {
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            let openState = success ? "success" : "failed"
            self?.dispatchOutsideState(openState: openState, urlText: callbackURLText ?? url.absoluteString)
        }
    }

    private func dispatchOutsideState(openState: String, urlText: String) {
        let detail: [String: Any] = [
            "state": openState,
            "url": urlText
        ]
        guard let detailPayloadText = TavoniJSONCodec.text(from: detail) else { return }

        let js = "window.dispatchEvent(new CustomEvent('nativeOpenState', { detail: \(detailPayloadText) }));"
        canvasWebView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func payloadDictionary(from body: Any) -> [String: Any]? {
        if let dictionary = body as? [String: Any] {
            return dictionary
        }
        if let text = body as? String {
            return TavoniJSONCodec.payloadDictionary(from: text)
        }
        return nil
    }

    private func isStoreURL(_ url: URL) -> Bool {
        let fullURLText = url.absoluteString.lowercased()
        return fullURLText.hasPrefix("https://apps.apple.com/") || fullURLText.hasPrefix("itms-apps://")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        TavoniWaitHUD.lower()
        hideCanvasLoading(removeLaunchImage: true)
        title = webView.title

        let canvasMillis = Int(Date().timeIntervalSince1970 * 1000) - canvasStartTick
        reportCanvasTiming(canvasMillis: canvasMillis)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        TavoniWaitHUD.lower()
        hideCanvasLoading(removeLaunchImage: false)
        if TavoniRouteConfig.activeConfig.traceSwitch {
            print("Tavoni canvasView load failed: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        TavoniWaitHUD.lower()
        hideCanvasLoading(removeLaunchImage: false)
        if TavoniRouteConfig.activeConfig.traceSwitch {
            print("Tavoni canvasView provisional load failed: \(error.localizedDescription)")
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "Close":
            guard didResetSignin == false else { return }
            didResetSignin = true
            TavoniFlowCenter.prime.resetToSignin()
        case "rechargePay":
            guard let payload = payloadDictionary(from: message.body) else { return }
            let storeProductId = payload["batchNo"] as? String ?? ""
            let orderMarkText = payload["orderCode"] as? String ?? ""
            beginStoreOrder(storeProductId: storeProductId, orderMarkText: orderMarkText)
        case "openBrowser":
            guard let payload = payloadDictionary(from: message.body),
                  let urlText = payload["url"] as? String else {
                return
            }

            guard let url = URL(string: urlText) else {
                dispatchOutsideState(openState: "failed", urlText: urlText)
                return
            }
            openOutside(url, callbackURLText: urlText)
        default:
            break
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if isStoreURL(url) {
            openOutside(url)
            decisionHandler(.cancel)
            return
        }

        let allowedSchemes = ["http", "https", "file", "chrome", "data", "javascript", "about"]
        let scheme = url.scheme?.lowercased() ?? ""
        guard allowedSchemes.contains(scheme) else {
            openOutside(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }

        if isStoreURL(url) {
            openOutside(url)
        } else {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}
