//
//  Keystore.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 25/09/2026.
//

import Foundation
import CryptoKit
import SwiftData

class Keystore {
    enum KeystoreErrors: Error {
        case failedToFetchLocalKey
        case failedToGetStaticKey
        case failedToFetchPrivateKeyDataForKeyId(keyId: Int)
        case failedToDeleteKeyFromKeystore
        case failedToQueryKeystore
        case failedToGetAllKeys
        case failedToDeserializeKey
    }
    
    public static let PUBLISHER_SERVER_PUBLIC_KEY = "COM.AFKANERD.PUBLISHER_SERVER_PUBLIC_KEY"
    public static let PUBLISHER_TOKEN_ID = "PUBLISHER_TOKEN_ID"
    public static let PUBLISHER_TOKEN_HASH = "PUBLISHER_TOKEN_HASH"
    public static let PUBLISHER_KEY_ID_PRIVATE_KEYS = "PUBLISHER_KEY_ID_PRIVATE_KEYS"

    var accountTag: String

    init(accountTag: String) {
        self.accountTag = accountTag
    }
    
    public static func getLocalKeysAccountTag(
        keyId: UInt8,
        tokenId: UUID,
    ) -> String {
        return PUBLISHER_KEY_ID_PRIVATE_KEYS + "_" + tokenId.uuidString + "_" + String(keyId)
    }
    
    func savePrivateKeyToKeychain(keyData: Data) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: accountTag.data(using: .utf8)!,
            kSecValueData: keyData,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Restricts data syncing/sharing if desired
        ]
        
        // First, delete any old instance of this specific key to avoid duplication conflicts
        SecItemDelete(query as CFDictionary)
        
        // Save the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private var baseQuery: [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: accountTag.data(using: .utf8)!
        ]
    }

    func deletePrivateKeyFromKeychain() throws -> Bool {
        let status = SecItemDelete(baseQuery as CFDictionary)
        print("Keychain delete status: \(status)")   // temporary, to confirm
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false   // nothing was deleted; don't report success
        default:
            throw KeystoreErrors.failedToDeleteKeyFromKeystore
        }
    }

    func isAvailable() throws -> Bool {
        var query = baseQuery
        query[kSecReturnAttributes] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed: return true
        case errSecItemNotFound: return false
        default: throw KeystoreErrors.failedToQueryKeystore
        }
    }
    
    func loadPrivateKeyFromKeychain() throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: accountTag.data(using: .utf8)!,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        let _ = try deletePrivateKeyFromKeychain()
        
        return data
    }
    
    public static func loadRandom(
        tokenId: UUID,
        withAttachment: Bool,
        into context: ModelContext
    ) throws -> (LocalKeypair, Data)? {
        do {
            let allTags = try getAllTags()
            let randomOffset = Int.random(in: 0..<allTags.count)
            
//            var randomDescriptor = FetchDescriptor<LocalKeys>()
//            randomDescriptor.fetchLimit = 1
//            randomDescriptor.fetchOffset = randomOffset
//            
//            guard let serverKeys = try context.fetch(randomDescriptor).first else {
//                throw KeystoreErrors.failedToFetchLocalKey
//            }
//            
//            let serverKeyId = serverKeys.keyId
//            let forKeyId = #Predicate<LocalKeys> { keys in
//                keys.keyId == serverKeyId
//            }
//            
//            let descriptor = FetchDescriptor<LocalKeys>( predicate: forKeyId )
//            guard let localKey = try context.fetch(descriptor).first else {
//                throw KeystoreErrors.failedToFetchLocalKey
//            }
            let keystore = Keystore(accountTag: allTags[randomOffset])
            guard let keystoreData = try keystore.loadPrivateKeyFromKeychain() else {
                throw KeystoreErrors.failedToFetchPrivateKeyDataForKeyId(keyId: randomOffset)
            }
            
            let localKey = try LocalKeypair.deserialize(data: keystoreData)
            
            guard let staticKeys = try StaticKeys.getStaticKey(kid: Int(localKey.keyId)) else {
                throw KeystoreErrors.failedToGetStaticKey
            }
            guard let authenticationPublicKey = try staticKeys.getKey() else {
                throw KeystoreErrors.failedToGetStaticKey
            }
            
            return (localKey, authenticationPublicKey)
        } catch {
            throw error
        }
    }
    
    static func getAllTags() throws -> [String] {
        var allItems: [String] = []
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecMatchLimit as String: kSecMatchLimitAll, // Return all matching items
            kSecReturnAttributes as String: true,       // Return metadata (keys/accounts)
            kSecReturnData as String: true              // Return the actual protected data
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw KeystoreErrors.failedToGetAllKeys
        }
        
        for item in items {
            // Extract the Key name (Account attribute)
            if let account = item[kSecAttrAccount as String] as? String {
                allItems.append(account)
            }
        }
        
        return allItems
    }
    
    static func getAllKeychainItems() throws -> [String: Data] {
        var allItems: [String: Data] = [:]
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecMatchLimit as String: kSecMatchLimitAll, // Return all matching items
            kSecReturnAttributes as String: true,       // Return metadata (keys/accounts)
            kSecReturnData as String: true              // Return the actual protected data
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw KeystoreErrors.failedToGetAllKeys
        }
        
        for item in items {
            // Extract the Key name (Account attribute)
            if let account = item[kSecAttrAccount as String] as? String {
                // Extract and decode the underlying Data value
                guard let data = item[kSecValueData as String] as? Data else {
                    throw KeystoreErrors.failedToFetchLocalKey
                }
                allItems[account] = data
            }
        }
    
        return allItems
    }
    
}


public class LocalKeypair {
    let keyId: UInt8
    let privateKey: Curve25519.KeyAgreement.PrivateKey
    let serverPublicKey: Data
    let tokenId: UInt32
    let tokenHash: Data
    
    init(
        keyId: UInt8,
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        serverPublicKey: Data,
        tokenId: UInt32,
        tokenHash: Data,
    ) {
        self.keyId = keyId
        self.privateKey = privateKey
        self.serverPublicKey = serverPublicKey
        self.tokenId = tokenId
        self.tokenHash = tokenHash
    }
    
    public func serialize() -> Data {
        return Data([keyId])
        + privateKey.rawRepresentation
        + serverPublicKey
        + withUnsafeBytes(of: tokenId) { Data($0) }
        + tokenHash
    }
    
    public static func deserialize(data: Data) throws -> LocalKeypair {
        let keyId = data.prefix(1).withUnsafeBytes { pointer in
            pointer.load(as: UInt8.self)
        }
        let rawPrivateKey = data.subdata(in: 1..<33)
        let serverPublicKey = data.subdata(in: 33..<65)
        let tokenId = data.subdata(in: 65..<69).withUnsafeBytes { pointer in
            pointer.load(as: UInt32.self)
        }
        let tokenHash = Data(data[69...])

        let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawPrivateKey)
        return LocalKeypair(
            keyId: keyId,
            privateKey: privateKey,
            serverPublicKey: serverPublicKey,
            tokenId: tokenId,
            tokenHash: tokenHash
        )
    }
}


