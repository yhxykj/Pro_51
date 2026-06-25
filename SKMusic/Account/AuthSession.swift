//
//  AuthSession.swift
//  SKMusic
//
//  Created by Codex on 2026/6/22.
//

import Foundation

enum AuthSession {
    static let testEmail = "music666@gmail.com"
    static let testPassword = "123456"

    enum RegistrationResult {
        case success
        case invalidEmail
        case invalidPassword
        case emailAlreadyExists
    }

    private static let loggedInKey = "auth_session_logged_in"
    private static let currentEmailKey = "auth_session_current_email"
    private static let registeredAccountsKey = "auth_session_registered_accounts"

    static var isLoggedIn: Bool {
        UserDefaults.standard.bool(forKey: loggedInKey)
    }

    static var currentEmail: String? {
        UserDefaults.standard.string(forKey: currentEmailKey)
    }

    static var isCurrentTestAccount: Bool {
        guard let currentEmail else { return false }
        return normalizedEmail(currentEmail) == testEmail
    }

    static func canSignIn(email: String, password: String) -> Bool {
        let email = normalizedEmail(email)
        let password = normalizedPassword(password)

        guard isValidEmail(email), !password.isEmpty else { return false }

        if email == testEmail {
            return password == testPassword
        }

        return registeredAccounts[email] == password
    }

    static func register(email: String, password: String) -> RegistrationResult {
        let email = normalizedEmail(email)
        let password = normalizedPassword(password)

        guard isValidEmail(email) else {
            return .invalidEmail
        }

        guard password.count >= 6 else {
            return .invalidPassword
        }

        guard email != testEmail, registeredAccounts[email] == nil else {
            return .emailAlreadyExists
        }

        var accounts = registeredAccounts
        accounts[email] = password
        saveRegisteredAccounts(accounts)
        return .success
    }

    static func start(email: String) {
        UserDefaults.standard.set(true, forKey: loggedInKey)
        UserDefaults.standard.set(normalizedEmail(email), forKey: currentEmailKey)
    }

    static func end() {
        UserDefaults.standard.removeObject(forKey: loggedInKey)
        UserDefaults.standard.removeObject(forKey: currentEmailKey)
    }

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func storageSafeComponent(_ text: String) -> String {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let token = normalizedText.map { character in
            character.isLetter || character.isNumber ? String(character) : "_"
        }.joined()
        return token.isEmpty ? "guest" : token
    }

    private static var registeredAccounts: [String: String] {
        guard
            let data = UserDefaults.standard.data(forKey: registeredAccountsKey),
            let accounts = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }

        return accounts
    }

    private static func saveRegisteredAccounts(_ accounts: [String: String]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: registeredAccountsKey)
    }

    private static func normalizedPassword(_ password: String) -> String {
        password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isValidEmail(_ email: String) -> Bool {
        guard email.filter({ $0 == "@" }).count == 1 else { return false }

        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        guard
            let localPart = parts.first,
            let domain = parts.last,
            !localPart.isEmpty,
            !domain.isEmpty,
            domain.contains(".")
        else {
            return false
        }
        return !email.contains(" ")
    }
}
