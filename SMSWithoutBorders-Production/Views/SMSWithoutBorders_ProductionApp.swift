//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData


@main
struct SMSWithoutBorders_ProductionApp: App {
    @StateObject private var languageManager: LanguagePreferencesManager = LanguagePreferencesManager()
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var dataController = DataController()

//    private var onboardingCompleted: Bool = UserDefaults.standard.bool(forKey: OnboardingView.ONBOARDING_COMPLETED)

    @AppStorage(OnboardingView.ONBOARDING_COMPLETED)
    private var onboardingCompleted: Bool = false

    @State private var alreadyLoggedIn: Bool = false
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if(!onboardingCompleted) {
                    OnboardingView()
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                }
                else {
                    HomepageView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .alert("You are being logged out!", isPresented: $alreadyLoggedIn) {
                        Button("Get me out!") {
                            getMeOut()
                        }
                    } message: {
                        Text(String(localized:"It seems you logged into another device. You can use RelaySMS on only one device at a time.", comment: "Explains that you cannot be logged in on multiple devices at a time"))
                    }
                    .onAppear() {
                        validateLLT()
                    }
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .active {
                            validateLLT()
                        }
                    }
                }
            }.environmentObject(languageManager)
            .onAppear {
                Publisher.refreshPlatforms(context: dataController.container.viewContext)
                
                Task {
                    if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                        print("Is searching for default....")
                        do {
                            try await GatewayClients.refresh(context: dataController.container.viewContext)
                        } catch {
                            print("Error refreshing gateways: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func getMeOut() {
        logoutAccount(context: dataController.container.viewContext)
        isLoggedIn = false
    }
    
    func validateLLT() {
        print("Validating LLT for continuation...")
        DispatchQueue.background(background: {
            do {
                let vault = Vault()
                let llt = try Vault.getLongLivedToken()
                if llt.isEmpty{
                    return
                }
                
                let result = try vault.validateLLT(
                    llt: llt,
                    context: dataController.container.viewContext
                )
                if !result {
                    alreadyLoggedIn = true
                } else {
                    let vault = Vault()
                    try vault.refreshStoredTokens(
                        llt: llt,
                        context: dataController.container.viewContext
                    )
                }
            } catch {
                print(error)
            }
        }, completion: {
            
        })
    }

    func getIsLoggedIn() -> Bool {
        do {
            isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print("Failed to check if llt exist: \(error)")
        }
        return false
    }
    
}


