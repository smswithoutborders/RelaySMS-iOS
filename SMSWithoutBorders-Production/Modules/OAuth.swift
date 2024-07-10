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

class OAuthViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    
    var presentingViewController: OAuthViewController = OAuthViewController()
    
    var request: OIDAuthorizationRequest?
    
    var session: OIDExternalUserAgentSession?
    
    var userAgent: OIDExternalUserAgentIOS?
    
    // property of the app's AppDelegate
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    // property of the containing class
    private var authState: OIDAuthState?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("App has finished launching")
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Pause tasks and disable timers
        print("App will resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save application state and release resources
        print("App entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Undo background state changes
        print("App will enter foreground")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Save data and clean up resources
        print("App will terminate")
    }

    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
       print("source application = \(sendingAppID ?? "Unknown")")

       // Process the URL.
       guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
           let authorizationPath = components.path,
           let params = components.queryItems else {
               print("Invalid URL or album path missing")
               return false
       }

       if let platform = params.first(where: { $0.name == "platform" })?.value {
           print("authorization_path = \(authorizationPath)")
           print("platform_name = \(platform)")
           return true
       } else {
           print("No platform index found")
           return false
       }
    
        if let codeVerifier = params.first(where: { $0.name == "code_challenge" })?.value {
            print("authorization_path = \(authorizationPath)")
            print("code_challenge = \(codeVerifier)")
            return true
        } else {
            print("No platform index found")
            return false
        }
        
    }
    
    func startAuthentication( authorizationEndpoint: URL,
                             clientID: String, 
                             redirectURI: URL, 
                             platform: Publisher.PlatformsData,
                             codeVerifier: String) -> URL?{
        let tokenEndpoint = URL(string: "https://example.com")!
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                                    tokenEndpoint: tokenEndpoint)
        
        let mRedirectUrl = URL(string: "https://oauth.afkanerd.com/platforms/gmail/protocols/oauth2/redirect_codes/ios/")!
        
        let clientSecret = ""
        
        let state = platform.name
        
        // builds authentication request
        request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile],
                                          redirectURL: mRedirectUrl,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
//        return URL(string: (request?.authorizationRequestURL().absoluteString)! + "&state=\(state)")
        request?.setValue(state, forKey: "state")
        return request?.authorizationRequestURL()

        
        
//        let userinfoEndpoint = URL(string:"https://openidconnect.googleapis.com/v1/userinfo")!
//        self.authState?.performAction() { (accessToken, idToken, error) in
//
//          if error != nil  {
//            print("Error fetching fresh tokens: \(error?.localizedDescription ?? "Unknown error")")
//            return
//          }
//          guard let accessToken = accessToken else {
//            return
//          }
//
//          // Add Bearer token to request
//            var urlRequest = URLRequest(url: request?.authorizationRequestURL())
//          urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
//
//          // Perform request...
//        }
//        
//        // performs authentication request
//        print("Initiating authorization request with scope: \(request?.scope ?? "nil")")
//        
////        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        
////        userAgent = OIDExternalUserAgentIOS(presenting: viewController)!
//        userAgent = OIDExternalUserAgentIOS(presenting: presentingViewController)!
//
//        self.currentAuthorizationFlow =
//        OIDAuthState.authState(byPresenting: request!, externalUserAgent: userAgent!) { authState, error in
//            if let authState = authState {
//                self.authState = authState
//                print("Got authorization tokens. Access token: " +
//                      "\(authState.lastTokenResponse?.accessToken ?? "nil")")
//            } else {
//                print("Authorization error: \(error?.localizedDescription ?? "Unknown error")")
//                self.authState = nil
//            }
//        }
    }
}



