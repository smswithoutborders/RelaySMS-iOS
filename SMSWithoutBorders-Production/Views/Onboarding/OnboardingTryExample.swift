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
                if messagePlatformViewRequested {
                    NavigationLink(destination: MessagingView(
                        platformName: messagePlatformViewPlatformName,
                        fromAccount: messagePlatformViewFromAccount,
                        message: nil), isActive: $messagePlatformViewRequested) {
                        
                    }
                }
                else {
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
                            .sheet(isPresented: $shownStoredPlatforms) {
                                VStack {
                                    OfflineAvailablePlatformsSheetsView(
                                        messagePlatformViewRequested: $messagePlatformViewRequested,
                                        messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
                                        messagePlatformViewFromAccount: $messagePlatformViewFromAccount)
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
