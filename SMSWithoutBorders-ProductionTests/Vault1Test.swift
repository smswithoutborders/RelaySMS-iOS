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

struct Vault1Test {
    

    @Test func entityCreationTest() throws {
        let phoneNumber = "+2371234567891"
        
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        let channel = ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host:"staging.smswithoutborders.com", port: 9050)
        
        let logger = Logger(label: "gRPC", factory: StreamLogHandler.standardOutput(label:))
        let callOptions = CallOptions.init(logger: logger)
        
        let vaultEntityStub = Vault_V1_EntityNIOClient.init(channel: channel, defaultCallOptions: callOptions)

        let entityCreationRequest: Vault_V1_CreateEntityRequest = .with {
            $0.phoneNumber = phoneNumber
        }
        
        let call = vaultEntityStub.createEntity(entityCreationRequest)
        let entityCreationResponse = try call.response.wait()
        
        XCTAssertTrue(entityCreationResponse.requiresOwnershipProof)
    }

}
