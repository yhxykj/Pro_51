import UIKit

@MainActor
enum TavoniWaitHUD {
    private static var activePanel: UIView?
    private static var toastTicket: DispatchWorkItem?

    static func raise() {
        guard activePanel == nil, let container = targetWindow() else { return }

        let veilView = UIView(frame: container.bounds)
        veilView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        veilView.backgroundColor = UIColor(white: 0, alpha: 0.16)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        veilView.addSubview(spinner)
        spinner.startAnimating()

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: veilView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: veilView.centerYAnchor)
        ])

        container.addSubview(veilView)
        activePanel = veilView
    }

    static func lower() {
        toastTicket?.cancel()
        toastTicket = nil
        activePanel?.removeFromSuperview()
        activePanel = nil
    }

    static func toast(_ text: String) {
        lower()
        guard let container = targetWindow() else { return }

        let bubbleLabel = TavoniInsetLabel()
        bubbleLabel.text = text
        bubbleLabel.textColor = .white
        bubbleLabel.font = .boldSystemFont(ofSize: 15)
        bubbleLabel.textAlignment = .center
        bubbleLabel.numberOfLines = 0
        bubbleLabel.backgroundColor = UIColor(white: 0, alpha: 0.76)
        bubbleLabel.layer.cornerRadius = 18
        bubbleLabel.clipsToBounds = true
        bubbleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bubbleLabel)

        NSLayoutConstraint.activate([
            bubbleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bubbleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            bubbleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 36),
            bubbleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -36)
        ])

        activePanel = bubbleLabel
        let item = DispatchWorkItem {
            Task { @MainActor in
                lower()
            }
        }
        toastTicket = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: item)
    }

    private static func targetWindow() -> UIWindow? {
        if let coverWindow = TavoniFlowCenter.prime.coverWindow {
            return coverWindow
        }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}

private final class TavoniInsetLabel: UILabel {
    private let edgePadding = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgePadding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + edgePadding.left + edgePadding.right, height: size.height + edgePadding.top + edgePadding.bottom)
    }
}
