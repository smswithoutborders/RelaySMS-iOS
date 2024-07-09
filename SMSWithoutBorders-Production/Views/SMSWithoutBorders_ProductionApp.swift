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
        }
    }
}

#Preview {
    @State var isFinished = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    return ControllerView(isFinished: $isFinished)
}
