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

@testable import SMSWithoutBorders

struct VaultTest {
    var vault = Vault()
    var phoneNumber = "+2371234567892"
    var password = "dMd2Kmo9"
    var ownershipProof = "123456"
    
    var clientPublishPubKey = ""
    var clientDeviceIDPubKey = ""
    
    
    @Test func endToEndTest() throws {
        var entityCreationResponse = try vault.createEntity(phoneNumber: phoneNumber)
        XCTAssertTrue(entityCreationResponse.requiresOwnershipProof)
        
        let countryCode = "CM"
        
        entityCreationResponse = try vault.createEntity2(
            phoneNumber: phoneNumber,
            countryCode: countryCode,
            password: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIdPubKey: clientDeviceIDPubKey,
            ownershipResponse: ownershipProof)
        print("message says: \(entityCreationResponse.message)")
        
        XCTAssertFalse(entityCreationResponse.requiresOwnershipProof)
        
        try vault.authenticateEntity(phoneNumber: phoneNumber, password: password)

        var response = try vault.authenticateEntity2(phoneNumber: phoneNumber,
                                      clientPublishPubKey: clientPublishPubKey,
                                      clientDeviceIDPubKey: clientDeviceIDPubKey,
                                      ownershipResponse: ownershipProof)
        
        let authenticationResponse = try vault.authenticateEntity(
            phoneNumber: phoneNumber, password: password)
        
        let response1 = try vault.listStoredEntityToken(
            longLiveToken: response.longLivedToken)
        
        XCTAssertEqual(response1.storedTokens, [])
    }
}
