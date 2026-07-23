import Foundation
import StoreKit

final class TavoniOrderBridge: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let store = TavoniOrderBridge()

    private var storeProductProbe: SKProductsRequest?
    private var isWatchingStoreQueue = false
    private var runningOrderCode = ""
    private var runningProductID = ""
    private var runningPrice: NSDecimalNumber?
    private var runningCurrency: String?

    private override init() {
        super.init()
    }

    func observeTransactions() {
        guard isWatchingStoreQueue == false else { return }
        isWatchingStoreQueue = true
        SKPaymentQueue.default().add(self)
    }

    func beginOrder(storeProductID: String, orderMarkText: String) {
        guard SKPaymentQueue.canMakePayments() else {
            TavoniWaitHUD.toast("Purchase unavailable")
            return
        }

        TavoniWaitHUD.raise()
        runningOrderCode = orderMarkText
        runningProductID = storeProductID
        runningPrice = nil
        runningCurrency = nil

        let request = SKProductsRequest(productIdentifiers: [storeProductID])
        storeProductProbe = request
        request.delegate = self
        request.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            resetStoreState()
            TavoniWaitHUD.toast("Failed")
            return
        }

        runningPrice = product.price
        runningCurrency = currencyMark(for: product)
        TavoniSocialBridge.trackCheckoutStart(price: runningPrice, currency: runningCurrency)

        let payment = SKMutablePayment(product: product)
        payment.applicationUsername = runningOrderCode
        SKPaymentQueue.default().add(payment)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        resetStoreState()
        TavoniWaitHUD.toast("Failed")
        if TavoniRouteConfig.activeConfig.traceSwitch {
            print("Tavoni product request failed: \(error.localizedDescription)")
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                guard let orderMarkText = orderMark(for: transaction) else { continue }
                checkReceipt(transaction: transaction, orderMarkText: orderMarkText)
            case .failed:
                guard orderMark(for: transaction) != nil else { continue }
                TavoniWaitHUD.lower()
                queue.finishTransaction(transaction)
                resetStoreState()
            case .restored:
                guard orderMark(for: transaction) != nil else { continue }
                TavoniWaitHUD.lower()
                queue.finishTransaction(transaction)
                resetStoreState()
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }

    private func orderMark(for transaction: SKPaymentTransaction) -> String? {
        if let applicationUsername = transaction.payment.applicationUsername,
           !applicationUsername.isEmpty {
            return applicationUsername
        }

        if transaction.payment.productIdentifier == runningProductID, !runningOrderCode.isEmpty {
            return runningOrderCode
        }

        return nil
    }

    private func checkReceipt(transaction: SKPaymentTransaction, orderMarkText: String) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path),
              let receiptData = try? Data(contentsOf: receiptURL, options: .alwaysMapped) else {
            TavoniWaitHUD.lower()
            return
        }

        let receiptEnvelope = receiptData.base64EncodedString(options: [])
        guard !receiptEnvelope.isEmpty else {
            TavoniWaitHUD.lower()
            return
        }

        submitStoreReceipt(transaction: transaction, receiptEnvelope: receiptEnvelope, orderMarkText: orderMarkText)
    }

    private func submitStoreReceipt(transaction: SKPaymentTransaction, receiptEnvelope: String, orderMarkText: String) {
        let storeTransactionMark = transaction.transactionIdentifier ?? ""
        let orderEnvelope: [String: Any] = ["orderCode": orderMarkText]
        let orderEnvelopeText = TavoniJSONCodec.text(from: orderEnvelope) ?? ""
        let parameters: [String: Any] = [
            "qavrnt": storeTransactionMark,
            "qavrnp": receiptEnvelope,
            "qavrnc": orderEnvelopeText
        ]

        TavoniPostClient.tunnel.post(
            path: TavoniRouteConfig.routeMap.storeReceiptGate,
            parameters: parameters,
            allowsPlainResponse: true
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                TavoniWaitHUD.lower()
                TavoniSocialBridge.trackStorePurchase(price: self.runningPrice, currency: self.runningCurrency)
                TavoniAdjustBridge.trackStorePurchase(
                    price: self.runningPrice,
                    currency: self.runningCurrency,
                    transactionId: storeTransactionMark
                )
                TavoniAdjustBridge.reportCheckoutPulse(orderMarkText: orderMarkText, transactionId: storeTransactionMark)
                SKPaymentQueue.default().finishTransaction(transaction)
                self.resetStoreState()
            case .failure(let error):
                TavoniWaitHUD.lower()
                if TavoniRouteConfig.activeConfig.traceSwitch {
                    print("Tavoni receipt verify failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func resetStoreState() {
        runningOrderCode = ""
        runningProductID = ""
        runningPrice = nil
        runningCurrency = nil
        storeProductProbe = nil
    }

    private func currencyMark(for product: SKProduct) -> String {
        (product.priceLocale as NSLocale).object(forKey: .currencyCode) as? String ?? "USD"
    }
}
