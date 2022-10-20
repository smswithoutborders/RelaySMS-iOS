//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData

struct mainViewAdapter: View {
    @Environment(\.managedObjectContext) var datastore
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    let cSecurity = CSecurity()
    
    var body: some View {
        if cSecurity.findInKeyChain().isEmpty || platforms.isEmpty {
            SynchronizeView()
        }
        else {
            RecentsView()
                .environment(\.managedObjectContext, datastore)
        }
    }
    
}

@main
struct SMSWithoutBorders_ProductionApp: App {
    // cases:
    // case 1: sync view with no gateway server url
    // case 2: sync view with gateway server url
    
    @State var navigatingFromURL: Bool = false
    @State var absoluteURLString: String = ""
    
    @StateObject private var dataController: DataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if navigatingFromURL {
                    SynchronizeView(gatewayServerURL: absoluteURLString)
                            .environment(\.managedObjectContext, dataController.container.viewContext)
                }
                else {
                    mainViewAdapter()
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
