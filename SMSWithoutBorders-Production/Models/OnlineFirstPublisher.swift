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
            guard let (localKeypair, authenticationPublicKey) = try Keystore.loadRandom(
                tokenId: tokenId,
                withAttachment: withAttachment,
                into: ModelContext(container)
            ) else {
                throw OnlineFirstPublisherError.failedToGenerateKeypair
            }

            let ciphertext = try v1PlatformPublisherEncrypt(
                ecKid: localKeypair.privateKey.rawRepresentation,
                ssKidPk: authenticationPublicKey,
                esKidPk: localKeypair.serverPublicKey,
                keyId: localKeypair.keyId,
                plaintext: plaintext
            )
            
            return (ciphertext, localKeypair.keyId, localKeypair.tokenId)
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
