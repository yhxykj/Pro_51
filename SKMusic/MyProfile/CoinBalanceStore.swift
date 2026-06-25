//
//  CoinBalanceStore.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import Foundation

enum CoinBalanceStore {
    private static let balanceKey = "coin_balance"
    private static let processedTransactionIDsKey = "coin_processed_transaction_ids"
    private static let defaultBalance = 9999

    static var balance: Int {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: balanceKey) != nil else {
            return defaultBalance
        }
        return defaults.integer(forKey: balanceKey)
    }

    @discardableResult
    static func credit(coins: Int, transactionID: UInt64) -> Bool {
        let identifier = String(transactionID)
        var processedIDs = Set(UserDefaults.standard.stringArray(forKey: processedTransactionIDsKey) ?? [])
        guard !processedIDs.contains(identifier) else {
            return false
        }

        processedIDs.insert(identifier)
        UserDefaults.standard.set(balance + coins, forKey: balanceKey)
        UserDefaults.standard.set(Array(processedIDs), forKey: processedTransactionIDsKey)
        return true
    }
}
