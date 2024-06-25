//
//  OnboardingIntroToVaults.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI
import AppAuthCore
import AppAuth

struct OnboardingIntroToVaults: View {
    @State var currentTab = "intro"
    @State var loginSheetShown = false
    @State var authRequestSheetShown = false
    
    var appDelegate: AppDelegate

    var body: some View {
        TabView(selection: $currentTab) {
            VStack {
                Tab(buttonView:
                    Group {
                        Button("Login") {
                            loginSheetShown = true
                        }
                        .buttonStyle(.borderedProminent)
                        .sheet(isPresented: $loginSheetShown) {
                            VStack {
                                LoginSheetView()
                            }
                        }
                        
                        Button("Create new") {
                            
                        }
                        .buttonStyle(.borderedProminent)
                    }, 
                    title:"Let's get you started",
                    subTitle: "Introducing Vaults",
                    description: "RelaySMS Vaults keep secure access to your online accounts while you are offline",
                    imageName: "OnboardingVault",
                    subDescription: "Create a new RelaySMS Vault account or signup to your existing."
                )
            }
            .tag("intro")
            
            VStack {
                Tab(buttonView:
                    Button("Add Accounts") {
                        ViewController(appDelegate: appDelegate)
                    }
                    .buttonStyle(.borderedProminent),
                    title: "Add Accounts to Vault",
                    subTitle: "Let's get you started",
                    description: "You can add accounts your Vault. This accounts are accessible to you when you are offline",
                    imageName: "OnboardingVaultOpen",
                    subDescription: "The Vault supports storing for multiple online paltforms. Click Add Accounts storage to see the list"
                )
            }
            .tag("example-store")
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

#Preview {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    return OnboardingIntroToVaults(currentTab: "example-store", appDelegate: appDelegate)
}