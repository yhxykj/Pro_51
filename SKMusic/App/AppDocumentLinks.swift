//
//  AppDocumentLinks.swift
//  SKMusic
//
//  Created by Codex on 2026/7/22.
//

import SafariServices
import UIKit

enum AppDocumentLink {
    case userAgreement
    case privacyPolicy
    case communityGuidelines

    var url: URL {
        switch self {
        case .userAgreement:
            return URL(string: "https://docs.google.com/document/d/1YDbclrL2QXuLvlteLxvPn5pp2WwYYu4syv_QnAgFmaQ/edit?usp=sharing")!
        case .privacyPolicy:
            return URL(string: "https://docs.google.com/document/d/1UTrf86P3ncP8w9GsasMPwe9js9SdTOQ2lmz0pvnS6w8/edit?usp=sharing")!
        case .communityGuidelines:
            return URL(string: "https://docs.google.com/document/d/1gNaPpn9GKEFn-itr1U5xmUJEyHeIO7LGu2MxVaFCqz4/edit?usp=sharing")!
        }
    }
}

extension UIViewController {
    func presentAppDocument(_ document: AppDocumentLink) {
        let safariViewController = SFSafariViewController(url: document.url)
        safariViewController.dismissButtonStyle = .close
        safariViewController.preferredBarTintColor = .white
        safariViewController.preferredControlTintColor = UIColor(red: 0.88, green: 0.24, blue: 0.65, alpha: 1)
        present(safariViewController, animated: true)
    }
}
