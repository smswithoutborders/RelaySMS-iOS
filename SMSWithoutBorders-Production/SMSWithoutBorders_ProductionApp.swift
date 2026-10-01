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

struct HomepageView: View {
    var body: some View {
        TabView {
            Tab("Recent", systemImage: "house.circle") {
                EmptyView()
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
                HomepageView()
            }
        }
        .modelContainer(for: [
            SupportedPlatforms.self,
            GatewayClients.self,
            LocalKeys.self,
        ])
    }
    
}


#Preview {
    HomepageView()
}
