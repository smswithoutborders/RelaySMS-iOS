//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

struct HomepageView: View {
    @Binding var codeVerifier: String

    var body: some View {
        NavigationView {
            TabView {
                RecentsView(codeVerifier: $codeVerifier)
                    .tabItem() {
                        Image(systemName: "house.circle")
                        Text("Recents")
                    }
                SettingsView()
                    .tabItem() {
                        Image(systemName: "gear")
                        Text("Settings")
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
//        RecentsViewAdapter(codeVerifier: $codeVerifier, platformType: $platformType, 
//                           platform: $platform)
        HomepageView(codeVerifier: $codeVerifier)
    }
}
