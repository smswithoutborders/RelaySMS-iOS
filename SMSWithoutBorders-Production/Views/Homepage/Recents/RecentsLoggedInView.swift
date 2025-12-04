//
//  RecentsLoggedInView.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 17/02/2025.
//

import SwiftUI
//import SwiftUICore

struct RecentsLoggedInView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>

    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: PlatformsRequestedType

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool
    @Binding var textIsRequested: Bool
    @Binding var messageIsRequested: Bool

    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool
    @Binding var requestedPlatformName: String

    var body: some View {
        NavigationView {
            VStack {
                if !messages.isEmpty {
                    SentMessagesList(
                        selectedTab: $selectedTab,
                        platformRequestType: $platformRequestType,
                        requestedMessage: $requestedMessage,
                        emailIsRequested: $emailIsRequested,
                        textIsRequested: $textIsRequested,
                        messageIsRequested: $messageIsRequested,
                        requestedPlatformName: $requestedPlatformName,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        composeTextRequested: $composeTextRequested,
                        composeMessageRequested: $composeMessageRequested,
                        composeEmailRequested: $composeEmailRequested
                    )
                } else {
                    NoSentMessages(
                        selectedTab: $selectedTab,
                        platformRequestType: $platformRequestType,
                        requestedPlatformName: $requestedPlatformName,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        composeTextRequested: $composeTextRequested,
                        composeMessageRequested: $composeMessageRequested,
                        composeEmailRequested: $composeEmailRequested
                    )
                }
            }
            .navigationTitle("Recents")
        }
    }
}

//#Preview {
//    @State var selectedTab: HomepageTabs = .recents
//    @State var platformRequestType: PlatformsRequestedType = .available
//    
//    RecentsViewLoggedIn(
//        selectedTab: $selectedTab,
//        platformRequestType: $platformRequestType
//    )
//}


