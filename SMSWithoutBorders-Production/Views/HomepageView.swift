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
}

struct HomepageView: View {
    @Binding var codeVerifier: String
    @State var isLoggedIn: Bool = false
    
    @State var selectedTab: HomepageTabs = .recents

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                RecentsView(codeVerifier: $codeVerifier, isLoggedIn: getIsLoggedIn())
                    .tabItem() {
                        Image(systemName: "house.circle")
                        Text("Recents")
                    }
                    .tag(HomepageTabs.recents)
                SettingsView()
                    .tabItem() {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(HomepageTabs.settings)
            }.onChange(of: selectedTab) { newTab in
                
            }
        }
    }
    
    func getIsLoggedIn() -> Bool {
        do {
            return try !Vault.getLongLivedToken().isEmpty
        } catch {
            print("error checking loggins: \(error)")
        }
        return false
    }
}


struct HomepageView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""

    static var previews: some View {
//        RecentsViewAdapter(codeVerifier: $codeVerifier, platformType: $platformType, 
//                           platform: $platform)
        HomepageView(codeVerifier: $codeVerifier)
    }
}
