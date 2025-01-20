//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

enum HomepageTabs {
    case recents
    case settings
    case gatewayClients
}

struct HomepageView: View {
    @Binding var codeVerifier: String
    @Binding var isLoggedIn: Bool
    
    @State var selectedTab: HomepageTabs = .recents

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                RecentsView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
                    .tabItem() {
                        Image(systemName: "house.circle.fill")
                        Text("Recents")
                    }
                    .tag(HomepageTabs.recents)
                
                GatewayClientsView()
                    .tabItem() {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        Text("Countries")
                    }
                    .tag(HomepageTabs.gatewayClients)
                
                SettingsView(isLoggedIn: $isLoggedIn)
                    .tabItem() {
                        Image(systemName: "gear.circle.fill")
                        Text("Settings")
                    }
                    .tag(HomepageTabs.settings)
            }
            
        }
    }
}

struct HomepageView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    @State static var isLoggedIn: Bool = false

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])
        
        return HomepageView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
    }
}
