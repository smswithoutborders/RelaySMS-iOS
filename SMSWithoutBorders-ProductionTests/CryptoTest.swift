//
//  CryptoTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 27/06/2024.
//

import Testing
import XCTest

@testable import SMSWithoutBorders

struct CryptoTest {

    @Test func curve25519Test() throws {
        let keystoreAlias = "example-keystoreAlias"
        let x = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAlias)
        
        let x1 = try SecurityCurve25519.getKeyPair(keystoreAlias: keystoreAlias)
        
        XCTAssertEqual(x.publicKey.rawRepresentation, x1?.publicKey.rawRepresentation)
    }

}
