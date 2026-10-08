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
//            kSecAttrKeyType: kSecAttrKeyTypeEC, // Curve25519 maps to Elliptic Curve
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
        
        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeystoreErrors.failedToDeleteKeyFromKeystore
        }
        
        return data
    }
    
    public static func loadRandom(
        tokenId: UUID,
        withAttachment: Bool,
        into container: ModelContainer
    ) throws -> (LocalKeypair, Data, Int)? {
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<LocalKeys>()
        do {
            let totalCount = try context.fetchCount(descriptor)
            guard totalCount > 0 else { return nil }
            
            let startRange = withAttachment ? 0 : 16
            let endRange = withAttachment ? 16 : 256
            let randomOffset = Int.random(in: startRange..<endRange)
            
            var randomDescriptor = FetchDescriptor<LocalKeys>()
            randomDescriptor.fetchLimit = 1
            randomDescriptor.fetchOffset = randomOffset
            
            guard let serverKeys = try context.fetch(randomDescriptor).first else {
                throw KeystoreErrors.failedToFetchLocalKey
            }
            
            let serverKeyId = serverKeys.keyId
            let forKeyId = #Predicate<LocalKeys> { keys in
                keys.keyId == serverKeyId
            }
            
            let descriptor = FetchDescriptor<LocalKeys>( predicate: forKeyId )
            guard let localKey = try context.fetch(descriptor).first else {
                throw KeystoreErrors.failedToFetchLocalKey
            }
            
            guard let staticKeys = try StaticKeys.getStaticKey(kid: Int(localKey.keyId)) else {
                throw KeystoreErrors.failedToGetStaticKey
            }
            guard let authenticationPublicKey = try staticKeys.getKey() else {
                throw KeystoreErrors.failedToGetStaticKey
            }
            
            let accountTag = Keystore.getLocalKeysAccountTag(
                keyId: UInt8(serverKeyId),
                tokenId: tokenId,
            )
            let keystore = Keystore(accountTag: accountTag)
            
            do {
                guard let rawKeyData = try keystore.loadPrivateKeyFromKeychain() else {
                    throw KeystoreErrors.failedToFetchPrivateKeyDataForKeyId(keyId: serverKeyId)
                }
                
                let keypair = try LocalKeypair.deserialize(data: rawKeyData)
                return (keypair, authenticationPublicKey, serverKeyId)
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
    
}


public class LocalKeypair {
    let privateKey: Curve25519.KeyAgreement.PrivateKey
    let serverPublicKey: Data
    let tokenId: UInt32
    let tokenHash: Data
    
    init(
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        serverPublicKey: Data,
        tokenId: UInt32,
        tokenHash: Data,
    ) {
        self.privateKey = privateKey
        self.serverPublicKey = serverPublicKey
        self.tokenId = tokenId
        self.tokenHash = tokenHash
    }
    
    public func serialize() -> Data {
        return privateKey.rawRepresentation
        + serverPublicKey
        + withUnsafeBytes(of: tokenId) { Data($0) }
        + tokenHash
    }
    
    public static func deserialize(data: Data) throws -> LocalKeypair {
        let rawPrivateKey = data.prefix(32)
        let serverPublicKey = data.subdata(in: 32..<64)
        let tokenId = data.subdata(in: 64..<68).withUnsafeBytes { pointer in
            pointer.load(as: UInt32.self)
        }
        let tokenHash = Data(data[68...])

        let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawPrivateKey)
        return LocalKeypair(
            privateKey: privateKey,
            serverPublicKey: serverPublicKey,
            tokenId: tokenId,
            tokenHash: tokenHash
        )
    }
}


