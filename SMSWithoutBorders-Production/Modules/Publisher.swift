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
import CryptoKit

class Publisher {
    public static var PUBLISHER_SHARED_KEY = "COM.AFKANERD.RELAYSMS.PUBLISHER_SHARED_KEY"
    public static var REDIRECT_URL_SCHEME = "relaysms://relaysms.com/ios/"
    public static var PUBLISHER_SERVER_PUBLIC_KEY = "COM.AFKANERD.PUBLISHER_SERVER_PUBLIC_KEY"
    public static var PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS = "COM.AFKANERD.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS"

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
    
    func getOAuthURL(platform: String,
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
    
    func sendOAuthAuthorizationCode(llt: String,
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
    
    private func revokeOAuthPlatform(llt: String, platform: String, account: String) throws -> Publisher_V1_RevokeAndDeleteOAuth2TokenResponse{
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
    
    private func revokePNBAPlatform(llt: String, platform: String, account: String) throws -> Publisher_V1_RevokeAndDeletePNBATokenResponse {
        let pnbaRevokeRequest: Publisher_V1_RevokeAndDeletePNBATokenRequest = .with {
            $0.longLivedToken = llt
            $0.platform = platform
            $0.accountIdentifier = account
        }
            
        let call = publisherStub!.revokeAndDeletePNBAToken(pnbaRevokeRequest)
        let response: Publisher_V1_RevokeAndDeletePNBATokenResponse
        
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

    func revokePlatform(llt: String, platform: String, account: String, protocolType: String) throws -> Bool {
        if protocolType ==  "oauth2" {
            return try revokeOAuthPlatform(llt: llt, platform: platform, account: account).success
        }
        else if protocolType == "pnba" {
            return try revokePNBAPlatform(llt: llt, platform: platform, account: account).success
        }
        return false
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
    
    public func phoneNumberBaseAuthenticationRequest(phoneNumber: String, platform: String) throws -> Publisher_V1_GetPNBACodeResponse {
        let pnbaRequest: Publisher_V1_GetPNBACodeRequest = .with {
            $0.phoneNumber = phoneNumber
            $0.platform = platform
        }
        
        let call = publisherStub!.getPNBACode(pnbaRequest)
        let response: Publisher_V1_GetPNBACodeResponse
        
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
    
    public func phoneNumberBaseAuthenticationExchange( authorizationCode: String,
                                                       llt: String, phoneNumber: String, platform: String) throws -> Publisher_V1_ExchangePNBACodeAndStoreResponse {
        let pnbaExchangeRequest: Publisher_V1_ExchangePNBACodeAndStoreRequest = .with {
            $0.authorizationCode = authorizationCode
            $0.longLivedToken = llt
            $0.password = ""
            $0.phoneNumber = phoneNumber
            $0.platform = platform
        }
            
        let call = publisherStub!.exchangePNBACodeAndStore(pnbaExchangeRequest)
        let response: Publisher_V1_ExchangePNBACodeAndStoreResponse
        
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
    
    public static func publish(platform: PlatformsEntity, context: NSManagedObjectContext) throws -> MessageComposer {
        do {
            let AD: [UInt8] = UserDefaults.standard.object(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as! [UInt8]
            let deviceID: [UInt8] = UserDefaults.standard.object(forKey: Vault.VAULT_DEVICE_ID) as! [UInt8]
            let peerPubkey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: AD)
            let pubSharedKey = try CSecurity.findInKeyChain(keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
            let usePhonenumber = UserDefaults.standard.bool(forKey: SecuritySettingsView.SETTINGS_MESSAGE_WITH_PHONENUMBER)
            print("use phone number for publishing: \(!usePhonenumber)")
            
            let messageComposer = try MessageComposer(
                SK: pubSharedKey.bytes,
                AD: AD,
                peerDhPubKey: peerPubkey,
                keystoreAlias: Publisher.PUBLISHER_SHARED_KEY,
                deviceID: deviceID,
                context: context,
                useDeviceID: !usePhonenumber)
            
            return messageComposer
        } catch {
            throw error
        }
    }
}
