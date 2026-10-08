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
        case failedToSaveLocalKey(keyId: Int)
        case failedToFindServerPublicKey(keyId: Int)
        case failedToSaveLocalKeysToSwiftData
        case failedToInitializeContextCOntainer
    }
    
    let publisherStub = Publisher_V3_Publisher.Client(wrapping: GRPCService.shared.client)
    
    var container: ModelContainer
    init(container: ModelContainer) {
        self.container = container
    }

    public func getAuthUrl(
        availablePlatform: SupportedPlatforms,
        requestIdentifier: String,
        autogenerateCodeVerifier: Bool = true,
        supportsUrlScheme: Bool = false,
    ) async throws -> Publisher_V3_GetOAuth2AuthorizationUrlResponse {
        let scheme = supportsUrlScheme ? "true" : "false"
        
        let reply = try await publisherStub.getOAuth2AuthorizationUrl(.with {
            $0.platform = availablePlatform.name
            $0.state = (availablePlatform.name + "," + scheme)
                .data(using: .utf8)!.base64EncodedString()
            $0.redirectURL = StaticVariables.Publisher.getRedirectUrl()
            $0.autogenerateCodeVerifier = autogenerateCodeVerifier
            $0.requestIdentifier = requestIdentifier
        })
        return reply
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
    
    private func storeKeys(
        keys: [(Int, Curve25519.KeyAgreement.PrivateKey)],
        serverEphemeralPublicKeys: [Publisher_V3_PublicKey],
        tokenId: UInt32,
        tokenHash: Data,
        catId: V1ContentCategories,
        accountId: String,
        platformName: String,
    ) throws {
        let context = ModelContext(self.container)
        context.autosaveEnabled = false
        
        let token = Tokens(
            catId: Int(catId.rawValue),
            account: accountId,
            platformName: platformName
        )
        context.insert(token)
        print("Token stored: \(token.id)")
        
        for keypair in keys {
            let (keyId, privateKey) = keypair
            let accountTag = Keystore.getLocalKeysAccountTag(
                keyId: UInt8(keyId),
                tokenId: token.id,
            )
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
            

            let localKeys = LocalKeys(
                keyId: keyId,
                tokenId: token.id
            )
            context.insert(localKeys)
        }
        print("Local keys stored: \(keys.count)")

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
        
        guard let ssKidPk = try StaticKeys.getStaticKey(kid: Int(keyId))?.getKey() else {
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
    ) async throws -> Publisher_V3_ExchangeOAuth2CodeAndStoreResponse {
        do {
            let (publisherKeys, keys) = try getKeys()
            
            let response = try await publisherStub.exchangeOAuth2CodeAndStore(.with {
                $0.platform = platformName
                $0.authorizationCode = code
                $0.codeVerifier = codeVerifier
                $0.redirectURL = StaticVariables.Publisher.getRedirectUrl()
                $0.requestIdentifier = requestIdentifier
                $0.clientEphemeralPublicKeys = publisherKeys
            })
            
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
