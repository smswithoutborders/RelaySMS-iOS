//
//  SecurityCurve25519.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 27/06/2024.
//

import CryptoKit
import Foundation

/// An error we can throw when something goes wrong.
class SecurityCurve25519 {
    enum Exceptions: Error {
        case DuplicateKeys
        case FailedToStoreItem
        case FailedToCreateSecKey
        case KeychainFailedToRead
    }

    public static func generateKeyPair(keystoreAlias: String) throws -> 
    (privateKey: Curve25519.KeyAgreement.PrivateKey, secKey: SecKey) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        let attributes = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                          kSecAttrKeySizeInBits as String: 256,
                          kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                          kSecAttrKeyClass as String: kSecAttrKeyClassPrivate] as [String: Any]
        
        // Get a SecKey representation.
        // TODO: Extract storing out, there's no need to store the key if computation does not happen on it
        guard let secKey = SecKeyCreateWithData(privateKey.rawRepresentation as CFData, attributes as CFDictionary, nil)
        else {
            throw Exceptions.FailedToCreateSecKey
        }
        
        // Describe the add operation.
        let query = [kSecClass: kSecClassKey, kSecAttrApplicationTag: keystoreAlias,
                     kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
                     kSecUseDataProtectionKeychain: true,
                  kSecValueRef: secKey] as [String: Any]


        // Add the key to the keychain.
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw Exceptions.DuplicateKeys
            }
            print(status)
            throw Exceptions.FailedToStoreItem
        }
        return (privateKey, secKey)
    }
    
    public static func getKeyPair(keystoreAlias: String) throws -> Curve25519.KeyAgreement.PrivateKey? {
        // Seek an elliptic-curve key with a given label.
        let query = [kSecClass: kSecClassKey, kSecAttrApplicationLabel: keystoreAlias,
                     kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                     kSecUseDataProtectionKeychain: true,
                     kSecReturnRef: true] as [String: Any]


        // Find and cast the result as a SecKey instance.
        var item: CFTypeRef?
        
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess:
//            return item as! SecKey
            return item as! Curve25519.KeyAgreement.PrivateKey
        case errSecItemNotFound: return nil
        case let status: throw Exceptions.KeychainFailedToRead
        }
    }
    
    
    static public func calculateSharedSecret( privateKey: Curve25519.KeyAgreement.PrivateKey,
                                              publicKey: Curve25519.KeyAgreement.PublicKey) throws -> SymmetricKey {
        
        do {
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
            return sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data(),
                sharedInfo: "x25591_key_exchange".data(using: .utf8)!,
                outputByteCount: 32)
        } catch {
            throw error
        }
    }
    
}
