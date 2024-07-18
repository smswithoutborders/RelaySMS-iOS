//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData

struct ControllerView: View {
    @Binding var isFinished: Bool
    
    @Binding var onboadingViewIndex: Int
    @State private var lastOnboardingView = false
    
    @Binding var codeVerifier: String
    @Binding var backgroundLoading: Bool
    
    var body: some View {
        switch self.onboadingViewIndex {
        case ...0:
            OnboardingWelcomeView()
            VStack {
                Button("Get started!") {
                    self.onboadingViewIndex += 1
                }
                .buttonStyle(.borderedProminent)
                .padding()
                Link("Read our privacy policy", destination: URL(string:"https://smswithoutborders.com/privacy-policy")!)
                    .font(.caption)
            }
        case 1:
            OnboardingIntroToVaults(codeVerifier: $codeVerifier,
                                    backgroundLoading: $backgroundLoading)
        default:
            OnboardingFinish(isFinished: $lastOnboardingView)
        }
        
        if(!backgroundLoading) {
            HStack {
                if(self.onboadingViewIndex > 0) {
                    if(!lastOnboardingView) {
                        Button("skip") {
                            self.onboadingViewIndex += 1
                        }.frame(alignment: .bottom)
                            .padding()
                    } else {
                        Button("Finish") {
                            isFinished = true
                        }.buttonStyle(.borderedProminent)
                            .padding()
                    }
                }
                
            }.padding()
        }
    }
}


@main
struct SMSWithoutBorders_ProductionApp: App {
    @StateObject private var dataController = DataController()
    
    @State var isFinished = false
    @State var navigatingFromURL: Bool = false
    @State var absoluteURLString: String = ""
    @State var codeVerifier: String = ""
    
    @State var backgroundLoading: Bool = false
    @State private var onboardingViewIndex: Int = 0

    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished) {
                    ControllerView(isFinished: $isFinished,
                                   onboadingViewIndex: $onboardingViewIndex,
                                   codeVerifier: $codeVerifier,
                                   backgroundLoading: $backgroundLoading)
                }
                else {
                    RecentsView(codeVerifier: $codeVerifier)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                }
            }
            .onOpenURL { url in
                let state = url.valueOf("state")
                let code = url.valueOf("code")
                print("state: \(state)\ncode: \(code)\ncodeVerifier: \(codeVerifier)")
                
                do {
                    let llt = try Vault.getLongLivedToken()
                    let publisher = Publisher()
                    
                    backgroundLoading = true
                    
                    let response = try publisher.sendAuthorizationCode(
                        llt: llt,
                        platform: state!,
                        code: code!,
                        codeVerifier: codeVerifier)
                    
                    if(response.success) {
                        onboardingViewIndex += 1
                    }
                } catch {
                    print("An error occured sending code: \(error)")
                }
                backgroundLoading = false
            }
        }
    }
}

#Preview {
    @State var isFinished = false
    @State var codeVerifier = ""
    @State var onboardingIndex = 0
    @State var isBackgroundLoading: Bool = true
    
    ControllerView(isFinished: $isFinished,
                   onboadingViewIndex: $onboardingIndex,
                   codeVerifier: $codeVerifier,
                   backgroundLoading: $isBackgroundLoading)
}
