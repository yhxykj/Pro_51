import CoreTelephony
import Foundation
import Security
import SystemConfiguration
import UIKit

enum TavoniLocalVault {
    static var sessionToken: String? {
        get { readVaultText(key: TavoniRouteConfig.sessionTokenSlot) }
        set { setVaultText(newValue, key: TavoniRouteConfig.sessionTokenSlot) }
    }

    static var secretText: String? {
        get { readVaultText(key: TavoniRouteConfig.secretSlot) }
        set { setVaultText(newValue, key: TavoniRouteConfig.secretSlot) }
    }

    static var pushMark: String? {
        UserDefaults.standard.string(forKey: TavoniRouteConfig.pushCacheSlot)
    }

    static var deviceStamp: String {
        if let stored = readVaultText(key: TavoniRouteConfig.deviceStampSlot), !stored.isEmpty {
            return stored
        }

        let generated = UIDevice.current.identifierForVendor?.uuidString ?? TavoniRouteConfig.fallbackDeviceMark
        saveVaultText(generated, key: TavoniRouteConfig.deviceStampSlot)
        return generated
    }

    static func savePushMark(_ deviceToken: Data) {
        let pushHexText = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(pushHexText, forKey: TavoniRouteConfig.pushCacheSlot)
    }

    static func removeSessionToken() {
        removeVaultText(TavoniRouteConfig.sessionTokenSlot)
    }

    static func saveVaultText(_ value: String, key: String) {
        guard let valueData = value.data(using: .utf8) else { return }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func readVaultText(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func removeVaultText(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func setVaultText(_ value: String?, key: String) {
        guard let value, !value.isEmpty else {
            removeVaultText(key)
            return
        }
        saveVaultText(value, key: key)
    }
}

enum TavoniDeviceProbe {
    static var keyboardMarks: [String] {
        UITextInputMode.activeInputModes.compactMap { $0.primaryLanguage }
    }

    static func hasCarrierSignal() -> Bool {
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            return info.serviceCurrentRadioAccessTechnology?.values.isEmpty == false
        }
        return info.currentRadioAccessTechnology != nil
    }

    static func isTunnelActive() -> Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = settings["__SCOPED__"] as? [String: Any] else {
            return false
        }

        let vpnKeys = ["tap", "tun", "ppp", "ipsec", "utun"]
        return scoped.keys.contains { key in
            let lowerKey = key.lowercased()
            return vpnKeys.contains { lowerKey.contains($0) }
        }
    }
}

enum TavoniJSONCodec {
    static func text(from dictionary: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }

    static func payloadDictionary(from text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = object as? [String: Any] else {
            return nil
        }
        return dictionary
    }

    static func text(from object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: []),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }
}
