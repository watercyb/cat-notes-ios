import CommonCrypto
import CryptoKit
import Foundation
import SwiftUI

class Crypto {
    static let shared = Crypto()

    private let saltSize = 16
    private let ivSize = 12
    private let iterations = 200_000
    private let keyLength = 32  // 256 bits

    private init() {}

    // MARK: - Generate key from password
    func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        var derivedKeyData = Data(repeating: 0, count: keyLength)

        _ = derivedKeyData.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password,
                    passwordData.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    derivedBytes.baseAddress?.assumingMemoryBound(
                        to: UInt8.self
                    ),
                    keyLength
                )
            }
        }
        return SymmetricKey(data: derivedKeyData)
    }

    // MARK: - Encrypt with password
    func encrypt(password: String, plaintext: String) throws -> String {
        let salt = randomBytes(count: saltSize)
        let key = deriveKey(password: password, salt: salt)
        let iv = randomBytes(count: ivSize)

        let sealedBox = try AES.GCM.seal(
            Data(plaintext.utf8),
            using: key,
            nonce: AES.GCM.Nonce(data: iv)
        )

        // Combine salt + iv + ciphertext
        var combined = Data()
        combined.append(salt)
        combined.append(iv)
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return combined.base64EncodedString()
    }

    // MARK: - Encrypt with password
    func encrypt(password: String, plaintext: String) throws -> (
        salt: Data, key: SymmetricKey, encryptedText: String
    ) {
        let salt = randomBytes(count: saltSize)
        let key = deriveKey(password: password, salt: salt)
        let iv = randomBytes(count: ivSize)

        let sealedBox = try AES.GCM.seal(
            Data(plaintext.utf8),
            using: key,
            nonce: AES.GCM.Nonce(data: iv)
        )

        // Combine salt + iv + ciphertext
        var combined = Data()
        combined.append(salt)
        combined.append(iv)
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return (salt: salt, key: key, encryptedText: combined.base64EncodedString())
    }

    // MARK: - Decrypt with password
    func decrypt(password: String, encrypted: String) throws -> (
        salt: Data, key: SymmetricKey, plaintext: String
    ) {
        let combined = Data(base64Encoded: encrypted)!

        guard combined.count >= saltSize + ivSize + 16 else {
            throw NSError(
                domain: "Crypto",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid encrypted data"
                ]
            )
        }

        let salt = combined.subdata(in: 0..<saltSize)
        let iv = combined.subdata(in: saltSize..<saltSize + ivSize)
        let ciphertext = combined.subdata(
            in: saltSize + ivSize..<(combined.count - 16)
        )  // last 16 = tag
        let tag = combined.subdata(in: (combined.count - 16)..<combined.count)

        let key = deriveKey(password: password, salt: salt)

        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: iv),
            ciphertext: ciphertext,
            tag: tag
        )
        let decrypted = try AES.GCM.open(sealedBox, using: key)

        return (
            salt: salt, key: key,
            plaintext: String(data: decrypted, encoding: .utf8)!
        )
    }

    // MARK: - Generate random salt/iv
    private func randomBytes(count: Int) -> Data {
        var bytes = Data(count: count)
        _ = bytes.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        return bytes
    }

    // MARK: - Generate key separately
    func getKey(password: String) -> (salt: Data, key: SymmetricKey) {
        let salt = randomBytes(count: saltSize)
        let key = deriveKey(password: password, salt: salt)
        return (salt, key)
    }

    // MARK: - Encrypt using a pre-derived SymmetricKey and salt
    func encrypt(salt: Data, key: SymmetricKey, plaintext: String) throws
        -> String
    {
        let iv = randomBytes(count: ivSize)

        let sealedBox = try AES.GCM.seal(
            Data(plaintext.utf8),
            using: key,
            nonce: AES.GCM.Nonce(data: iv)
        )

        var combined = Data()
        combined.append(salt)
        combined.append(iv)
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return combined.base64EncodedString()
    }
}
