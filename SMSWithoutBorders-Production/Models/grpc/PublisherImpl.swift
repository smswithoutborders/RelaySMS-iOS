//
//  PublisherImpl.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import CryptoKit
import Foundation
import SwiftData

class PublisherImpl {
    enum PublisherImplError: Error {
        case failedToGenerateKeys
        case failedToGetAuthUrl(status: String)
        case failedToGenerateRequestIdentifier
        case failedToSendOAuthAuthorizationCode
        case invalidDecryptionKeyRequested(keyId: UInt32)
        case failedToFindStaticKeyForId(keyId: UInt32)
        case failedToDecryptClientToken
        case failedToDeserializeData
        case failedToSaveLocalKey(keyId: UInt32)
        case failedToFindServerPublicKey(keyId: UInt32)
        case failedToSaveLocalKeysToSwiftData
    }
    
    public static let REDIRECT_URL_SCHEME = "relaysms://relaysms.com/ios/"
    public static let REDIRECT_URL_URL = "https://relay.smswithoutborders.com/ios"
    public static var PUBLISHER_SERVER_PUBLIC_KEY = "COM.AFKANERD.PUBLISHER_SERVER_PUBLIC_KEY"
    
    public static var PUBLISHER_TOKEN_ID = "PUBLISHER_TOKEN_ID"
    public static var PUBLISHER_TOKEN_HASH = "PUBLISHER_TOKEN_HASH"
    public static var PUBLISHER_KEY_ID_PRIVATE_KEYS = "PUBLISHER_KEY_ID_PRIVATE_KEYS"

    let channel = GRPCHandler.getChannelPublisher()
    let publisherStub = Publisher_V3_Publisher(channel: channel)
    
    private func getBase64EncodedPublisherPublicKey() throws -> String {
        if let publisherPublicKeyBytes = UserDefaults.standard.object(
            forKey: PublisherImpl.PUBLISHER_SERVER_PUBLIC_KEY) as? [UInt8]
        {
            let data = Data(publisherPublicKeyBytes)
            let base64String = data.base64EncodedString()
            return base64String
        } else {
            throw PublisherImplError.failedToGenerateRequestIdentifier
        }
    }

    public func getAuthUrl(
        availablePlatform: SupportedPlatforms,
        requestIdentifier: String,
        autogenerateCodeVerifier: Bool = true,
        supportsUrlScheme: Bool = true,
    ) throws -> Publisher_V3_GetOAuth2AuthorizationUrlResponse {
        let scheme = supportsUrlScheme ? "true" : "false"
        
        let publishingUrlRequest:
            Publisher_V3_GetOAuth2AuthorizationUrlRequest = try .with {
                $0.platform = availablePlatform.name
                $0.state = (availablePlatform.name + "," + scheme)
                    .data(using: .utf8)!.base64EncodedString()
                $0.redirectURL = supportsUrlScheme ?
                PublisherImpl.REDIRECT_URL_SCHEME :
                PublisherImpl.REDIRECT_URL_URL
                $0.autogenerateCodeVerifier = autogenerateCodeVerifier
                $0.requestIdentifier = try getBase64EncodedPublisherPublicKey()
            }

        let call = publisherStub.getOAuth2AuthorizationUrl(publishingUrlRequest)
        let response: Publisher_V3_GetOAuth2AuthorizationUrlResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            if !status.isOk {
                throw PublisherImplError.failedToGetAuthUrl(
                    status: status.code.description)
            }
        } catch {
            throw error
        }

        return response
    }
    
    private func getKeys() throws -> (
        [Publisher_V3_PublicKey],
        [(Int, Curve25519.KeyAgreement.PrivateKey)]
    ){
        var keys = [(Int, Curve25519.KeyAgreement.PrivateKey)]()
        var publisherKeys = [Publisher_V3_PublicKey]()
        for i in 0...255 {
            guard let privateKey = generateNewKeypair() else {
                throw PublisherImplError.failedToGenerateKeys
            }
            let ppKey: Publisher_V3_PublicKey = .with {
                $0.keyID = UInt32(i)
                $0.publicKey = privateKey.publicKey.rawRepresentation
            }
            keys.append((i, privateKey))
            publisherKeys.append(ppKey)
        }
        
        return (publisherKeys, keys)
    }
    
    private class PublisherKeys {
        let keyId: UInt8
        let privateKey: Data
        
        init(keyId: UInt8, privateKey: Data) {
            self.keyId = keyId
            self.privateKey = privateKey
        }
        
        func serialize() -> Data {
            return [keyId] + privateKey
        }
        
        public static func deserialize(data: Data) throws -> PublisherKeys {
            guard let keyId: UInt8 = data.first else {
                throw PublisherImplError.failedToDeserializeData
            }
            return PublisherKeys(
                keyId: keyId,
                privateKey: data.dropFirst()
            )
        }
    }
    
    public static func getLocalKeysAccountTag(keyId: UInt8) -> String {
        return PublisherImpl.PUBLISHER_KEY_ID_PRIVATE_KEYS + "_" + String(keyId)
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
            tokenHash: Data
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
            let serverPublicKey = data.subdata(in: 32..<65)
            let tokenId = data.subdata(in: 65..<70).withUnsafeBytes { pointer in
                pointer.load(as: UInt32.self)
            }
            let tokenHash = data[70...]

            let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawPrivateKey)
            return LocalKeypair(
                privateKey: privateKey,
                serverPublicKey: serverPublicKey,
                tokenId: tokenId,
                tokenHash: tokenHash
            )
        }
    }
    
    
    private func storeKeys(
        keys: [(Int, Curve25519.KeyAgreement.PrivateKey)],
        serverEphemeralPublicKeys: [Publisher_V3_PublicKey],
        tokenId: UInt32,
        tokenHash: Data,
        catId: V1ContentCategories,
        accountId: String,
        platformName: String,
    ) throws {
        let container = try ModelContainer(for: LocalKeys.self)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        for keypair in keys {
            let (keyId, privateKey) = keypair
            let accountTag = PublisherImpl.getLocalKeysAccountTag(keyId: keyId)
            let serverPublicKey = serverEphemeralPublicKeys.first{ $0.keyID == keyId }
            
            if serverPublicKey == nil {
                throw PublisherImplError.failedToFindServerPublicKey(keyId: keyId)
            }
            
            let localKeypair = LocalKeypair(
                privateKey: privateKey,
                serverPublicKey: serverPublicKey!.publicKey,
                tokenId: tokenId,
                tokenHash: tokenHash
            ).serialize()
            
            if(!Keystore(accountTag: accountTag)
                .savePrivateKeyToKeychain(keyData: localKeypair)) {
                throw PublisherImplError.failedToSaveLocalKey(keyId: keyId)
            }
            
            let localKeys = LocalKeys(keyId: UInt32(keyId))
            context.insert(localKeys)
            
        }
        do {
            try context.save()
        } catch {
            throw PublisherImplError.failedToSaveLocalKeysToSwiftData
        }
    }
    
    private func processEphemeralKeys(
        keyId: UInt32,
        serverEphemeralPublicKeys: [Publisher_V3_PublicKey],
        keys: [(Int, Curve25519.KeyAgreement.PrivateKey)],
        tokenCipherText: Data,
        catId: V1ContentCategories,
        accountId: String,
        platformName: String,
        tokenId: UInt32,
    ) throws {
        let ecKid = keys.first { v in v.0 == keyId }?.1.rawRepresentation
        if ecKid == nil {
            throw PublisherImplError.invalidDecryptionKeyRequested(keyId: keyId)
        }
        
        let esKidPk = serverEphemeralPublicKeys.first { v in v.keyID == keyId }?.publicKey
        if esKidPk == nil {
            throw PublisherImplError.invalidDecryptionKeyRequested(keyId: keyId)
        }
        
        guard let ssKidPk = StaticKeys.getStaticKey(kid: keyId)?.getKey() else {
            throw PublisherImplError.failedToFindStaticKeyForId(keyId: keyId)
        }
        
        do {
            let tokenHash = try v1TokenDecryptClient(
                ecKid: ecKid!,
                ssKidPk: ssKidPk,
                esKidPk: esKidPk!,
                keyId: UInt8(keyId),
                receivedPayload: Data(tokenCipherText)
            )
            
            try storeKeys(
                keys: keys,
                serverEphemeralPublicKeys: serverEphemeralPublicKeys,
                tokenId: tokenId,
                tokenHash: tokenHash,
                catId: catId,
                accountId: accountId,
                platformName: platformName
            )
            
        } catch {
            throw PublisherImplError.failedToDecryptClientToken
        }
        
    }
    
    
    public func sendOAuthAuthorizationCode(
        platformName: String,
        code: String,
        codeVerifier: String,
        requestIdentifier: String,
    ) throws -> Publisher_V3_ExchangeOAuth2CodeAndStoreResponse {
        do {
            let (publisherKeys, keys) = try getKeys()
            
            let request: Publisher_V3_ExchangeOAuth2CodeAndStoreRequest = .with {
                $0.platform = platformName
                $0.authorizationCode = code
                $0.codeVerifier = codeVerifier
                $0.redirectURL = PublisherImpl.REDIRECT_URL_URL
                $0.requestIdentifier = requestIdentifier
                $0.clientEphemeralPublicKeys = publisherKeys
            }
            
            let call = publisherStub.exchangeOAuth2CodeAndStore(request: request)
            let response: Publisher_V3_ExchangeOAuth2CodeAndStoreResponse = try call.response.wait()
            let status = try call.status.wait()
            
            if !status.isOk {
                throw PublisherImplError.failedToSendOAuthAuthorizationCode
            }
            
            try processEphemeralKeys(
                keyId: response.keyID,
                serverEphemeralPublicKeys: response.serverEphemeralPublicKeys,
                keys: keys,
                tokenCipherText: response.tokenCiphertext,
                catId: v1ContentCategoryFromU8(value: UInt8(response.catID)),
                accountId: response.accountIdentifier,
                platformName: response.platform,
                tokenId: response.tokenID
            )
            
            return response
        } catch {
            throw error
        }
    }
    
}
