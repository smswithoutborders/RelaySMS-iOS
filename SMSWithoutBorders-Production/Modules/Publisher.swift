//
//  Publisher.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 04/07/2024.
//

import Foundation
import GRPC
import Logging

class Publisher {
    enum Exceptions: Error {
        case requestNotOK(status: GRPCStatus)
    }
    
    var channel: ClientConnection?
    var callOptions: CallOptions?
    var publisherStub: Publisher_V1_PublisherNIOClient?

    init() {
        channel = GRPCHandler.getChannelPublisher()
        let logger = Logger(label: "gRPC", factory: StreamLogHandler.standardOutput(label:))
        callOptions = CallOptions.init(logger: logger)
        publisherStub = Publisher_V1_PublisherNIOClient.init(channel: channel!,
                                                            defaultCallOptions: callOptions!)
    }
    
    func getURL(platform: String, 
                state: String = "",
                codeVerifier: String = "",
                autogenerateCodeVerifier: Bool = true) throws -> Publisher_V1_GetOAuth2AuthorizationUrlResponse {
        
        let publishingUrlRequest: Publisher_V1_GetOAuth2AuthorizationUrlRequest = .with {
            $0.platform = platform
            $0.state = state
            $0.codeVerifier = codeVerifier
            $0.autogenerateCodeVerifier = autogenerateCodeVerifier
        }
        
        let call = publisherStub!.getOAuth2AuthorizationUrl(publishingUrlRequest)
        let response: Publisher_V1_GetOAuth2AuthorizationUrlResponse
        
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("status code - raw value: \(status.code.rawValue)")
            print("status code - description: \(status.code.description)")
            print("status code - isOk: \(status.isOk)")
            
            if(!status.isOk) {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("Some error came back: \(error)")
            throw error
        }

        return response
    }
    
    public struct PlatformsData: Codable {
        let name: String
        let shortcode: String
        let service_type: String
        let protocol_type: String
        let icon_svg: String
        let icon_png: String
    }
    
    static func getPlatforms(completion: @escaping (Result<[PlatformsData], Error>) -> Void) {
        let platformsUrl = "https://raw.githubusercontent.com/smswithoutborders/SMSWithoutBorders-Publisher/staging/resources/platforms.json"
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: URL(string: platformsUrl)!)
                let decodedData = try JSONDecoder().decode([PlatformsData].self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}
