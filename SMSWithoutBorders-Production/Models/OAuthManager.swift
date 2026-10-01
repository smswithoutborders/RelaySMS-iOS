//
//  OAuthManager.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI
import AuthenticationServices
import SwiftData

class OAuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false
    struct OAuthRequest {
        let platformName: String
        let codeVerifier: String
        let requestIdentifier: String
    }
    private var webAuthSession: ASWebAuthenticationSession?

    /**
     This is temporal, waiting for figure out this AASA thing
     */

    enum OAuthManagerError: Error {
        case failedToGetRedirectComponents
        case failedToConvertToBase64
        case failedToGetStringForUrlData
        case failedToGetCode
        case contextContainerCannotBeNil
    }

    func startOAuthFlow(
        url: String,
        platformName: String,
        onCompleteCallback: @escaping (String) -> Void
    ) throws {
        let authURL = URL(string: url)!
        
        guard let redirectComponents = StaticVariables.Publisher.getRedirectComponents() else {
            throw OAuthManagerError.failedToGetRedirectComponents
        }
        
        let callback: ASWebAuthenticationSession.Callback = .https(
            host: redirectComponents.domain,
            path: redirectComponents.path
        )

        self.webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callback: callback,
        ) { callbackURL, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard callbackURL != nil else { return }
            
            guard let code = self.processIncomingUrls(url: callbackURL!) else {
                print("OAuthManagerError.failedToGetCode")
                return
            }
            onCompleteCallback(code)
        }

        self.webAuthSession?.presentationContextProvider = self
        self.webAuthSession?.prefersEphemeralWebBrowserSession = false
        self.webAuthSession?.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    private func processIncomingUrls(url: URL) -> String? {
        let stateB64Values = url.valueOf("state")
        // Decode the Base64 string to Data
        guard let decodedData = Data(base64Encoded: stateB64Values!) else {
            return nil
        }
        
//        guard let decodedString = String(data: decodedData, encoding: .utf8) else {
//            return nil
//        }
//        let values = decodedString.split(separator: ",")
//        let state = values[0]
//        let supportsUrlScheme = values[1] == "true"
        
        let code = url.valueOf("code")
        if code == nil {
            return nil
        }
        return code
    }

}
