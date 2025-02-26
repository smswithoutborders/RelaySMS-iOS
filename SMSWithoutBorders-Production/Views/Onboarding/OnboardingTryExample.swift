//
//  OnboardingTryExample.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 18/07/2024.
//

import SwiftUI

struct OnboardingTryExample: View {
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @State var shownStoredPlatforms = false
    @State var messagePlatformViewRequested = false
    @State var messagePlatformViewFromAccount: String = ""
    @State var messagePlatformViewPlatformName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Tab(buttonView:
                    Group {
                        Button {
                            shownStoredPlatforms = true
                        } label: {
                            Text("Try Example")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .padding(.bottom, 10)
                        .buttonStyle(.borderedProminent)
//                        .background(
//                            NavigationLink(destination: OfflineAvailablePlatformsSheetsView(),
//                                           isActive: $shownStoredPlatforms) {
//                                    EmptyView()
//                                }.hidden()
//                        )
                    },
                    title:"Send your first messages",
                    subTitle: "Learn how it works",
                    description: "Messages are shared with your default SMS messaging app which you use to send out SMS messages from your device",
                    imageName: "OnboardingTryExample",
                    subDescription: "Messages are encrypted meaning the messages will be scrambled - don't worry that's intended"
                )
            }
            
        }
    }
}

struct OnboardingTryExample_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return OnboardingTryExample()
            .environment(\.managedObjectContext, container.viewContext)
    }
}
