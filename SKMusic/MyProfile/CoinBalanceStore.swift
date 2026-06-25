//
//  CoinBalanceStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import Foundation

extension Notification.Name {
    static let coinBalanceDidChange = Notification.Name("coinBalanceDidChange")
}

enum CoinBalanceStore {
    private static let legacyBalanceKey = "coin_balance"
    private static let legacyProcessedTransactionIDsKey = "coin_processed_transaction_ids"
    private static let balanceKeyPrefix = "coin_balance"
    private static let processedTransactionIDsKeyPrefix = "coin_processed_transaction_ids"
    private static let defaultBalance = 100

    static var balance: Int {
        let defaults = UserDefaults.standard
        migrateLegacyBalanceIfNeeded(defaults: defaults)

        guard defaults.object(forKey: balanceKey) != nil else {
            return defaultBalance
        }
        return defaults.integer(forKey: balanceKey)
    }

    @discardableResult
    static func credit(coins: Int, transactionID: UInt64) -> Bool {
        credit(coins: coins, transactionIdentifier: String(transactionID))
    }

    @discardableResult
    static func credit(coins: Int, transactionIdentifier: String) -> Bool {
        let identifier = transactionIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !identifier.isEmpty else { return false }

        migrateLegacyBalanceIfNeeded(defaults: UserDefaults.standard)

        var processedIDs = Set(UserDefaults.standard.stringArray(forKey: processedTransactionIDsKey) ?? [])
        guard !processedIDs.contains(identifier) else {
            return false
        }

        processedIDs.insert(identifier)
        setBalance(balance + coins)
        UserDefaults.standard.set(Array(processedIDs), forKey: processedTransactionIDsKey)
        return true
    }

    private static func setBalance(_ newBalance: Int) {
        UserDefaults.standard.set(newBalance, forKey: balanceKey)
        NotificationCenter.default.post(name: .coinBalanceDidChange, object: nil)
    }

    private static var balanceKey: String {
        "\(balanceKeyPrefix).\(currentAccountToken)"
    }

    private static var processedTransactionIDsKey: String {
        "\(processedTransactionIDsKeyPrefix).\(currentAccountToken)"
    }

    private static var currentAccountToken: String {
        AuthSession.storageSafeComponent(AuthSession.currentEmail ?? "guest")
    }

    private static func migrateLegacyBalanceIfNeeded(defaults: UserDefaults) {
        guard AuthSession.isCurrentTestAccount else { return }
        guard defaults.object(forKey: balanceKey) == nil else { return }
        guard defaults.object(forKey: legacyBalanceKey) != nil else { return }

        defaults.set(defaults.integer(forKey: legacyBalanceKey), forKey: balanceKey)

        if let processedIDs = defaults.stringArray(forKey: legacyProcessedTransactionIDsKey) {
            defaults.set(processedIDs, forKey: processedTransactionIDsKey)
        }
    }
}
