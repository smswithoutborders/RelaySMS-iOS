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
    @State var isLoggedIn: Bool = true
    
    @State var selectedTab: HomepageTabs = .recents

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                RecentsView(codeVerifier: $codeVerifier, isLoggedIn: isLoggedIn)
                    .tabItem() {
                        Image(systemName: "house.circle.fill")
                        Text("Recents")
                    }
                    .tag(HomepageTabs.recents)
                
                GatewayClientsView()
                    .tabItem() {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        Text("Gateway Clients")
                    }
                    .tag(HomepageTabs.gatewayClients)
                
                SettingsView()
                    .tabItem() {
                        Image(systemName: "gear.circle.fill")
                        Text("Settings")
                    }
                    .tag(HomepageTabs.settings)
            }.onChange(of: selectedTab) { newTab in
                if newTab == HomepageTabs.recents{
                    print("checking for loggin")
                    do {
                        isLoggedIn = try !Vault.getLongLivedToken().isEmpty
                    } catch {
                        print("error checking status")
                    }
                }
            }
        }
    }
    
}


struct HomepageView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])
        
        return HomepageView(codeVerifier: $codeVerifier)
    }
}
