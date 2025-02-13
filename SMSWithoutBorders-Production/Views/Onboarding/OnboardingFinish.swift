//
//  OnboardingFinish.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

struct OnboardingFinish: View {
    @Binding var lastOnboardingView: Bool
    
    var body: some View {
        VStack {
            Tab(buttonView: EmptyView(),
                title: String(localized:"You are ready!"),
                subTitle: String(localized: "Come back anytime"),
                description: String(localized: "You are ready to begin sending messages from you added platforms.", comment: "Explains that you can start sending messages from you added platforms."),
                imageName: "OnboardingAddAccountExample",
                subDescription: String(localized:"You can add platforms from the homepage once you are logged in", comment: "Explains that you can add platforms from the homepage once you are logged in")
            )
        }
        .padding()
        .task {
            lastOnboardingView = true
        }
    }
}

#Preview {
    @State var isFinished = false
    return OnboardingFinish(lastOnboardingView: $isFinished)
}
