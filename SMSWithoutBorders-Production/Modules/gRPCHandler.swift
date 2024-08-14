//
//  gRPCHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 25/06/2024.
//

import Foundation
import GRPC

class GRPCHandler {
    #if DEBUG
        private static var VAULT_GRPC = "staging.smswithoutborders.com"
        private static var VAULT_PORT = 9050

        private static var PUBLISHER_GRPC = "staging.smswithoutborders.com"
        private static var PUBLISHER_PORT = 9060
    #else
        private static var VAULT_GRPC = "vault.beta.smswithoutborders.com"
        private static var VAULT_PORT = 443
        
        private static var PUBLISHER_GRPC = "publisher.beta.smswithoutborders.com"
        private static var PUBLISHER_PORT = 443
    #endif
    
    static func getChannelVault() -> ClientConnection {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host: VAULT_GRPC, port: VAULT_PORT)
    }
    
    static func getChannelPublisher() -> ClientConnection {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host: VAULT_GRPC, port: VAULT_PORT)
    }
}
