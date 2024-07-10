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
            OnboardingIntroToVaults()
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
    @State var isFinished = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var navigatingFromURL: Bool = false
    
    @State var absoluteURLString: String = ""

    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished) {
                    ControllerView(isFinished: $isFinished)
                }
                else {
                    RecentsView()
                }
            }
            .environmentObject(appDelegate)
            .onOpenURL { url in
                // relaysms://oauth.afkanerd.com/platforms/gmail/protocols/oauth2/redirect_codes/ios/?state=RyPtoLjr9rr4LQvuVXsIIXaIWiIfQLxSYifjgRaAJmI&code=4%2F0ATx3LY7bQpsxfhHVpBR0sSMx0mAI3JWWykGphzsm3q-wfeRhdTcHqq12IXgxNy-XAnLMBA&scope=profile+openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile&authuser=0&prompt=consent
                
                print(url.query)
                let state = url.valueOf("state")
                let code = url.valueOf("code")
                print("state: \(state)\ncode: \(code)")
            }
        }
    }
}

#Preview {
    @State var isFinished = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    return ControllerView(isFinished: $isFinished)
}
