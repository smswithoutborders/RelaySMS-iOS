//
//  CryptoTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 27/06/2024.
//

import Testing
import XCTest
import CryptoKit
import CryptoSwift
import SwobDoubleRatchet

@testable import SMSWithoutBorders

struct CryptoTest {
    
    @Test func curve25519Test() throws {
        let keystoreAlias = "example-keystoreAlias"
        CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAlias)
        
        let x = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAlias)
        
        let x1 = try SecurityCurve25519.getKeyPair(keystoreAlias: keystoreAlias)
        
        XCTAssertEqual(x.privateKey.rawRepresentation, x1?.rawRepresentation)
    }
    
    //    @Test func curve25519ManualTest() throws {
    //        let keystoreAlias = "example-keystoreAlias"
    //        let peerPublicKeyEncoded = try "w5o0/rPpfxyBqgVPAwb3OufetAt7qoKBsnqLwC2PsR0=".base64Decoded()
    //        CSecurity.deleteFromKeyChain(keystoreAlias: keystoreAlias)
    //
    //        let x = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAlias)
    //        print("PK: \(x.publicKey.rawRepresentation.base64EncodedString())")
    //
    //        let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKeyEncoded)
    //        let sharedKey = try SecurityCurve25519.calculateSharedSecret(
    //            privateKey: x, publicKey: peerPublicKey).withUnsafeBytes {
    //                return Data(Array($0)).base64URLEncodedString()
    //            }
    //        print("DK: \(sharedKey)")
    //    }
    
    func KDF_RK(rk: [UInt8], dh: [UInt8]) throws -> (rk: [UInt8], ck: [UInt8]) {
        let info = "KDF_RK"
        
        return try HKDF(
            password: rk,
            salt: dh,
            info: info.bytes,
            keyLength: 32*2, variant: .sha2(.sha512))
            .calculate().withUnsafeBytes {
                return (Array(Array($0)[0..<32]), Array(Array($0)[32..<64]))
            }
    }
    
    @Test func testKeyDerivation() throws {
        print(try KDF_RK(rk: "Hello world".bytes, dh: "Hello world".bytes))
    }
}
