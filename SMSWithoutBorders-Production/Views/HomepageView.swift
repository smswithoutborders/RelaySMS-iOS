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
    case inbox
}

struct HomepageView: View {
    @Environment(\.managedObjectContext) var context
    
    @Binding var codeVerifier: String
    
    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: PlatformsRequestedType = .available

    @State var composeNewMessageRequested: Bool = false
    @State var composeTextRequested: Bool = false
    @State var composeMessageRequested: Bool = false
    @State var composeEmailRequested: Bool = false

    @State var loginSheetRequested: Bool = false
    @State var createAccountSheetRequested: Bool = false
    @State var passwordRecoveryRequired: Bool = false
    @State var requestedPlatformName: String = ""
    
    @Binding var isLoggedIn: Bool

    init(codeVerifier: Binding<String>, isLoggedIn: Binding<Bool>) {
        _codeVerifier = codeVerifier
        _isLoggedIn = isLoggedIn

        do {
            self.isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print(error)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Compose views
                NavigationLink(
                    destination: EmailView(
                        platformName: Bridges.SERVICE_NAME,
                        isBridge: true
                    ),
                    isActive: $composeNewMessageRequested
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: EmailView(platformName: requestedPlatformName),
                    isActive: $composeEmailRequested
                ) {
                    EmptyView()
                }

                NavigationLink(
                    destination: TextComposeView(platformName: requestedPlatformName),
                    isActive: $composeTextRequested
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: MessagingView(
                        platformName: requestedPlatformName
                    ),
                    isActive: $composeMessageRequested
                ) {
                    EmptyView()
                }

                
                NavigationLink(
                    destination:
                        RecoverySheetView( isRecovered: $isLoggedIn ),
                    isActive: $passwordRecoveryRequired
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: SignupSheetView(
                        loginRequested: $loginSheetRequested,
                        accountCreated: $isLoggedIn
                    ),
                    isActive: $createAccountSheetRequested
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: LoginSheetView(
                        isLoggedIn: $isLoggedIn,
                        createAccountRequested: $createAccountSheetRequested,
                        passwordRecoveryRequired: $passwordRecoveryRequired
                    ),
                    isActive: $loginSheetRequested
                ) {
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
                        
                        PlatformsView(
                            requestType: $platformRequestType,
                            requestedPlatformName: $requestedPlatformName,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            composeTextRequested: $composeTextRequested,
                            composeMessageRequested: $composeMessageRequested,
                            composeEmailRequested: $composeEmailRequested
                        )
                        .tabItem() {
                            Image(systemName: "apps.iphone")
                            Text("Platforms")
                        }.tag(HomepageTabs.platforms)

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
                    
                    InboxView()
                        .tabItem() {
                            Image(systemName: "tray")
                            Text("Inbox")
                        }
                        .tag(HomepageTabs.inbox)

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
        .onChange(of: isLoggedIn) { state in
            if state {
                Publisher.refreshPlatforms(context: context)
                
                Task {
                    if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                        print("Is searching for default....")
                        do {
                            try await GatewayClients.refresh(context: context)
                        } catch {
                            print("Error refreshing gateways: \(error)")
                        }
                    }
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
        
        return HomepageView(
            codeVerifier: $codeVerifier,
            isLoggedIn: $isLoggedIn
        )
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
        
        return HomepageView(
            codeVerifier: $codeVerifier,
            isLoggedIn: $isLoggedIn
        )
    }
}
