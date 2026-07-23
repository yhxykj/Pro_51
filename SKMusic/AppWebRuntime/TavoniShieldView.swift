import UIKit

final class TavoniShieldView: UIView {
    let shieldCanvas = UIView()

    private let silentField = TavoniSilentField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareShield()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareShield()
    }

    private func prepareShield() {
        backgroundColor = .clear

        silentField.isSecureTextEntry = true
        silentField.backgroundColor = .clear
        silentField.textColor = .clear
        silentField.tintColor = .clear
        silentField.borderStyle = .none
        silentField.clipsToBounds = true

        addSubview(silentField)
        lockEdges(silentField, to: self)

        guard let secureCanvas = findShieldCanvas(in: silentField) else {
            assertionFailure("Secure canvas not found. Falling back to normal content view.")
            addSubview(shieldCanvas)
            lockEdges(shieldCanvas, to: self)
            return
        }

        secureCanvas.backgroundColor = .clear
        secureCanvas.isUserInteractionEnabled = true
        secureCanvas.clipsToBounds = true
        secureCanvas.tintColor = .systemBlue
        secureCanvas.addSubview(shieldCanvas)
        lockEdges(shieldCanvas, to: secureCanvas)
    }

    private func findShieldCanvas(in view: UIView) -> UIView? {
        for subview in view.subviews {
            let className = NSStringFromClass(type(of: subview))
            if className.contains("CanvasView")
                || className.contains("LayoutCanvasView")
                || className.contains("TextLayoutCanvasView") {
                return subview
            }

            if let found = findShieldCanvas(in: subview) {
                return found
            }
        }

        return nil
    }

    private func lockEdges(_ child: UIView, to parent: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
}

private final class TavoniSilentField: UITextField {
    override var canBecomeFirstResponder: Bool {
        false
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        []
    }
}
