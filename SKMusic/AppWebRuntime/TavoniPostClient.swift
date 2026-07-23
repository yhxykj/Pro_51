import Foundation

enum TavoniPostError: Error {
    case badURL
    case badBody
    case emptyPayload
    case badJSON
    case missingCipherResult
}

final class TavoniPostClient {
    static let tunnel = TavoniPostClient()

    private let routeConfig = TavoniRouteConfig.activeConfig

    private init() {}

    func post(
        path: String,
        parameters: [String: Any],
        allowsPlainResponse: Bool = false,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: "\(routeConfig.gatewayRoot)/\(path)") else {
            completion(.failure(TavoniPostError.badURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(TavoniLocalVault.deviceStamp, forHTTPHeaderField: "deviceNo")
        request.setValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "", forHTTPHeaderField: "appVersion")
        request.setValue(routeConfig.clientMark, forHTTPHeaderField: "appId")
        request.setValue(TavoniRouteConfig.coverHeaders.firstHeaderValue, forHTTPHeaderField: TavoniRouteConfig.coverHeaders.firstHeaderName)
        request.setValue(TavoniRouteConfig.coverHeaders.secondHeaderValue, forHTTPHeaderField: TavoniRouteConfig.coverHeaders.secondHeaderName)

        if let pushMarkText = TavoniLocalVault.pushMark, !pushMarkText.isEmpty {
            request.setValue(pushMarkText, forHTTPHeaderField: "pushToken")
        }
        if let sessionText = TavoniLocalVault.sessionToken, !sessionText.isEmpty {
            request.setValue(sessionText, forHTTPHeaderField: "loginToken")
        }

        if !parameters.isEmpty {
            guard let jsonText = TavoniJSONCodec.text(from: parameters),
                  let encryptedText = try? TavoniCipherBox.encryptHexText(jsonText, routeConfig: routeConfig),
                  let bodyData = encryptedText.data(using: .utf8) else {
                completion(.failure(TavoniPostError.badBody))
                return
            }
            request.httpBody = bodyData
        }

        if routeConfig.traceSwitch {
            print("Tavoni canvas request: \(url.absoluteString)")
            print("Tavoni canvas headers: \(request.allHTTPHeaderFields ?? [:])")
            print("Tavoni canvas params: \(parameters)")
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let data, let responseText = String(data: data, encoding: .utf8) else {
                    completion(.failure(TavoniPostError.emptyPayload))
                    return
                }

                if self.routeConfig.traceSwitch {
                    print("Tavoni canvas response: \(responseText)")
                }

                guard let response = TavoniJSONCodec.payloadDictionary(from: responseText) else {
                    completion(.failure(TavoniPostError.badJSON))
                    return
                }

                guard let encryptedResult = response["result"] as? String else {
                    if allowsPlainResponse {
                        completion(.success(response))
                    } else {
                        completion(.failure(TavoniPostError.missingCipherResult))
                    }
                    return
                }

                do {
                    let decrypted = try TavoniCipherBox.decryptPayload(cipherText: encryptedResult, routeConfig: self.routeConfig)
                    completion(.success(decrypted))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
