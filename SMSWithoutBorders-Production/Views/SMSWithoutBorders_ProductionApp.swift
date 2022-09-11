//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation

@main
struct SMSWithoutBorders_ProductionApp: App {
    // cases:
    // case 1: sync view with no gateway server url
    // case 2: sync view with gateway server url
    
    @State var navigationView: Int;
    @State var absoluteURLString: String;
    
    init() {
        print("Starting up SMSWithoutBorders")
        navigationView = 1
        absoluteURLString = ""
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch navigationView {
                    
                case 2:
                    SynchronizeView(gatewayServerURL: absoluteURLString, syncStatement: "Click to start handshake")
                    
                default:
                    SynchronizeView()
                }
            }
            .onOpenURL { url in
                print(url.absoluteString)
                
                if(url.scheme == "apps") {
                    absoluteURLString = url.absoluteString.replacingOccurrences(of: "apps", with: "https")
                    navigationView = 2
                }
            }
        }
    }
}
