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

    private static let loggedInKey = "auth_session_logged_in"
    private static let currentEmailKey = "auth_session_current_email"

    static var isLoggedIn: Bool {
        UserDefaults.standard.bool(forKey: loggedInKey)
    }

    static var currentEmail: String? {
        UserDefaults.standard.string(forKey: currentEmailKey)
    }

    static func canSignIn(email: String, password: String) -> Bool {
        normalizedEmail(email) == testEmail && password == testPassword
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
}
