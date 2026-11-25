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

enum AppTab: Hashable {
    case recent
    case platforms
    case gatewayClients

    var titleKey: LocalizedStringKey {
        switch self {
        case .recent: "Recent"
        case .platforms: "Platforms"
        case .gatewayClients: "Routing numbers"
        }
    }

    var systemImage: String {
        switch self {
        case .recent: "house.circle"
        case .platforms: "server.rack"
        case .gatewayClients: "phone.arrow.up.right.circle"
        }
    }
}

struct MainView: View {
    @State private var selectedTab: AppTab = .recent
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.recent.titleKey, systemImage: AppTab.recent.systemImage, value: AppTab.recent) {
                HomepageView()
            }
            
            Tab(AppTab.platforms.titleKey, systemImage: AppTab.platforms.systemImage, value: AppTab.platforms) {
                SupportedPlatformsView()
            }
            
            Tab(AppTab.gatewayClients.titleKey, systemImage: AppTab.gatewayClients.systemImage, value: AppTab.gatewayClients) {
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
