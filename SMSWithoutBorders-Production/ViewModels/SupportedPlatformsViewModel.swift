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
    case failure(data: String)
}

@Observable
class SupportedPlatformsViewModel {
    enum SupportedPlatformsViewModelError: Error {
        case failedToGenerateRequestId
        case failedToGetOAuthUrl
    }
    private(set) var fetchState: SupportedPlatformsFetchState = .loading
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
            throw error
        }
    }
    
    func setIsStoring(isStoring: Bool) {
        self.isStoring = isStoring
    }

}
