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

struct HeadersInterceptor: ClientInterceptor {
    enum HeadersInterceptorError: Error {
        case failedToGetAuthenticationKey
        case failedToGenerateKeypair
        case failedToGetMethodName
        case failedToEncryptPayload
    }
    let onRequest: @Sendable () -> Data?
    var payload: Data?

    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (
            StreamingClientRequest<Input>,
            ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        let keyId = Int.random(in: 0..<256)
        
        guard let authenticationKey = try StaticKeys.getStaticKey(kid: keyId)?.getKey() else {
            throw HeadersInterceptorError.failedToGetAuthenticationKey
        }
        
        guard let keypair = generateNewKeypair() else {
            throw HeadersInterceptorError.failedToGenerateKeypair
        }
        
        guard let methodName = "/\(context.descriptor.fullyQualifiedMethod)".data(using: .utf8) else {
            throw HeadersInterceptorError.failedToGetMethodName
        }
        
        let cipherText = try v1RequestsEncrypt(
            ec: keypair.rawRepresentation,
            ssKidPk: authenticationKey,
            methodName: methodName,
            payload: payload,
            timestamp: nil
        )
        
        var request = request
        request.metadata.addBinary([UInt8](cipherText.ciphertext), forKey: "X-Payload-bin")
        request.metadata.addBinary([UInt8](keypair.publicKey.rawRepresentation), forKey: "X-Public-Key-bin")
        request.metadata.addString(String(keyId), forKey: "X-Key-ID")
        request.metadata.addBinary([UInt8](cipherText.nonce), forKey: "X-Nonce-bin")
        request.metadata.addString(String(cipherText.timestamp), forKey: "X-Timestamp")
        return try await next(request, context)
    }
}

final class GRPCService: Sendable {
    static let shared = try! GRPCService(host: GRPC_URL, port: GRPC_PORT)
    
    let client: GRPCClient<HTTP2ClientTransport.Posix>
    private let runTask: Task<Void, Error>

    init(host: String, port: Int) throws {
        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: host, port: port),
            transportSecurity: .tls
        )
        let client = GRPCClient(
            transport: transport,
            interceptors: [HeadersInterceptor(onRequest: { nil })]
        )
        self.client = client
        
        // Runs the connections until shutdown or cancellation.
        self.runTask = Task { try await client.runConnections() }
    }
    
    func shutdown() {
        client.beginGracefulShutdown() // lets in-flight RPCs finish
    }
    
    deinit { runTask.cancel() }
}
