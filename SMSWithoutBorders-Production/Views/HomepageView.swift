//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

enum HomepageTabs {
    case recents
    case platforms
    case settings
    case gatewayClients
}

struct HomepageView: View {
    @Binding var codeVerifier: String
    @Binding var isLoggedIn: Bool
    
    @State var selectedTab: HomepageTabs = .recents
    
    @State var composeNewMessageRequested: Bool = false
    @State var loginSheetRequested: Bool = false
    @State var createAccountSheetRequested: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination: EmailView(
                        platformName: Bridges.SERVICE_NAME,
                        fromAccount: nil,
                        isBridge: true
                    ),
                    isActive: $composeNewMessageRequested
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: SignupSheetView(
                        loginRequested: $loginSheetRequested
                    ),
                    isActive: $createAccountSheetRequested) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: LoginSheetView(
                        isLoggedIn: $isLoggedIn,
                        createAccountRequested: $createAccountSheetRequested
                    ),
                    isActive: $loginSheetRequested) {
                    EmptyView()
                }

                TabView(selection: Binding(
                    get: { selectedTab },
                    set: {
                        selectedTab = $0
                        print($0)
                    }
                )){
                    if(isLoggedIn) {
                        RecentsViewLoggedIn()
                        .tabItem() {
                            Image(systemName: "house.circle.fill")
                                Text("Recents")
                            }
                        .tag(HomepageTabs.recents)
                        
                        PlatformsView()
                            .tabItem() {
                                Image(systemName: "apps.iphone")
                                Text("Platforms")
                            }
                            .tag(HomepageTabs.platforms)

                    } else {
                        RecentsViewNotLoggedIn(
                            isLoggedIn: $isLoggedIn,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            createAccountSheetRequested: $createAccountSheetRequested,
                            loginSheetRequested: $loginSheetRequested
                        )
                        .tabItem() {
                            Image(systemName: "house.circle.fill")
                                Text("Get started")
                            }
                        .tag(HomepageTabs.recents)
                        
                    }
                    
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

struct HomepageViewLoggedIn_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    @State static var isLoggedIn: Bool = true

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])
        
        return HomepageView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
    }
}
