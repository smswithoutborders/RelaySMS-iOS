//
//  OnlineFirstPublisher.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import Foundation
import SwiftData

class OnlineFirstPublisher {
    enum OnlineFirstPublisherError: Error {
        case failedToGenerateKeypair
        case failedToGetStaticKey
        case failedToPublishOffline(status: any Error)
        case failedToGetRandomKey
        case failedToFetchLocalKey
        case failedToFetchPrivateKeyDataForKeyId(keyId: Int)
        case failedToEncrypt
        case failedToPublishOnline
    }
    
    public func encrypt(
        tokenId: Int,
        plaintext: Data,
        withAttachment: Bool = false
    ) throws -> (Data, UInt8)?{
        let container = try ModelContainer(for: LocalKeys.self)
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
                throw OnlineFirstPublisherError.failedToFetchLocalKey
            }
            
            let serverKeyId = serverKeys.keyId
            let forKeyId = #Predicate<LocalKeys> { keys in
                keys.keyId == serverKeyId
            }
            
            let descriptor = FetchDescriptor<LocalKeys>( predicate: forKeyId )
            guard let localKey = try context.fetch(descriptor).first else {
                throw OnlineFirstPublisherError.failedToFetchLocalKey
            }
            
            guard let staticKeys = try StaticKeys.getStaticKey(kid: Int(localKey.keyId)) else {
                throw OnlineFirstPublisherError.failedToGetStaticKey
            }
            guard let authenticationPublicKey = try staticKeys.getKey() else {
                throw OnlineFirstPublisherError.failedToGetStaticKey
            }
            
            let accountTag = PublisherImpl.getLocalKeysAccountTag(keyId: UInt8(serverKeyId))
            let keystore = Keystore(accountTag: accountTag)
            guard let rawKeyData = keystore.loadPrivateKeyFromKeychain() else {
                throw OnlineFirstPublisherError
                    .failedToFetchPrivateKeyDataForKeyId(keyId: serverKeyId)
            }
            let keypair = try PublisherImpl.LocalKeypair.deserialize(data: rawKeyData)


            let ciphertext = try v1PlatformPublisherEncrypt(
                ecKid: keypair.privateKey.rawRepresentation,
                ssKidPk: authenticationPublicKey,
                esKidPk: keypair.serverPublicKey,
                keyId: UInt8(serverKeyId),
                plaintext: plaintext
            )
            
            return (ciphertext, UInt8(serverKeyId))
        } catch {
            throw OnlineFirstPublisherError.failedToEncrypt
        }
    }
    
    func publish(
        catId: V1ContentCategories,
        body: String,
        platformName: String,
        tokenId: Int,
        to: String?,
        subject: String?,
    ) throws -> V1ContentsContainer {
        do {
            return try TransportImpl.publishWithoutAttachment(
                catId: catId,
                tokenId: UInt32(tokenId),
                body: body,
                to: to,
                subject: subject,
                encrypt: { plaintext in
                    guard let payload = try encrypt(
                        tokenId: tokenId,
                        plaintext: Data(plaintext),
                        withAttachment: false
                    ) else {
                        throw OnlineFirstPublisherError.failedToEncrypt
                    }
                    return payload
                },
                transmissionCallback: { serializePayload in
                    
                }
            )
        } catch {
            throw OnlineFirstPublisherError.failedToPublishOnline
        }
    }
}
