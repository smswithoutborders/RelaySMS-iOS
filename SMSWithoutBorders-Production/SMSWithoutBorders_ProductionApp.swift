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
    @AppStorage("selectedLanguage") private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    
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
            .environment(\.locale, Locale(identifier: selectedLanguage))
            .environment(
                \.layoutDirection,
                 (
                    selectedLanguage == "ar" ||
                    selectedLanguage == "fa"
                 ) ? .rightToLeft : .leftToRight)
            .transaction { transaction in
                // Prevents SwiftUI from trying to animate layout shifts during a language change
                transaction.animation = nil
            }
            .id(selectedLanguage)
        }
        .modelContainer(for: [
            SupportedPlatforms.self,
            GatewayClients.self,
            Tokens.self,
            Payloads.self,
        ])
    }
    
}


#Preview {
    MainView()
}
