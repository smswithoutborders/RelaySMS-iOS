//
//  Untitled.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 28/09/2026.
//

import Observation
import Foundation
import CoreData
import SwiftData

enum SupportedPlatformsFetchState {
    case loading
    case idle
    case revoking
    case failure(data: String)
}

enum PnbaState : Equatable {
    case idle
    case complete
    case phoneNumberRequested
    case authCodeRequested
    case passwordRequested
}

@Observable
class SupportedPlatformsViewModel {
    enum SupportedPlatformsViewModelError: Error {
        case failedToGenerateRequestId
        case failedToGetOAuthUrl
        case failedToRevokeOAuth2
    }
    
    private(set) var fetchState: SupportedPlatformsFetchState = .loading
    private(set) var pnbaState: PnbaState = .idle
    private(set) var pnbaStateFailure: String = ""
    
    private(set) var isStoring: Bool = false

    func fetch(into container: ModelContainer) async {
        fetchState = .loading
        guard let url = URL(string: SupportedPlatforms.supportedUrl) else {
            print("Invalid URL")
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                fetchState = .failure(data: "https request failed")
                return
            }

            let supportedPlatforms = try JSONDecoder().decode([SupportedPlatforms.SupportPlatformsData].self, from: data)
            print("Successfully fetched \(supportedPlatforms.count) platforms.")
            
            try SupportedPlatforms.save(data: supportedPlatforms, into: container)
            fetchState = .idle
        } catch {
            print("Failed to fetch data: \(error.localizedDescription)")
            fetchState = .failure(data: error.localizedDescription)
        }
    }
    
    func requestOAuthUrl(
        platform: SupportedPlatforms,
        into container: ModelContainer,
        oauthManager: OAuthManager,
    ) async throws {
        isStoring = true
        let publisherImpl = PublisherImpl(container: container)

        guard let requestId = generate32RandomBytes()?.base64EncodedString() else {
            throw SupportedPlatformsViewModelError.failedToGenerateRequestId
        }
        
        do {
            let response = try await publisherImpl.getAuthUrl(
                availablePlatform: platform,
                requestIdentifier: requestId
            )
            
            let oAuthRequest = OAuthManager.OAuthRequest(
                platformName: platform.name,
                codeVerifier: response.codeVerifier,
                requestIdentifier: requestId
            )
            
            try await oauthManager.startOAuthFlow(
                url: response.authorizationURL,
                platformName: platform.name,
            ) { code in
                Task.detached(priority: .background) {
                    do {
                        let response = try await publisherImpl.sendOAuthAuthorizationCode(
                            platformName: platform.name,
                            code: code,
                            codeVerifier: response.codeVerifier,
                            requestIdentifier: requestId,
                        )
                        DispatchQueue.main.async {
                            oauthManager.isAuthenticated = true
                        }
                    } catch {
                        print(error)
                    }
                    self.isStoring = false
                }
            }
        } catch {
            self.isStoring = false
            throw error
        }
    }
    
    func requestPnba(
        platform: SupportedPlatforms,
        phoneNumber: String,
        code: String?,
        password: String?,
        channel: String,
        into container: ModelContainer,
    ) async throws {
        pnbaStateFailure = ""
        let publisherImpl = PublisherImpl(container: container)
        
        if phoneNumber.isEmpty {
            pnbaState = .phoneNumberRequested
            return
        }
        isStoring = true
        
        if pnbaState == .phoneNumberRequested && (code != nil && !code!.isEmpty) {
            pnbaState = .authCodeRequested
        }

        switch pnbaState {
        case .phoneNumberRequested:
            do {
                let _ = try await publisherImpl.requestPnbaCode(
                    phoneNumber: phoneNumber,
                    platformName: platform.name,
                    channel: channel
                )
                pnbaState = .authCodeRequested
            } catch {
                print(error)
                if error.localizedDescription.hasPrefix("invalidArgument:") {
                    pnbaStateFailure = String(localized: "The phone number has a problem")
                } else {
                    pnbaStateFailure = error.localizedDescription
                }
            }
            
        case .authCodeRequested:
            do {
                let response = try await publisherImpl.sendPnbaAuthorizationExchange(
                    code: code!,
                    phoneNumber: phoneNumber,
                    platformName: platform.name,
                    channel: channel,
                    password: password
                )
                if response != nil {
                    pnbaState = .passwordRequested
                } else {
                    pnbaState = .complete
                }
            } catch {
                print(error)
                if error.localizedDescription.hasPrefix("invalidArgument:") {
                    pnbaStateFailure = String(localized: "Invalid or wrong code")
                } else {
                    pnbaStateFailure = error.localizedDescription
                }
            }
        case .passwordRequested:
            do {
                let _ = try await publisherImpl.sendPnbaAuthorizationExchange(
                    code: code!,
                    phoneNumber: phoneNumber,
                    platformName: platform.name,
                    channel: channel,
                    password: password
                )
                pnbaState = .complete
            } catch {
                print(error)
                if error.localizedDescription.hasPrefix("invalidArgument:") {
                    pnbaStateFailure = String(localized: "Invalid or wrong password")
                } else {
                    pnbaStateFailure = error.localizedDescription
                }
            }
        case .idle, .complete:
            break
        }
            
        
        isStoring = false
    }
    
    func setIsStoring(isStoring: Bool) {
        self.isStoring = isStoring
    }
    
    func setPnbaState(state: PnbaState) {
        self.pnbaState = state
        self.pnbaStateFailure = ""
    }
    
    func setState(_ state: SupportedPlatformsFetchState) {
        self.fetchState = state
    }
    
    func revoke(
        _ account: Tokens,
        _ proto: Int,
        into container: ModelContainer
    ) async throws {
        isStoring = true
        let publisherImpl = PublisherImpl(container: container)
        do {
            if proto == V1PayloadsSupportedProtocols.oAuth20.rawValue {
                try await publisherImpl.revokeOAuth2( tokenId: account.id, )
            }
            
            fetchState = .idle
            
        } catch {
            print(error)
            isStoring = false
            throw SupportedPlatformsViewModelError.failedToRevokeOAuth2
        }
        isStoring = false
    }
}
