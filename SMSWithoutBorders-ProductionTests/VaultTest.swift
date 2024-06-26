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
    var phoneNumber = "+2371234567891"
    var password = "dMd2Kmo9"
    var ownershipProof = "123456"
    
    var clientPublishPubKey = ""
    var clientDeviceIDPubKey = ""
    
    @Test func entityCreationTest() throws {
        do {
            let entityCreationResponse = try vault.createEntity(phoneNumber: phoneNumber)
            
            XCTAssertTrue(entityCreationResponse != nil)
            
            print("message says: \(entityCreationResponse?.message)")
            
            XCTAssertTrue(((entityCreationResponse?.requiresOwnershipProof) != nil))
        } catch {
            throw error
        }
        
    }
    
    @Test func entityCreation2Test() throws {
        let countryCode = "CM"
        
        let entityCreationResponse = try vault.createEntity2(
            phoneNumber: phoneNumber,
            countryCode: countryCode,
            password: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIdPubKey: clientDeviceIDPubKey,
            ownershipResponse: ownershipProof)
        print("message says: \(entityCreationResponse.message)")
        
        XCTAssertFalse(entityCreationResponse.requiresOwnershipProof)
    }
    
    
    @Test func authenticateEntity() throws {
        let authenticationResponse = try vault.authenticateEntity(
            phoneNumber: phoneNumber, password: password)
        
        try vault.authenticateEntity2(phoneNumber: phoneNumber,
                                      clientPublishPubKey: clientPublishPubKey,
                                      clientDeviceIDPubKey: clientDeviceIDPubKey)
    }
    
    @Test func listStoredEntityTokens() throws {
        let authenticationResponse = try vault.authenticateEntity(
            phoneNumber: phoneNumber, password: password)
        
        let llt = try vault.authenticateEntity2(phoneNumber: phoneNumber,
                                      clientPublishPubKey: clientPublishPubKey,
                                      clientDeviceIDPubKey: clientDeviceIDPubKey)
        
        let storedTokens = try vault.listStoredEntityToken(longLiveToken: llt)
    }
}
