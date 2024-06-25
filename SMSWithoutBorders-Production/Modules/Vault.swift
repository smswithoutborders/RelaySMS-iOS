//
//  Vault.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 24/06/2024.
//

import Foundation
import GRPC
import Logging


class VaultAuth {
    
    var channel: ClientConnection?
    var callOptions: CallOptions?

    init() {
        channel = GRPCHandler.getChannel()
        let logger = Logger(label: "gRPC", factory: StreamLogHandler.standardOutput(label:))
        callOptions = CallOptions.init(logger: logger)
    }
    
    func createEntity(phoneNumber: String, countryCode: String) throws -> Vault_V1_CreateEntityResponse{
        let vaultEntityStub = Vault_V1_EntityNIOClient.init(channel: channel!,
                                                            defaultCallOptions: callOptions!)
        var message = ""

        let entityCreationRequest: Vault_V1_CreateEntityRequest = .with {
            $0.phoneNumber = phoneNumber
        }
        
        let call = vaultEntityStub.createEntity(entityCreationRequest)
        return try call.response.wait()
    }
}
