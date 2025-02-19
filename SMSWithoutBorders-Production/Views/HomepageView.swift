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
    
    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: RequestType = .available

    @State var composeNewMessageRequested: Bool = false
    @State var loginSheetRequested: Bool = false
    @State var createAccountSheetRequested: Bool = false
    @State var passwordRecoveryRequired: Bool = false
    @State var isLoggedIn: Bool = false

    init(codeVerifier: Binding<String>) {
        _codeVerifier = codeVerifier
        
        do {
            self.isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print(error)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination:
                        RecoverySheetView( isRecovered: $isLoggedIn ),
                    isActive: $passwordRecoveryRequired
                ) {
                    EmptyView()
                }
                
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
                        loginRequested: $loginSheetRequested,
                        accountCreated: $isLoggedIn
                    ),
                    isActive: $createAccountSheetRequested) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: LoginSheetView(
                        isLoggedIn: $isLoggedIn,
                        createAccountRequested: $createAccountSheetRequested,
                        passwordRecoveryRequired: $passwordRecoveryRequired
                    ),
                    isActive: $loginSheetRequested) {
                    EmptyView()
                }

                TabView(selection: Binding(
                    get: { selectedTab },
                    set: {
                        if $0 == .platforms && selectedTab != .platforms {
                            platformRequestType = .available
                        }
                        selectedTab = $0
                    }
                )){
                    if(isLoggedIn) {
                        RecentsViewLoggedIn(
                            selectedTab: $selectedTab,
                            platformRequestType: $platformRequestType
                        )
                        .tabItem() {
                            Image(systemName: "house.circle.fill")
                                Text("Recents")
                            }
                        .tag(HomepageTabs.recents)
                        
                        PlatformsView(requestType: $platformRequestType)
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
        .onAppear {
            do {
                isLoggedIn = try !Vault.getLongLivedToken().isEmpty
            } catch {
                print(error)
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
        
        return HomepageView(codeVerifier: $codeVerifier)
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
        
        return HomepageView(codeVerifier: $codeVerifier)
    }
}
