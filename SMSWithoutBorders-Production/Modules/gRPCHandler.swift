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
        private static var host = NSLocalizedString("vault_url_debug", comment: "url for debugging")
    #else
        private static var host = NSLocalizedString("vault_url_production", comment: "url for production")
    #endif
    
    static func getChannel() -> ClientConnection {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host:host, port: 9050)
    }
}
