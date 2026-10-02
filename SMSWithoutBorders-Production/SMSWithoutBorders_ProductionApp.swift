//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData
import SwiftData

struct MainView: View {
    var body: some View {
        TabView {
            Tab("Recent", systemImage: "house.circle") {
                HomepageView()
            }
            
            Tab("Platforms", systemImage: "server.rack") {
                SupportedPlatformsView()
            }
            
            Tab("Routing numbers", systemImage: "phone.arrow.up.right.circle") {
                GatewayClientsView()
            }
        }
    }
}



@main
struct SMSWithoutBorders_ProductionApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                MainView()
            }
        }
        .modelContainer(for: [
            SupportedPlatforms.self,
            GatewayClients.self,
            LocalKeys.self,
            Tokens.self,
        ])
    }
    
}


#Preview {
    MainView()
}
