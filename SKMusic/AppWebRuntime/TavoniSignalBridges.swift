import Foundation
@_implementationOnly import AdjustSdk
@_implementationOnly import FacebookCore

enum TavoniAdjustBridge {
    private static let attributionTimeoutMs = 3000
    private static let defaultCurrency = "USD"

    static func prepareBridge() {
        let routeConfig = TavoniRouteConfig.activeConfig
        guard !routeConfig.adjustBundleToken.isEmpty,
              let adjustConfig = ADJConfig(appToken: routeConfig.adjustBundleToken, environment: ADJEnvironmentProduction) else {
            return
        }

        adjustConfig.logLevel = .suppress
        prepareCallbackMark()
        Adjust.initSdk(adjustConfig)
        trackInstallIfNeeded()
  
    }

    static func fetchAdid(completion: @escaping (String) -> Void) {
        Adjust.adid(withTimeout: attributionTimeoutMs) { adid in
            completion(adid ?? "")
        }
    }

    static func trackStorePurchase(price: NSDecimalNumber?, currency: String?, transactionId: String?) {
        let routeConfig = TavoniRouteConfig.activeConfig
        guard !routeConfig.adjustPaidSignal.isEmpty,
              let price,
              price.compare(NSDecimalNumber.zero) == .orderedDescending,
              let event = ADJEvent(eventToken: routeConfig.adjustPaidSignal) else {
            return
        }

        event.setRevenue(price.doubleValue, currency: currencyOrDefault(currency))
        if let transactionId, !transactionId.isEmpty {
            event.setTransactionId(transactionId)
        }
        Adjust.trackEvent(event)
    }

    static func reportCheckoutPulse(orderMarkText: String, transactionId: String?) {
        let group = DispatchGroup()
        var adidText = ""
        var attributionText = "{}"

        group.enter()
        fetchAdid { adid in
            adidText = adid
            group.leave()
        }

        group.enter()
        fetchAttributionText { attribution in
            attributionText = attribution
            group.leave()
        }

        group.notify(queue: .global(qos: .utility)) {
            let parameters: [String: Any] = [
                "qavrnt": attributionText,
                "qavrne": "Purchase",
                "qavrnd": TavoniLocalVault.deviceStamp,
                "qavrna": adidText
            ]

            TavoniPostClient.tunnel.post(
                path: TavoniRouteConfig.routeMap.checkoutPulse,
                parameters: parameters,
                allowsPlainResponse: true
            ) { _ in }
        }
    }

    private static func fetchAttributionText(completion: @escaping (String) -> Void) {
        Adjust.attribution(withTimeout: attributionTimeoutMs) { attribution in
            let rawPayload = attribution?.jsonResponse as? [String: Any]
            let fallbackPayload = attribution?.dictionary() as? [String: Any]
            completion(TavoniJSONCodec.text(from: rawPayload ?? fallbackPayload ?? [:]) ?? "{}")
        }
    }

    private static func prepareCallbackMark() {
        let distinctId = TavoniLocalVault.deviceStamp
        guard !distinctId.isEmpty else { return }
        Adjust.addGlobalCallbackParameter(distinctId, forKey: "ta_distinct_id")
    }

    private static func trackInstallIfNeeded() {
        let routeConfig = TavoniRouteConfig.activeConfig
        guard !routeConfig.adjustFirstSignal.isEmpty else { return }

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: TavoniRouteConfig.installPulseSlot) == false,
              let event = ADJEvent(eventToken: routeConfig.adjustFirstSignal) else {
            return
        }

        Adjust.trackEvent(event)
        defaults.set(true, forKey: TavoniRouteConfig.installPulseSlot)
    }

    private static func currencyOrDefault(_ currency: String?) -> String {
        guard let currency, !currency.isEmpty else {
            return defaultCurrency
        }
        return currency
    }
}

enum TavoniSocialBridge {
    private static let defaultCurrency = "USD"

    static func trackCheckoutStart(price: NSDecimalNumber?, currency: String?) {
        guard let price,
              price.compare(NSDecimalNumber.zero) == .orderedDescending else {
            return
        }

        AppEvents.shared.logEvent(
            AppEvents.Name("fb_mobile_initiated_checkout"),
            valueToSum: price.doubleValue,
            parameters: [.currency: currencyOrDefault(currency)]
        )
    }

    static func trackStorePurchase(price: NSDecimalNumber?, currency: String?) {

        guard let price,
              price.compare(NSDecimalNumber.zero) == .orderedDescending else {
            return
        }

        AppEvents.shared.logPurchase(
            amount: price.doubleValue,
            currency: currencyOrDefault(currency)
        )
    }

    private static func currencyOrDefault(_ currency: String?) -> String {
        guard let currency, !currency.isEmpty else {
            return defaultCurrency
        }
        return currency
    }
}
