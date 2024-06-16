//
//  OAuth.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 15/06/2024.
//

import Foundation
import UIKit
import AppAuth
import AppAuthCore


class AppDelegate: UIResponder, UIApplicationDelegate {
    var request: OIDAuthorizationRequest?
    
    var session: OIDExternalUserAgentSession?
    
    var userAgent: OIDExternalUserAgentIOS?
    
    // property of the app's AppDelegate
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    // property of the containing class
    private var authState: OIDAuthState?
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Sends the URL to the current authorization flow (if any) which will
        // process it if it relates to an authorization response.
        if let authorizationFlow = self.currentAuthorizationFlow,
                                 authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            self.currentAuthorizationFlow = nil
            return true
        }

        // Your additional URL handling (if any)

        return false
    }
    
    func startAuthentication(presenting viewController: UIViewController) {
        
        let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth?access_type=offline")!
        let tokenEndpoint = URL(string: "https://www.googleapis.com/oauth2/v4/token")!
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                                    tokenEndpoint: tokenEndpoint)
        
        let clientID = "86878463881-3miiph6l8e8almabu5mat1gun3aaumrv.apps.googleusercontent.com"
        let clientSecret = ""
        let redirectURI = URL(string: "https://example.com")!
        
        // builds authentication request
        request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        
        // performs authentication request
        print("Initiating authorization request with scope: \(request?.scope ?? "nil")")
        
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        userAgent = OIDExternalUserAgentIOS(presenting: viewController)!
        
        self.currentAuthorizationFlow =
        OIDAuthState.authState(byPresenting: request!, externalUserAgent: userAgent!) { authState, error in
            if let authState = authState {
                self.authState = authState
                print("Got authorization tokens. Access token: " +
                      "\(authState.lastTokenResponse?.accessToken ?? "nil")")
            } else {
                print("Authorization error: \(error?.localizedDescription ?? "Unknown error")")
                self.authState = nil
            }
        }
    }
}

class ViewController: UIViewController {
    var appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.appDelegate = appDelegate
        self.appDelegate?.startAuthentication(presenting: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


