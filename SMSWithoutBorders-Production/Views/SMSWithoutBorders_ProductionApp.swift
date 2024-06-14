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
    @State private var onboadingViewIndex: Int = 0
    
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
            EmptyView()
        }
        
        if(self.onboadingViewIndex > 0) {
            Button("skip") {
                self.onboadingViewIndex += 1
            }.frame(alignment: .bottom)
                .padding()
        }
    }
}


@main
struct SMSWithoutBorders_ProductionApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                ControllerView()
            }
        }
    }
}

#Preview {
    ControllerView()
}
