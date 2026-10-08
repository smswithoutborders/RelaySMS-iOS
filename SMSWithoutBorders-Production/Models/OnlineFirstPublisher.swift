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
        case failedToPublishOffline(status: any Error)
        case failedToGetRandomKey
        case failedToEncrypt
        case failedToPublishOnline
    }
    
    public func encrypt(
        tokenId: UUID,
        plaintext: Data,
        withAttachment: Bool = false,
        into container: ModelContainer
    ) throws -> (Data, UInt8, UInt32)?{
        do {
            guard let (keypair, authenticationPublicKey, serverKeyId) = try Keystore.loadRandom(
                tokenId: tokenId,
                withAttachment: withAttachment,
                into: container
            ) else {
                throw OnlineFirstPublisherError.failedToGenerateKeypair
            }

            let ciphertext = try v1PlatformPublisherEncrypt(
                ecKid: keypair.privateKey.rawRepresentation,
                ssKidPk: authenticationPublicKey,
                esKidPk: keypair.serverPublicKey,
                keyId: UInt8(serverKeyId),
                plaintext: plaintext
            )
            
            return (ciphertext, UInt8(serverKeyId), keypair.tokenId)
        } catch {
            throw OnlineFirstPublisherError.failedToEncrypt
        }
    }
    
    func publish(
        catId: V1ContentCategories,
        body: String,
        platformName: String,
        tokenId: UUID,
        to: String?,
        subject: String?,
        into container: ModelContainer,
        transmissionCallback: (String) -> Void,
    ) throws -> V1ContentsContainer {
        do {
            return try TransportImpl.publishWithoutAttachment(
                catId: catId,
                body: body,
                to: to,
                subject: subject,
                encrypt: { plaintext in
                    guard let payload = try encrypt(
                        tokenId: tokenId,
                        plaintext: Data(plaintext),
                        withAttachment: false,
                        into: container
                    ) else {
                        throw OnlineFirstPublisherError.failedToEncrypt
                    }
                    return payload
                },
                transmissionCallback: transmissionCallback
            )
        } catch {
            throw OnlineFirstPublisherError.failedToPublishOnline
        }
    }
}
