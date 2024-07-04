//
//  gRPCHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 25/06/2024.
//

import Foundation
import GRPC

class GRPCHandler {
    
    static func getChannelVault() -> ClientConnection {
    #if DEBUG
        let host = NSLocalizedString("vault_url_debug", comment: "")
        let port = Int(NSLocalizedString("vault_port_debug", comment: ""))
    #else
        let host = NSLocalizedString("vault_url_production", comment: "")
        let port = Int(NSLocalizedString("vault_port_production", comment: ""))
    #endif
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host:host, port: port!)
    }
    
    static func getChannelPublisher() -> ClientConnection {
    #if DEBUG
        let host = NSLocalizedString("publisher_url_debug", comment: "")
        let port = Int(NSLocalizedString("publisher_port_debug", comment: ""))
    #else
        let host = NSLocalizedString("publisher_url_production", comment: "")
        let port = Int(NSLocalizedString("publisher_port_production", comment: ""))
    #endif
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host:host, port: port!)
    }
}
