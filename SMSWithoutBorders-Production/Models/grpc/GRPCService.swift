//
//  gRPCHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 25/06/2024.
//

import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2

#if DEBUG
    let GRPC_URL = "publisher.relaysms.afkanerd.de"
    let GRPC_PORT = 443
#else
    let GRPC_URL = "relaysms.smswithoutborders.afkanerd.com"
    let GRPC_PORT = 443
#endif

final class GRPCService: Sendable {
    static let shared = try! GRPCService(host: GRPC_URL, port: GRPC_PORT)
    
    let client: GRPCClient<HTTP2ClientTransport.Posix>
    private let runTask: Task<Void, Error>

    init(host: String, port: Int) throws {
        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: host, port: port),
            transportSecurity: .tls
        )
        let client = GRPCClient(transport: transport)
        self.client = client

        // Runs the connections until shutdown or cancellation.
        self.runTask = Task { try await client.runConnections() }
    }
    
    func shutdown() {
        client.beginGracefulShutdown() // lets in-flight RPCs finish
    }

    deinit { runTask.cancel() }
}
