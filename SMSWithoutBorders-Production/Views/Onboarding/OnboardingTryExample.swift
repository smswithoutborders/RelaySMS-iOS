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

    var body: some View {
        VStack {
            Tab(buttonView:
                Group {
                    Button("Try Example") {
                        shownStoredPlatforms = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $shownStoredPlatforms) {
                        VStack {
                            OfflineAvailablePlatformsSheetsView()
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
        .task {
            for platform in storedPlatforms {
                print("platform.name: \(platform.name)")
                print("platform.account: \(platform.account)\n")
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
