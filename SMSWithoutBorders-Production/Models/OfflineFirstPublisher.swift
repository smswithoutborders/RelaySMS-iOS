//
//  OfflineFirstPublisher.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import Foundation
import SwiftData

class OfflineFirstPublisher {
    enum OfflineFirstPublisherError: Error {
        case failedToGenerateKeypair
        case failedToGetStaticKey
        case failedToPublishOffline(status: any Error)
        case failedToEncrypt
    }
    
    func encrypt(
        plaintext: [UInt8],
        withAttachment: Bool,
    ) throws -> (Data, UInt8){
        do {
            
            let startRange = withAttachment ? 0 : 16
            let endRange = withAttachment ? 16 : 256
            let randomOffset = Int.random(in: startRange..<endRange)
            guard let staticKeys = try StaticKeys.getStaticKey(kid: randomOffset) else {
                throw OfflineFirstPublisherError.failedToGetStaticKey
            }
            guard let authenticationPublicKey = try staticKeys.getKey() else {
                throw OfflineFirstPublisherError.failedToGetStaticKey
            }

            let ecKeypair = generateNewKeypair()
            let scKeypair = generateNewKeypair()

            let offlineFirst = try OfflineFirst.encrypt(
                ssPk: authenticationPublicKey,
                ec: ecKeypair!.rawRepresentation,
                sc: scKeypair!.rawRepresentation,
                payload: Data(plaintext)
            )
            
            let payload = Data(try offlineFirst.serialize())
            return (payload, UInt8(randomOffset))
        } catch {
            throw OfflineFirstPublisherError.failedToPublishOffline(status: error)
        }
    }
    
    func publish(
        body: String,
        to: String?,
        subject: String?,
        into container: ModelContainer,
        transmissionCallback: (String) -> Void,
    ) throws -> V1ContentsContainer {
        do {
            return try TransportImpl.publishWithoutAttachment(
                catId: V1ContentCategories.email,
                body: body,
                to: to,
                subject: subject,
                encrypt: { plaintext in
                    do {
                        let (ciphertext, keyId) = try encrypt(
                            plaintext: plaintext,
                            withAttachment: false,
                        )
                        return (ciphertext, keyId, nil)
                    } catch {
                        print(error)
                        throw OfflineFirstPublisherError.failedToEncrypt
                    }
                },
                transmissionCallback: transmissionCallback
            )
        } catch {
            throw OfflineFirstPublisherError.failedToPublishOffline(status: error)
        }
    }
}
