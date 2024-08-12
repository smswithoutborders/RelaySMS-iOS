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
                title: "You are ready!",
                subTitle: "Come back anytime",
                description: "You can now add accounts to the Vault at anytime from within the App.",
                imageName: "OnboardingAddAccountExample",
                subDescription: "Add accounts from your homepage, once you are logged into your Vault account"
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
