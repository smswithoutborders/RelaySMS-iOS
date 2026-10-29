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
            Tab(String(localized: "Recent"), systemImage: "house.circle") {
                HomepageView()
            }
            
            Tab(String(localized: "Platforms"), systemImage: "server.rack") {
                SupportedPlatformsView()
            }
            
            Tab(String(localized: "Routing numbers"), systemImage: "phone.arrow.up.right.circle") {
                GatewayClientsView()
            }
        }
    }
}



@main
struct SMSWithoutBorders_ProductionApp: App {
    @AppStorage("isOnboarded") private var isOnboarded = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isOnboarded {
                    OnboardingView(onboardingCompletedCallback: {
                        isOnboarded = true
                    })
                } else {
                    MainView()
                }
            }
        }
        .modelContainer(for: [
            SupportedPlatforms.self,
            GatewayClients.self,
            LocalKeys.self,
            Tokens.self,
            Payloads.self,
        ])
    }
    
}


#Preview {
    MainView()
}
