//
//  Publisher.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 04/07/2024.
//

import Foundation
import GRPC
import Logging
import CoreData

class Publisher {
    public static var PUBLISHER_SHARED_KEY = "COM.AFKANERD.RELAYSMS.PUBLISHER_SHARED_KEY"
    public static var REDIRECT_URL_SCHEME = "relaysms://relaysms.com/ios/"

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
    
    func getRedirectUrl(platformName: String) -> String{
        return "https://oauth.afkanerd.com/platforms/\(platformName)/protocols/oauth2/redirect_codes/ios/"
    }
    
    func getURL(platform: String, 
                state: String = "",
                autogenerateCodeVerifier: Bool = true,
                supportsUrlSchemes: Bool = true) throws -> Publisher_V1_GetOAuth2AuthorizationUrlResponse {
        
        
        let publishingUrlRequest: Publisher_V1_GetOAuth2AuthorizationUrlRequest = .with {
            $0.platform = platform
            $0.state = ((platform + "," + (supportsUrlSchemes ? "true" : "false")).data(using: .utf8)?.base64EncodedString())!
            $0.redirectURL = supportsUrlSchemes ? Publisher.REDIRECT_URL_SCHEME : getRedirectUrl(platformName: platform)
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
    
    func sendAuthorizationCode(llt: String, 
                               platform: String,
                               code: String, 
                               codeVerifier: String? = nil,
                               supportsUrlSchemes: Bool = false) throws -> Publisher_V1_ExchangeOAuth2CodeAndStoreResponse {
        let authorizationRequest: Publisher_V1_ExchangeOAuth2CodeAndStoreRequest = .with {
            $0.platform = platform
            $0.authorizationCode = code
            $0.longLivedToken = llt
            if(codeVerifier != nil || !codeVerifier!.isEmpty) {
                $0.codeVerifier = codeVerifier!
            }
            $0.redirectURL = supportsUrlSchemes ? Publisher.REDIRECT_URL_SCHEME : getRedirectUrl(platformName: platform)
        }
        
        let call = publisherStub!.exchangeOAuth2CodeAndStore(authorizationRequest)
        let response: Publisher_V1_ExchangeOAuth2CodeAndStoreResponse
        
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
    
    func revokePlatform(llt: String, platform: String, account: String) throws -> Publisher_V1_RevokeAndDeleteOAuth2TokenResponse {
        let revokeRequest: Publisher_V1_RevokeAndDeleteOAuth2TokenRequest = .with {
            $0.platform = platform
            $0.longLivedToken = llt
            $0.accountIdentifier = account
        }
        
        let call = publisherStub!.revokeAndDeleteOAuth2Token(revokeRequest)
        let response: Publisher_V1_RevokeAndDeleteOAuth2TokenResponse
        
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
        let support_url_scheme: Bool
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
