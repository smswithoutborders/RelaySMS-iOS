//
//  VaultTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 25/06/2024.
//

//import Foundation
import GRPC
import NIO
import XCTest

@testable import SMSWithoutBorders

class VaultTest: XCTestCase {
    
    var eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var phoneNumber = "+2371234567891"
    
    var channel: GRPCChannel?
    override func setUpWithError() throws {
        channel = try GRPCChannelPool.with(
            target: .host("staging.smswithoutborders.com", port: 9050),
            transportSecurity: .plaintext,
            eventLoopGroup: eventLoopGroup)
    }


    func createEntityTest() throws {
        let vaultEntityStub = Vault_V1_EntityNIOClient(channel: channel!)

        let entityCreationRequest: Vault_V1_CreateEntityRequest = .with {
            $0.phoneNumber = phoneNumber
        }
        
        let call = vaultEntityStub.createEntity(entityCreationRequest)
        let entityCreationResponse = try call.response.wait()
        
        XCTAssertTrue(entityCreationResponse.requiresOwnershipProof)
    }

}
