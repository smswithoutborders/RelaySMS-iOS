//
//  CryptoTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 27/06/2024.
//

import XCTest
import CryptoKit
import CryptoSwift
import SwobDoubleRatchet

@testable import SMSWithoutBorders

struct CryptoTest {
    
//    @Test func curve25519Test() throws {
//        let keystoreAlias = "example-keystoreAlias"
//        CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAlias)
//        
//        let x = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAlias)
//        
//        let x1 = try SecurityCurve25519.getKeyPair(keystoreAlias: keystoreAlias)
//        
//        XCTAssertEqual(x.privateKey.rawRepresentation, x1?.rawRepresentation)
//    }
//    
//    @Test func testKeyDerivation() throws {
//        var clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey?
//        var clientPublishPubKey: String
//
//        CSecurity.deleteKeyFromKeychain(keystoreAlias: "example-keystore-publish")
//
//        do {
//            clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: "example-keystore-publish").privateKey
//            clientPublishPubKey = clientPublishPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
//            print(clientPublishPubKey)
//            
//            let peerpubkey = "Zn5MtyabPhNaBvJvDUIt41WezrzHKtdZnHV5R3lQxho="
//            let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(
//                rawRepresentation: peerpubkey.base64Decoded())
//            
//            let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
//                privateKey: clientPublishPrivateKey!, publicKey: peerPublishPublicKey).withUnsafeBytes {
//                    return Array($0)
//            }
//            print("SK:", Data(publishingSharedKey).base64EncodedString())
//            
//            let state = States()
//            try Ratchet.aliceInit(state: state,
//                              SK: publishingSharedKey,
//                              bobDhPubKey: peerPublishPublicKey, keystoreAlias: nil)
//            let (header, ciphertext) = try Ratchet.encrypt(state: state, data: "Hello world".bytes, AD: peerPublishPublicKey.rawRepresentation.bytes)
//            
//            var bytesHeaderLen = Data(count: 4)
//            bytesHeaderLen.withUnsafeMutableBytes {
//                $0.storeBytes(of: UInt32(header.serialize().count).littleEndian, as: UInt32.self)
//            }
//            var data = Data()
//            data.append(bytesHeaderLen)
//            data.append(header.serialize())
//            data.append(Data(ciphertext))
//            
//            print("Cipher text: " + Data(ciphertext).base64EncodedString() + "\n")
//            print("Header: " + header.serialize().base64EncodedString() + "\n")
//            print("Payload: " + data.base64EncodedString())
//            
//        } catch {
//            throw error
//        }
//    }
}
