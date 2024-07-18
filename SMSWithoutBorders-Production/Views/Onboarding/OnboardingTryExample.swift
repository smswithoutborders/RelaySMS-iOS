//
//  OnboardingTryExample.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 18/07/2024.
//

import SwiftUI

struct OnboardingTryExample: View {
    @State var shownStoredPlatforms = false
    var body: some View {
        VStack {
            Tab(buttonView:
                Group {
                    Button("Try Example") {
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $shownStoredPlatforms) {
                        VStack {
                        }
                    }
                    .buttonStyle(.borderedProminent)
                },
                title:"Send your first messages",
                subTitle: "Learn how it works",
                description: "Messages are shared with your default SMS messaging app, which you can use to out SMS messages from your device",
                imageName: "OnboardingTryExample",
                subDescription: "Messages are encrypted, so the messages will scrambled - don't worry that's intended"
            )
        }
    }
}

#Preview {
    OnboardingTryExample()
}
