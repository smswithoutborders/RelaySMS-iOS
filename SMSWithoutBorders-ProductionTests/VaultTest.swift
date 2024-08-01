//
//  Vault1Test.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 25/06/2024.
//

import Testing
import GRPC
import NIO
import XCTest
import Logging
import CryptoKit
import Fernet
import SwobDoubleRatchet

@testable import SMSWithoutBorders

struct VaultTest {
    var vault = Vault()
    var password = "LL<O3ZG~=z-epkv"
    var phoneNumber = "+237123456"
    var ownershipProof = "123456"
    var keystoreAliasPublishPubKey = "vault-test-keystoreAlias-pub-key"
    var keystoreAliasDeviceIDPubKey = "vault-test-keystoreAlias-device-id-key"
    
    @Test func loginTest() throws {
        var clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey?
        var clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey?

        var clientPublishPubKey: String
        var clientDeviceIDPubKey: String
        
        CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAliasPublishPubKey)
        CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAliasDeviceIDPubKey)

        do {
            clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasDeviceIDPubKey).privateKey
            clientDeviceIDPubKey = clientDeviceIDPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
            
            clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasPublishPubKey).privateKey
            clientPublishPubKey = clientPublishPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
        } catch {
            throw error
        }
        print("PK: \(clientDeviceIDPubKey)")
        
        do {
            var response = try vault.authenticateEntity(phoneNumber: phoneNumber,
                                                        password: password,
                                          clientPublishPubKey: clientPublishPubKey,
                                          clientDeviceIDPubKey: clientDeviceIDPubKey)
            
            XCTAssertFalse(response.requiresOwnershipProof)

            response = try vault.authenticateEntity(phoneNumber: phoneNumber,
                                                        password: password,
                                          clientPublishPubKey: clientPublishPubKey,
                                          clientDeviceIDPubKey: clientDeviceIDPubKey,
                                          ownershipResponse: ownershipProof)
            
            let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: response.serverDeviceIDPubKey.base64Decoded())
            
            let sharedKey = try SecurityCurve25519.calculateSharedSecret(
                privateKey: clientDeviceIDPrivateKey!, publicKey: peerPublicKey).withUnsafeBytes {
                    return Data(Array($0))
                }
            
            let fernetToken = try Fernet(key: Data(sharedKey))
            let decodedOutput = try fernetToken.decode(Data(base64Encoded: response.longLivedToken)!)
            XCTAssertTrue(decodedOutput.hmacSuccess)
            
            let llt = String(data: decodedOutput.data, encoding: .utf8)

            let response1 = try vault.listStoredEntityToken(longLiveToken: llt!)
            
            print("stored tokens: \(response1.storedTokens)")
            
            for storedToken in response1.storedTokens {
                print("Platform: \(storedToken.platform)")
                print("Account identifier: \(storedToken.accountIdentifier)")
            }
            
            let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(
                rawRepresentation: response.serverPublishPubKey.base64Decoded())
            
            let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
                privateKey: clientPublishPrivateKey!, publicKey: peerPublishPublicKey).withUnsafeBytes {
                    return Data(Array($0))
                }
            
            XCTAssertTrue(CSecurity.deletePasswordFromKeychain(keystoreAlias: "example_long_lived_token"))
            XCTAssertTrue(CSecurity.deletePasswordFromKeychain(keystoreAlias: "example_publishing_shared_key"))
            
            // TODO: Encrypt all the data being stored securely on the device
            try CSecurity.storeInKeyChain(data: llt!.data(using: .utf8)!, keystoreAlias: "example_long_lived_token")
            try CSecurity.storeInKeyChain(data: publishingSharedKey, keystoreAlias: "example_publishing_shared_key")
            
            let rllt = try CSecurity.findInKeyChain(keystoreAlias: "example_long_lived_token")
            let rPubSharedKey = try CSecurity.findInKeyChain(keystoreAlias: "example_publishing_shared_key")
            
            XCTAssertNotNil(rllt)
            XCTAssertNotNil(rPubSharedKey)
            
            print("rltt: \(String(data: rllt, encoding: .utf8))")
            print("sharedKey: \(rPubSharedKey.base64EncodedString())")

            XCTAssertEqual(String(data: rllt, encoding: .utf8), llt)
            XCTAssertEqual(rPubSharedKey, publishingSharedKey)

        } catch {
            print(error)
            throw error
        }
    }

    
    @Test func endToEndTest() throws {
        var clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey?
        var clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey?

        var clientPublishPubKey: String
        var clientDeviceIDPubKey: String
        
        CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAliasPublishPubKey)
        CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAliasDeviceIDPubKey)

        do {
            clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasDeviceIDPubKey).privateKey
            clientDeviceIDPubKey = clientDeviceIDPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
            
            clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasPublishPubKey).privateKey
            clientPublishPubKey = clientPublishPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
        } catch {
            throw error
        }
        print("PK: \(clientDeviceIDPubKey)")

        let countryCode = "CM"
        
        do {
            var entityCreationResponse = try vault.createEntity(
                phoneNumber: phoneNumber,
                countryCode: countryCode,
                password: password,
                clientPublishPubKey: clientPublishPubKey,
                clientDeviceIdPubKey: clientDeviceIDPubKey)
            
            entityCreationResponse = try vault.createEntity(
                phoneNumber: phoneNumber,
                countryCode: countryCode,
                password: password,
                clientPublishPubKey: clientPublishPubKey,
                clientDeviceIdPubKey: clientDeviceIDPubKey,
                ownershipResponse: ownershipProof)
            print("message says: \(entityCreationResponse.message)")
            
            XCTAssertTrue(entityCreationResponse.requiresOwnershipProof)
            
            XCTAssertFalse(entityCreationResponse.requiresOwnershipProof)
        } catch Vault.Exceptions.requestNotOK(let status){
            print("Error came back - message: \(status.message)")
            print("Error came back - cause: \(status.cause)")
            print("Error came back - description: \(status.cause)")
            print("Error came back - code: \(status.code)")
//            var (field, message) = Vault.parseErrorMessage(message: status.message)!
//            print("Field: \(field)")
//            print("Message: \(message)")
            if status.code.rawValue != 6 {
                throw status
            }
        }
        
        
        do {
            var response = try vault.authenticateEntity(phoneNumber: phoneNumber,
                                                        password: password,
                                          clientPublishPubKey: clientPublishPubKey,
                                          clientDeviceIDPubKey: clientDeviceIDPubKey)
            
            XCTAssertFalse(response.requiresOwnershipProof)

            // ** LOGIN **
            response = try vault.authenticateEntity(phoneNumber: phoneNumber,
                                                        password: password,
                                          clientPublishPubKey: clientPublishPubKey,
                                          clientDeviceIDPubKey: clientDeviceIDPubKey,
                                          ownershipResponse: ownershipProof)
            
            let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: response.serverDeviceIDPubKey.base64Decoded())
            
            let sharedKey = try SecurityCurve25519.calculateSharedSecret(
                privateKey: clientDeviceIDPrivateKey!, publicKey: peerPublicKey).withUnsafeBytes {
                    return Data(Array($0))
                }
            
            let fernetToken = try Fernet(key: Data(sharedKey))
            let decodedOutput = try fernetToken.decode(Data(base64Encoded: response.longLivedToken)!)
            XCTAssertTrue(decodedOutput.hmacSuccess)
            
            let llt = String(data: decodedOutput.data, encoding: .utf8)

            // ** LIST STORED TOKENS **
            let response1 = try vault.listStoredEntityToken(longLiveToken: llt!)
            
            print("stored tokens: \(response1.storedTokens)")
            
            let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(
                rawRepresentation: response.serverPublishPubKey.base64Decoded())
            
            let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
                privateKey: clientPublishPrivateKey!, publicKey: peerPublishPublicKey).withUnsafeBytes {
                    return Data(Array($0))
                }
            
            XCTAssertTrue(CSecurity.deletePasswordFromKeychain(keystoreAlias: "example_long_lived_token"))
            XCTAssertTrue(CSecurity.deletePasswordFromKeychain(keystoreAlias: "example_publishing_shared_key"))
            
            try CSecurity.storeInKeyChain(data: llt!.data(using: .utf8)!, keystoreAlias: "example_long_lived_token")
            try CSecurity.storeInKeyChain(data: publishingSharedKey, keystoreAlias: "example_publishing_shared_key")
            
            let rllt = try CSecurity.findInKeyChain(keystoreAlias: "example_long_lived_token")
            let rPubSharedKey = try CSecurity.findInKeyChain(keystoreAlias: "example_publishing_shared_key")
            
            XCTAssertNotNil(rllt)
            XCTAssertNotNil(rPubSharedKey)
            
            print("rltt: \(String(data: rllt, encoding: .utf8))")
            print("sharedKey: \(rPubSharedKey.base64EncodedString())")

            XCTAssertEqual(String(data: rllt, encoding: .utf8), llt)
            XCTAssertEqual(rPubSharedKey, publishingSharedKey)
            
            // ** REVOKE STORED TOKENS **
            let publisher = Publisher()
            for platform in response1.storedTokens {
                print("Revoking: \(platform.platform): \(platform.accountIdentifier)")
                let response = try publisher.revokePlatform(llt: llt!,
                                         platform: platform.platform,
                                         account: platform.accountIdentifier)
                
                XCTAssertTrue(response.success)
            }
            
            // ** DELETE STORED TOKENS **
            let deleteResponse = try vault.deleteEntity(longLiveToken: llt!)
            print("Deleted tokens...")
            
            XCTAssertTrue(deleteResponse.success)
            
        } catch {
            print(error)
            throw error
        }
    }
}
