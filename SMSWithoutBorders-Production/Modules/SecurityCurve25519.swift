//
//  SecurityCurve25519.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 27/06/2024.
//

import CryptoKit
import Foundation

/// An error we can throw when something goes wrong.
struct KeyStoreError: Error, CustomStringConvertible {
    var message: String

    init(_ message: String) {
        self.message = message
    }

    public var description: String {
        return message
    }
}

class SecurityCurve25519 {
    
    public static func generateKeyPair(keystoreAlias: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        let attributes = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                          kSecAttrKeySizeInBits as String: 256,
                          kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                          kSecAttrKeyClass as String: kSecAttrKeyClassPrivate] as [String: Any]
        
        // Get a SecKey representation.
        guard let secKey = SecKeyCreateWithData(privateKey.rawRepresentation as CFData, attributes as CFDictionary, nil)
        else {
            throw KeyStoreError("Unable to create SecKey representation.")
        }
        
        // Describe the add operation.
        let query = [kSecClass: kSecClassKey, kSecAttrApplicationLabel: keystoreAlias,
                     kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
                     kSecUseDataProtectionKeychain: true,
                  kSecValueRef: secKey] as [String: Any]


        // Add the key to the keychain.
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeyStoreError("Unable to store item: \(status.description)")
        }
        
        return privateKey
    }
    
    public static func getKeyPair(keystoreAlias: String) throws -> Curve25519.KeyAgreement.PrivateKey? {
        // Seek an elliptic-curve key with a given label.
        let query = [kSecClass: kSecClassKey, kSecAttrApplicationLabel: keystoreAlias,
                     kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                     kSecUseDataProtectionKeychain: true,
                     kSecReturnRef: true] as [String: Any]


        // Find and cast the result as a SecKey instance.
        var item: CFTypeRef?
        var privateKey: Curve25519.KeyAgreement.PrivateKey?
        
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess:
            if let keyData = item as? Data {
                do {
                    privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
                } catch {
                    print("Failed to construct the private key: \(error)")
                }
            }
        case errSecItemNotFound: return nil
        case let status: throw KeyStoreError("Keychain read failed: \(status.description)")
        }
        return privateKey
    }
    
    
    static public func calculateSharedSecret( privateKey: Curve25519.KeyAgreement.PrivateKey,
                                              publicKey: Curve25519.KeyAgreement.PublicKey) throws -> SymmetricKey {
        
        do {
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
            return sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: "".data(using:.utf8)!,
                sharedInfo: "x25591_key_exchange".data(using: .utf8)!,
                outputByteCount: 32)
        } catch {
            throw error
        }
    }
    
}
