import CommonCrypto
import Foundation

enum TavoniCipherError: Error {
    case badCipherConfig
    case badInput
    case cipherFailed
    case badHex
    case badPayload
}

enum TavoniCipherBox {
    static func encryptHexText(_ plainText: String, routeConfig: TavoniRouteConfig = .activeConfig) throws -> String {
        guard routeConfig.cipherSeed.count == kCCKeySizeAES128,
              routeConfig.cipherVector.count == kCCBlockSizeAES128,
              let keyData = routeConfig.cipherSeed.data(using: .utf8),
              let ivData = routeConfig.cipherVector.data(using: .utf8),
              let inputData = plainText.data(using: .utf8) else {
            throw TavoniCipherError.badCipherConfig
        }

        let outputData = try crypt(
            operation: CCOperation(kCCEncrypt),
            inputData: inputData,
            keyData: keyData,
            ivData: ivData
        )

        return outputData.map { String(format: "%02x", $0) }.joined()
    }

    static func decryptPayload(cipherText: String, routeConfig: TavoniRouteConfig = .activeConfig) throws -> [String: Any] {
        guard routeConfig.cipherSeed.count == kCCKeySizeAES128,
              routeConfig.cipherVector.count == kCCBlockSizeAES128,
              let keyData = routeConfig.cipherSeed.data(using: .utf8),
              let ivData = routeConfig.cipherVector.data(using: .utf8) else {
            throw TavoniCipherError.badCipherConfig
        }

        let inputData = try data(fromHex: cipherText)
        let outputData = try crypt(
            operation: CCOperation(kCCDecrypt),
            inputData: inputData,
            keyData: keyData,
            ivData: ivData
        )

        guard let dictionary = try? JSONSerialization.jsonObject(with: outputData, options: []) as? [String: Any] else {
            throw TavoniCipherError.badPayload
        }
        return dictionary
    }

    private static func data(fromHex hex: String) throws -> Data {
        guard hex.count.isMultiple(of: 2) else {
            throw TavoniCipherError.badHex
        }

        var data = Data()
        var pair = ""
        for character in hex {
            pair.append(character)
            if pair.count == 2 {
                guard let byte = UInt8(pair, radix: 16) else {
                    throw TavoniCipherError.badHex
                }
                data.append(byte)
                pair = ""
            }
        }
        return data
    }

    private static func crypt(
        operation: CCOperation,
        inputData: Data,
        keyData: Data,
        ivData: Data
    ) throws -> Data {
        let bufferSize = inputData.count + kCCBlockSizeAES128
        var outputBuffer = Data(count: bufferSize)
        var processedByteCount: size_t = 0

        let status = outputBuffer.withUnsafeMutableBytes { outputBytes in
            inputData.withUnsafeBytes { inputBytes in
                keyData.withUnsafeBytes { keyBytes in
                    ivData.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            kCCKeySizeAES128,
                            ivBytes.baseAddress,
                            inputBytes.baseAddress,
                            inputData.count,
                            outputBytes.baseAddress,
                            bufferSize,
                            &processedByteCount
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            throw TavoniCipherError.cipherFailed
        }

        return outputBuffer.prefix(processedByteCount)
    }
}
