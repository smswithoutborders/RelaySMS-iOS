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
        case failedToImportKeys(name: String)
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
    
    static func importKeys(_ keyDatas: [String: Data]) throws {
        for (name, value) in keyDatas {
            let query: [CFString: Any] = [
                kSecClass: kSecClassKey,
                kSecAttrApplicationTag: name,
                kSecValueData: value,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Restricts data syncing/sharing if desired
            ]
            
            // First, delete any old instance of this specific key to avoid duplication conflicts
            SecItemDelete(query as CFDictionary)
            
            // Save the new item
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                throw KeystoreErrors.failedToImportKeys(name: name)
            }
        }
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
            let allTags = try getAllTags().filter { $0.starts(with: "\(PUBLISHER_KEY_ID_PRIVATE_KEYS)_\(tokenId.uuidString)_")}
            let randomOffset = Int.random(in: 0..<allTags.count)
            
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
            kSecReturnAttributes as String: true        // Return metadata attributes only
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Handle empty keychain gracefully instead of throwing an error
        if status == errSecItemNotFound {
            return []
        }
        
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw KeystoreErrors.failedToGetAllKeys
        }
        
        for item in items {
            // Extract kSecAttrApplicationTag (stored as Data) and convert back to String
            if let tagData = item[kSecAttrApplicationTag as String] as? Data,
               let tagString = String(data: tagData, encoding: .utf8) {
                allItems.append(tagString)
            }
        }
        
        return allItems
    }
    
    static func getAllKeychainItems() throws -> [String: Data] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ]
        
        var itemResult: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &itemResult)
        
        // errSecItemNotFound means there are simply no keys saved yet
        if status == errSecItemNotFound {
            return [:]
        }
        
        guard status == errSecSuccess else {
            throw KeystoreErrors.failedToFetchLocalKey
        }
        
        // SecItemCopyMatching returns an array of dictionaries when kSecMatchLimitAll is used
        guard let items = itemResult as? [[String: Any]] else {
            return [:]
        }
        
        var allItems: [String: Data] = [:]
        
        for item in items {
            // 1. kSecAttrApplicationTag returns Data, so we convert it to a String
            if let tagData = item[kSecAttrApplicationTag as String] as? Data,
               let account = String(data: tagData, encoding: .utf8) {
                
                // 2. Extract the underlying Data value
                guard let keyData = item[kSecValueData as String] as? Data else {
                    throw KeystoreErrors.failedToFetchLocalKey
                }
                
                allItems[account] = keyData
            }
        }
        
        return allItems
    }

    enum KeychainError: Error {
        case invalidData
        case itemNotFound
        case unknown(OSStatus)
    }
    
    static func savePassword(_ password: String, service: String, account: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Attempt to add the item to the Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists; update it instead
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unknown(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Retrieves a password from the Keychain.
    /// - Parameters:
    ///   - service: The unique identifier used when saving.
    ///   - account: The specific account or username associated with the password.
    /// - Returns: The decrypted password string.
    static func retrievePassword(service: String, account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return password
    }
    
    /// Deletes a password from the Keychain.
    /// - Parameters:
    ///   - service: The unique identifier used when saving.
    ///   - account: The specific account or username associated with the password.
    static func deletePassword(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Treat errSecItemNotFound as success to make deletion idempotent,
        // or throw if you prefer strict tracking.
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
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


