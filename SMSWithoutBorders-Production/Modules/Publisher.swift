//
//  Publisher.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 04/07/2024.
//

import CoreData
import CryptoKit
import Foundation
import GRPC
import Logging
import SwiftUI

class Publisher {
    public static var PUBLISHER_SHARED_KEY = "COM.AFKANERD.RELAYSMS.PUBLISHER_SHARED_KEY"
    public static var REDIRECT_URL_SCHEME = "relaysms://relaysms.com/ios/"
    public static var PUBLISHER_SERVER_PUBLIC_KEY = "COM.AFKANERD.PUBLISHER_SERVER_PUBLIC_KEY"
    public static var PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS = "COM.AFKANERD.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS"
    public static var CLIENT_PUBLIC_KEY_KEYSTOREALIAS = "COM.AFKANERD.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS"

    public static var PLATFORM_CODE_VERIFIER = "PLATFORM_CODE_VERIFIER"

    public enum ServiceTypeDescriptions: String.LocalizationValue {
        case EMAIL = "Adding emails to your RelaySMS account enables you use them to send emails using SMS messaging.\n\nGmail are currently supported."
        case MESSAGE = "Adding numbers to your RelaySMS account enables you use them to send messages using SMS messaging.\n\nTelegram messaging is currently supported."
        case TEXT = "Adding accounts to your RelaySMS account enables you use them to make post using SMS messaging.\n\nPosting is currently supported."
        case BRIDGE = "Your RelaySMS account is an alias of your phone number with the domain @relaysms.me.\n\nYou can receive replies by SMS whenever a message is sent to your alias."

        func localizedValue() -> String {
            return String(localized: self.rawValue)
        }
    }

    public enum ServiceComposeTypeDescriptions: String.LocalizationValue {
        case EMAIL = "Continue to send an email from your saved email account. You can choose a message forwarding country from the 'Countries' tab below.\n\nContinue to send message"
        case MESSAGE = "Continue to send messages from your saved messaging account. You can choose a message forwarding country from the 'Countries' tab below.\n\nContinue to send message"
        case TEXT = "Continue to make posts from your saved messaging account. You can choose a message forwarding country from the 'Countries' tab below.\n\nContinue to send message"
        case BRIDGE = "Your RelaySMS account is an alias of your phone number with the domain @relaysms.me.\n\nYou can receive replies by SMS whenever a message is sent to your alias.\nYou can choose a message forwarding country from the 'Countries' tab below.\n\nContinue to send message"
        func localizedValue() -> String {
            return String(localized: self.rawValue)
        }
    }

    public enum ProtocolTypes: String {
        case OAUTH2 = "oauth2"
        case PNBA = "pnba"
        case BRIDGE = "bridge"
    }

    public enum ServiceTypes: String {
        case EMAIL = "email"
        case MESSAGE = "message"
        case TEXT = "text"
        case BRIDGE = "bridge"
    }

    public enum Exceptions: Error {
        case requestNotOK(status: GRPCStatus)
    }

    var channel: ClientConnection?
    var callOptions: CallOptions?
    var publisherStub: Publisher_V1_PublisherNIOClient?

    init() {
        channel = GRPCHandler.getChannelPublisher()
        let logger = Logger(
            label: "gRPC", factory: StreamLogHandler.standardOutput(label:))
        callOptions = CallOptions.init(logger: logger)
        publisherStub = Publisher_V1_PublisherNIOClient.init(
            channel: channel!,
            defaultCallOptions: callOptions!)
    }

    private func getBase64EncodedPublisherPublicKey() -> String {
        if let publisherPublicKeyBytes = UserDefaults.standard.object(
            forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as? [UInt8]
        {
            let data = Data(publisherPublicKeyBytes)
            let base64String = data.base64EncodedString()
            print("[Publisher]: Base64 ecoded Publisher Public Key: \(base64String)")
            return base64String
        } else {
            print("[Publisher]: No public key found or wrong type")
            return ""
            //throw NSError(domain: "Publisher", code: -1, userInfo: [NSLocalizedDescriptionKey : "No public key found or wrong type"])
        }
    }

    func getRedirectUrl(platformName: String) -> String {
        return "https://oauth.afkanerd.com/platforms/\(platformName)/protocols/oauth2/redirect_codes/ios/"
    }

    func getOAuthURL(
        platform: String,
        state: String = "",
        autogenerateCodeVerifier: Bool = true,
        supportsUrlSchemes: Bool = true
    ) throws -> Publisher_V1_GetOAuth2AuthorizationUrlResponse {

        print("[Publisher] Getting OAuth URL....")
        let publishingUrlRequest:
            Publisher_V1_GetOAuth2AuthorizationUrlRequest = .with {
                $0.platform = platform
                $0.state =
                    ((platform + "," + (supportsUrlSchemes ? "true" : "false"))
                    .data(using: .utf8)?.base64EncodedString())!
                $0.redirectURL =
                    supportsUrlSchemes
                    ? Publisher.REDIRECT_URL_SCHEME
                    : getRedirectUrl(platformName: platform)
                $0.autogenerateCodeVerifier = autogenerateCodeVerifier
                $0.requestIdentifier = getBase64EncodedPublisherPublicKey()
            }

        print("[Publisher] GetOAuthURLRequest: \(publishingUrlRequest)")
        let call = publisherStub!.getOAuth2AuthorizationUrl(
            publishingUrlRequest)
        let response: Publisher_V1_GetOAuth2AuthorizationUrlResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            print("[Publisher] GetOAuthURLResponse: \(response)")

            print("[Publisher] status code - raw value: \(status.code.rawValue)")
            print("[Publisher] status code - description: \(status.code.description)")
            print("[Publisher] status code - isOk: \(status.isOk)")

            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Publisher] Some error came back: \(error)")
            throw error
        }

        return response
    }

    func sendOAuthAuthorizationCode(
        llt: String,
        platform: String,
        code: String,
        codeVerifier: String,
        storeOnDevice: Bool,
        supportsUrlSchemes: Bool = false
    ) throws -> Publisher_V1_ExchangeOAuth2CodeAndStoreResponse {

        print("[Publisher] Sending OAuth Authorization Code Request with paramaters...")
        print("[Publisher] llt: \(llt) \nplatform: \(platform) \ncode: \(code) \ncodeVerifier: \(String(describing: codeVerifier)) \nstoreOnDevice: \(storeOnDevice), \nsupportsUrlSchemes: \(supportsUrlSchemes)")

        let authorizationRequest:
            Publisher_V1_ExchangeOAuth2CodeAndStoreRequest = .with {
                $0.platform = platform
                $0.authorizationCode = code
                $0.longLivedToken = llt
                $0.storeOnDevice = storeOnDevice
                $0.codeVerifier = codeVerifier
                $0.redirectURL =
                    supportsUrlSchemes
                    ? Publisher.REDIRECT_URL_SCHEME
                    : getRedirectUrl(platformName: platform)
                $0.requestIdentifier = getBase64EncodedPublisherPublicKey()
            }

        print("[Publisher] Authorization Request: \(authorizationRequest)")

        let call = publisherStub!.exchangeOAuth2CodeAndStore(
            authorizationRequest)
        let response: Publisher_V1_ExchangeOAuth2CodeAndStoreResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            print("[Publisher] Authorization Response: \(response)")

            print("[Publisher] status code - raw value: \(status.code.rawValue)")
            print("[Publisher] status code - description: \(status.code.description)")
            print("[Publisher] status code - isOk: \(status.isOk)")

            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Publisher] Some error came back: \(error)")
            throw error
        }

        return response
    }

    private func revokeOAuthPlatform(
        llt: String, platform: String, account: String
    ) throws -> Publisher_V1_RevokeAndDeleteOAuth2TokenResponse {
        print("[Publisher] Revoking OAuth Platform")

        let revokeRequest: Publisher_V1_RevokeAndDeleteOAuth2TokenRequest =
            .with {
                $0.platform = platform
                $0.longLivedToken = llt
                $0.accountIdentifier = account
            }

        print("[Publisher] Revoking OAuth Platform Request: \(revokeRequest)")

        let call = publisherStub!.revokeAndDeleteOAuth2Token(revokeRequest)
        let response: Publisher_V1_RevokeAndDeleteOAuth2TokenResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            print("[Publisher] Revoking OAuth Platform Response: \(response)")
            print("[Publisher] status code - raw value: \(status.code.rawValue)")
            print("[Publisher] status code - description: \(status.code.description)")
            print("[Publisher] status code - isOk: \(status.isOk)")

            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Publisher] Some error came back: \(error)")
            throw error
        }

        return response
    }

    private func revokePNBAPlatform(
        llt: String, platform: String, account: String
    ) throws -> Publisher_V1_RevokeAndDeletePNBATokenResponse {
        let pnbaRevokeRequest: Publisher_V1_RevokeAndDeletePNBATokenRequest =
            .with {
                $0.longLivedToken = llt
                $0.platform = platform
                $0.accountIdentifier = account
            }

        print("[Publisher] Requesting to revoke PNBA Platform...")
        print("[Publisher] Revoke PNBA Platform Request: \(pnbaRevokeRequest)")

        let call = publisherStub!.revokeAndDeletePNBAToken(pnbaRevokeRequest)
        let response: Publisher_V1_RevokeAndDeletePNBATokenResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            print("[Publisher] Revoking PNBA Platform Response: \(response)")

            print("[Publisher] status code - raw value: \(status.code.rawValue)")
            print("[Publisher] status code - description: \(status.code.description)")
            print("[Publisher] status code - isOk: \(status.isOk)")

            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Publisher] Some error came back: \(error)")
            throw error
        }

        return response

    }

    func revokePlatform(
        llt: String, platform: String, account: String, protocolType: String
    ) throws -> Bool {
        print("[Publisher][+] Revoking: \(platform) with protocol type: \(protocolType)")
        if protocolType == ProtocolTypes.OAUTH2.rawValue {
            return try revokeOAuthPlatform(
                llt: llt, platform: platform, account: account
            ).success
        } else if protocolType == ProtocolTypes.PNBA.rawValue {
            return try revokePNBAPlatform(
                llt: llt, platform: platform, account: account
            ).success
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

    public static func refreshPlatforms(
        context: NSManagedObjectContext, completion: @escaping (Bool) -> Void
    ) {
        print("[Publisher] Publisher refreshing platforms...")

        Publisher.getPlatforms { result in
            switch result {
            case .success(let data):
                print("[Publisher] Success: \(data)")

                // Use a dispatch group to track all downloads
                let downloadGroup = DispatchGroup()
                var downloadErrors: [Error] = []

                for platform in data {
                    downloadGroup.enter()
                    downloadAndSaveIcons(
                        url: URL(string: platform.icon_png)!,
                        platform: platform,
                        context: context
                    ) { error in
                        if let error = error {
                            downloadErrors.append(error)
                        }
                        downloadGroup.leave()
                    }
                }

                //Notify when all dowanlods complete
                downloadGroup.notify(queue: .main) {
                    let success = downloadErrors.isEmpty
                    print("[Publisher] All platforms refreshed. Success: \(success)")
                    completion(success)
                }

            case .failure(let error):
                print("[Publisher] Failed to load JSON data: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }

            }

        }

    }

    static func downloadAndSaveIcons(
        url: URL,
        platform: Publisher.PlatformsData,
        context: NSManagedObjectContext,
        completion: @escaping (Error?) -> Void
    ) {
        print("[Publisher] Downloading platform icon and saving platform for: \(platform.name)")

        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            guard let data = data, error == nil else {
                completion(
                    error ?? NSError(domain: "DownloadError", code: -1, userInfo: nil))
                return

            }

            // Perfome Core Data operations on the main queue since we're using the view context
            DispatchQueue.main.async {
                // 1. Fetch existing entity
                let fetchRequest = PlatformsEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(
                    format: "name == %@", platform.name)

                do {
                    let existingPlatforms = try context.fetch(fetchRequest)
                    if let existingPlatform = existingPlatforms.first {
                        // 2. Update existing entity
                        print("[Publisher] Updating existing Platform: \(platform.name)")
                        existingPlatform.image = data
                        existingPlatform.protocol_type = platform.protocol_type
                        existingPlatform.service_type = platform.service_type
                        existingPlatform.shortcode = platform.shortcode
                        existingPlatform.support_url_scheme = platform.support_url_scheme
                    } else {
                        // 3. Create new entity
                        print("[Publisher] Creating new Platform: \(platform.name)")
                        let platformsEntity = PlatformsEntity(context: context)
                        platformsEntity.image = data
                        platformsEntity.name = platform.name
                        platformsEntity.protocol_type = platform.protocol_type
                        platformsEntity.service_type = platform.service_type
                        platformsEntity.shortcode = platform.shortcode
                        platformsEntity.support_url_scheme = platform.support_url_scheme
                    }

                    // 4. Save changes after each platform
                    if context.hasChanges {
                        try context.save()
                        print("[Publisher] Successfully saved platform: \(platform.name)")
                    }

                    completion(nil)

                } catch {
                    print("[Publisher] Error saving Platform \(platform.name): \(error)")
                    completion(error)
                }

            }

        }
        task.resume()
    }

    static func clear(context: NSManagedObjectContext, shouldSave: Bool = true)
        throws
    {
        print("[Publisher] Clearing platforms...")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlatformsEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeCount

        do {
            try context.execute(deleteRequest)
            if shouldSave {
                try context.save()
            }
        } catch {
            print("[Publisher] Error clearing PlatformsEntity: \(error)")
            context.rollback()
            throw error  // Re-throw the error after rollback
        }
    }

    private static func getPlatforms(
        completion: @escaping (Result<[PlatformsData], Error>) -> Void
    ) {
        print("[Publisher] Getting platforms...")

        var url: URL = URL(string: "https://publisher.smswithoutborders.com/v1/platforms")!

        #if DEBUG
            url = URL(string:"https://publisher.staging.smswithoutborders.com/v1/platforms")!
        #endif

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(
                    for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                    200...299 ~= httpResponse.statusCode
                else {
                    completion(.failure(
                            NSError(
                                domain: "HTTPError", code: -1,
                                userInfo: [NSLocalizedDescriptionKey:"HTTP Error: \((response as? HTTPURLResponse)?.statusCode ?? -1)"])
                    )
                    )
                    return
                }

                //Print the raw response
                if let json = try? JSONSerialization.jsonObject(
                    with: data, options: [])
                {
                    print(["[Publisher]: [Get Platforms Resonse]: \(json)"])
                }

                let decodedPlatformsData = try JSONDecoder().decode(
                    [PlatformsData].self, from: data)
                completion(.success(decodedPlatformsData))
            } catch {
                print("[Publisher] Error fetching platforms: \(error)")
                completion(.failure(error))
            }
        }
    }

    //    private static func getPlatforms(completion: @escaping (Result<[PlatformsData], Error>) -> Void) {
    //        print("[Publisher] Getting platforms...")
    //        let platformsUrl = "https://raw.githubusercontent.com/smswithoutborders/SMSWithoutBorders-Publisher/staging/resources/platforms.json"
    //
    //        Task {
    //            do {
    //                let (data, _) = try await URLSession.shared.data(from: URL(string: platformsUrl)!)
    //                let decodedData = try JSONDecoder().decode([PlatformsData].self, from: data)
    //                completion(.success(decodedData))
    //            } catch {
    //                completion(.failure(error))
    //            }
    //        }
    //    }

    public func phoneNumberBaseAuthenticationRequest(
        phoneNumber: String, platform: String
    ) throws -> Publisher_V1_GetPNBACodeResponse {
        let pnbaRequest: Publisher_V1_GetPNBACodeRequest = .with {
            $0.phoneNumber = phoneNumber
            $0.platform = platform
        }

        let call = publisherStub!.getPNBACode(pnbaRequest)
        let response: Publisher_V1_GetPNBACodeResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            print("[Publisher] status code - raw value: \(status.code.rawValue)")
            print("[Publisher] status code - description: \(status.code.description)")
            print("[Publisher] status code - isOk: \(status.isOk)")

            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Publisher] Some error came back: \(error)")
            throw error
        }

        return response
    }

    public func phoneNumberBaseAuthenticationExchange(
        authorizationCode: String,
        llt: String, phoneNumber: String,
        platform: String,
        password: String = ""
    ) throws -> Publisher_V1_ExchangePNBACodeAndStoreResponse {
        let pnbaExchangeRequest: Publisher_V1_ExchangePNBACodeAndStoreRequest =
            .with {
                $0.authorizationCode = authorizationCode
                $0.longLivedToken = llt
                $0.password = password
                $0.phoneNumber = phoneNumber
                $0.platform = platform
            }

        let call = publisherStub!.exchangePNBACodeAndStore(pnbaExchangeRequest)
        let response: Publisher_V1_ExchangePNBACodeAndStoreResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()

            print("[Publisher] status code - raw value: \(status.code.rawValue)")
            print("[Publisher] status code - description: \(status.code.description)")
            print("[Publisher] status code - isOk: \(status.isOk)")

            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Publisher] Some error came back: \(error)")
            throw error
        }

        return response
    }

    public static func canPublish() throws -> Bool {
        do {
            return try !CSecurity.findInKeyChain(
                keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS
            ).isEmpty
        } catch {
            print(error)
            return false
        }
    }

    public static func publish(
        context: NSManagedObjectContext,
        checkPhoneNumberSettings: Bool = true
    ) throws -> MessageComposer {
        do {
            let AD: [UInt8] =
                UserDefaults.standard.object(
                    forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as! [UInt8]
            let deviceID: [UInt8] =
                UserDefaults.standard.object(forKey: Vault.VAULT_DEVICE_ID)
                as! [UInt8]
            let peerPubkey = try Curve25519.KeyAgreement.PublicKey(
                rawRepresentation: AD)
            let pubSharedKey = try CSecurity.findInKeyChain(
                keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
            let usePhonenumber =
                checkPhoneNumberSettings
                ? UserDefaults
                    .standard.bool(
                        forKey: SettingsKeys.SETTINGS_MESSAGE_WITH_PHONENUMBER)
                : true
            print("[Publisher] use deviceID for publishing: \(!usePhonenumber)")

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

    public static func processIncomingUrls(
        context: NSManagedObjectContext,
        url: URL, codeVerifier: String,
        storeOnDevice: Bool,
        storedTokenEntities: FetchedResults<StoredPlatformsEntity>
    ) throws {
        let stateB64Values = url.valueOf("state")
        // Decode the Base64 string to Data
        guard let decodedData = Data(base64Encoded: stateB64Values!) else {
            fatalError("Failed to decode Base64 string")
        }

        // Convert Data to String
        guard let decodedString = String(data: decodedData, encoding: .utf8)
        else {
            fatalError("Failed to convert Data to String")
        }

        print("[Publisher] decoded string: \(decodedString)")
        let values = decodedString.split(separator: ",")
        let state = values[0]
        let supportsUrlScheme = values[1] == "true"

        let code = url.valueOf("code")
        if code == nil {
            return
        }
        print("[Publisher] state: \(state)\ncode: \(code)\ncodeVerifier: \(codeVerifier)\nstoreOnDevice: \(storeOnDevice)")

        do {
            let llt = try Vault.getLongLivedToken()
            let publisher = Publisher()

            let response = try publisher.sendOAuthAuthorizationCode(
                llt: llt,
                platform: String(state),
                code: code!,
                codeVerifier: codeVerifier,
                storeOnDevice: storeOnDevice,
                supportsUrlSchemes: supportsUrlScheme
            )

            print("[Publisher] Saved new account successfully....")

            if response.success {
                try Vault().refreshStoredTokens(
                    llt: llt,
                    context: context,
                    storedTokenEntities: storedTokenEntities
                )
            }
        } catch {
            throw error
        }
    }

    public static func getProtocolTypeForPlatform(
        storedPlatform: StoredPlatformsEntity,
        platforms: FetchedResults<PlatformsEntity>
    ) -> String {
        for platform in platforms {
            if platform.name == storedPlatform.name {
                return platform.protocol_type!
            }
        }
        return ""
    }

}
