//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData

@main
struct SMSWithoutBorders_ProductionApp: App {
    // cases:
    // case 1: sync view with no gateway server url
    // case 2: sync view with gateway server url
    
    @State var navigatingFromURL: Bool = false
    @State var absoluteURLString: String = ""
    
    @StateObject private var dataController = DataController()
    
    let cSecurity = CSecurity()
    
    init() {
        print("Starting up SMSWithoutBorders")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if navigatingFromURL {
                    SynchronizeView(gatewayServerURL: absoluteURLString, syncStatement: "Click to start handshake")
                            .environment(\.managedObjectContext, dataController.container.viewContext)
                }
                else if cSecurity.findInKeyChain().isEmpty {
                    SynchronizeView()
                }
                else {
                    AvailablePlatformsView()
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                }
            }
            .onOpenURL { url in
                print(url.absoluteString)
                
                if(url.scheme == "apps") {
                    absoluteURLString = url.absoluteString.replacingOccurrences(of: "apps", with: "https")
                    navigatingFromURL = true
                }
            }
        }
    }
}
