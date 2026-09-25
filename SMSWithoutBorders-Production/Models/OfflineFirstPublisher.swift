//
//  OfflineFirstPublisher.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import Foundation

enum OfflineFirstPublisherError: Error {
    case failedToGenerateKeypair
    case failedToGetStaticKey
    case failedToPublishOffline(status: any Error)
}

class OfflineFirstPublisher {
    func encrypt(
        plaintext: [UInt8],
        withAttachment: Bool,
    ) throws -> (Data, Int){
        do {
            let keyId = withAttachment ? Int.random(in: 0...15) : Int.random(in: 16...255)
            let authenticationKey = StaticKeys.getStaticKey(kid: keyId)
            if(authenticationKey == nil) {
                throw OfflineFirstPublisherError.failedToGetStaticKey
            }
            
            let ecKeypair = try generateNewKeypair()
            if(ecKeypair == nil) {
                throw OfflineFirstPublisherError.failedToGenerateKeypair
            }
            
            let scKeypair = try generateNewKeypair()
            if(scKeypair == nil) {
                throw OfflineFirstPublisherError.failedToGenerateKeypair
            }

            let offlineFirst = try OfflineFirst.encrypt(
                ssPk: Data((authenticationKey?.keypair.bytes)!),
                ec: ecKeypair!.rawRepresentation,
                sc: scKeypair!.rawRepresentation,
                payload: Data(plaintext)
            )
            
            let payload = Data(try offlineFirst.serialize())
            return (payload, keyId)
        } catch {
            throw OfflineFirstPublisherError.failedToPublishOffline(status: error)
        }
    }
}
