//
//  StaticVariables.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import Foundation

class StaticVariables {
    class GRPC {
        
        static func getUrl() -> String {
        #if DEBUG
            let url = "publisher.relaysms.afkanerd.de"
        #else
            let url = "relaysms.smswithoutborders.afkanerd.com"
        #endif
            return url
        }
        
        static func getPort() -> Int {
            let port = 443
            return port
        }
    }
    
    class Publisher {
        private static let redirectUrl = "https://relay.smswithoutborders.com/ios"
        
        #if DEBUG
        static let mimiGatewayClientUrl = "https://publisher.relaysms.afkanerd.de/v1/publications"
        #else
        static let mimiGatewayClientUrl = "https://relaysms.smswithoutborders.afkanerd.com/v1/publications"
        #endif

        static func getRedirectUrl() -> String {
            return redirectUrl
        }
        
        static func getRedirectComponents() -> (domain: String, path: String)? {
            guard let components = URLComponents(string: redirectUrl) else {
                return nil
            }
            
            guard let host = components.host else {
                return nil
            }
            
            let path = components.path
            
            // Include query parameters if present (e.g., "/ios/v1?token=123")
            var fullPath = path
            if let query = components.query {
                fullPath += "?\(query)"
            }
            
            return (domain: host, path: fullPath)
        }
    }
}
