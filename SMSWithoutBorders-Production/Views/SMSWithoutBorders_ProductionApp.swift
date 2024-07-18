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
    
    @State private var onboadingViewIndex: Int = 0
    @State private var lastOnboardingView = false
    
    @Binding var codeVerifier: String
    
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
            OnboardingIntroToVaults(codeVerifier: $codeVerifier)
        default:
            OnboardingFinish(isFinished: $lastOnboardingView)
        }
        
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


@main
struct SMSWithoutBorders_ProductionApp: App {
    @StateObject private var dataController = DataController()
    
    @State var isFinished = false
    @State var navigatingFromURL: Bool = false
    @State var absoluteURLString: String = ""
    @State var codeVerifier: String = ""

    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished) {
                    ControllerView(isFinished: $isFinished, codeVerifier: $codeVerifier)
                }
                else {
                    RecentsView(codeVerifier: $codeVerifier)
                }
            }
            .onOpenURL { url in
                let state = url.valueOf("state")
                let code = url.valueOf("code")
                print("state: \(state)\ncode: \(code)\ncodeVerifier: \(codeVerifier)")
                
                do {
                    let llt = try Vault.getLongLivedToken()
                    let publisher = Publisher()
                    let response = try publisher.sendAuthorizationCode(
                        llt: llt, platform: state!, code: code!,
                        codeVerifier: codeVerifier)
                    
                    if(response.success) {
                        
                    }
                } catch {
                    print("An error occured sending code: \(error)")
                }
            }
        }
    }
}

#Preview {
    @State var isFinished = false
    @State var codeVerifier = ""
    
    return ControllerView(isFinished: $isFinished, codeVerifier: $codeVerifier)
}
