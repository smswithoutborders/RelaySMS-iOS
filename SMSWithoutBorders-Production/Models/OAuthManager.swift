//
//  OAuthManager.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI
import AuthenticationServices

class OAuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false
    private var webAuthSession: ASWebAuthenticationSession?

    func startOAuthFlow(
        url: String,
        platformName: String
    ) {
        let authURL = URL(string: url)!
        let callbackScheme = "relaysms"

        self.webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let callbackURL = callbackURL else { return }
            // Extract code/token from callbackURL and exchange for access token
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }

        self.webAuthSession?.presentationContextProvider = self
        self.webAuthSession?.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
