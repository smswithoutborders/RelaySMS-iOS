//
//  RecentsViewLoggedIn.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 17/02/2025.
//

import SwiftUI
import SwiftUICore

@ViewBuilder
func getPlatformView(message: Messages, type: Publisher.ServiceTypes) -> some View {
    switch (type) {
    case .EMAIL:
        EmailPlatformView(message: message)
    case .TEXT:
        TextPlatformView(message: message)
    case .MESSAGE:
        MessagingView(
            platformName: message.platformName,
            message: message
        )
    default:
        EmptyView()
    }
}

struct SentMessages: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(
        keyPath: \MessageEntity.date,
        ascending: false)]
    ) var messages: FetchedResults<MessageEntity>

    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    @State var platformIsRequested = false
    
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: PlatformsRequestedType

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool
    @Binding var textIsRequested: Bool
    @Binding var messageIsRequested: Bool
    
    @Binding var requestedPlatformName: String
    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool


    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    List(messages, id: \.id) { message in
                        Card(
                            logo: getImageForPlatform(name: message.platformName!),
                            subject: message.subject!,
                            toAccount: message.toAccount!,
                            messageBody: message.body!,
                            date: Int(message.date)
                        )
                            .onTapGesture {
                                requestedMessage = Messages(
                                    subject: message.subject!,
                                    data: message.body!,
                                    fromAccount: message.fromAccount!,
                                    toAccount: message.toAccount!,
                                    platformName: message.platformName!,
                                    date: Int(message.date)
                                )
                                switch getServiceTypeForPlatform(name: message.platformName!) {
                                case Publisher.ServiceTypes.EMAIL.rawValue:
                                    emailIsRequested = true
                                    break
                                case Publisher.ServiceTypes.TEXT.rawValue:
                                    textIsRequested = true
                                    break
                                case Publisher.ServiceTypes.MESSAGE.rawValue:
                                    messageIsRequested = true
                                    break
                                default:
                                    print("No acceptable type")
                                    emailIsRequested = true
                                    break
                                }
                            }

                    }
                }

                VStack {

                    Button(action: {
                        platformRequestType = .compose
                        platformIsRequested.toggle()
                    }, label: {
                        Image(systemName: "square.and.pencil")
                            .frame(maxWidth: 48, maxHeight: 48)
                            .foregroundColor(Color.white)
                    })
                    .sheet(isPresented: $platformIsRequested) {
                        PlatformsView(
                            requestType: $platformRequestType,
                            requestedPlatformName: $requestedPlatformName,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            composeTextRequested: $composeTextRequested,
                            composeMessageRequested: $composeMessageRequested,
                            composeEmailRequested: $composeEmailRequested
                        ) {
                            platformIsRequested.toggle()
                        }
                    }
                    .background(Color("AccentColor"))
                    .cornerRadius(12.0)

                    Button(action: {
                        selectedTab = .platforms
                        platformRequestType = .available
                    }, label: {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .frame(maxWidth: 48, maxHeight: 48)
                            .foregroundColor(Color.white)
                    })
                    .background(Color("AccentColor"))
                    .cornerRadius(12.0)
                }
                .padding()
            }

        }
    }

    func getServiceTypeForPlatform(name: String) -> String {
        return platforms.filter {
            $0.name == name
        }
        .first?.service_type ?? Bridges.SERVICE_NAME
    }

//    
    func getImageForPlatform(name: String) -> Image {
        let image = platforms.filter {
            $0.name == name
        }
        .first?.image
        if image != nil {
            return Image(uiImage: UIImage(data: image!)!)
        }
        return Image("Logo")
    }
}


struct NoSentMessages: View {
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: PlatformsRequestedType

    @Binding var requestedPlatformName: String
    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool

    @State var platformIsRequested = false

    var body: some View {
        VStack {
            Spacer()
            Spacer()

            VStack {
                Image("5")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 20)
                Text("Send your first message...")
                    .font(RelayTypography.titleLarge)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
//                    selectedTab = .platforms
                    platformRequestType = .compose
                    platformIsRequested.toggle()
                } label: {
                    Text("Send new message")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.relayButton(variant: .primary))
                .sheet(isPresented: $platformIsRequested) {
                    PlatformsView(
                        requestType: $platformRequestType,
                        requestedPlatformName: $requestedPlatformName,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        composeTextRequested: $composeTextRequested,
                        composeMessageRequested: $composeMessageRequested,
                        composeEmailRequested: $composeEmailRequested
                    ) {
                        platformIsRequested.toggle()
                    }
                }

                Button {
                    selectedTab = .platforms
                    platformRequestType = .available
                } label: {
                    Text("Save platforms")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.relayButton(variant: .secondary))

            }
            .padding()
            .padding(.bottom, 32)
        }
    }
}

struct RecentsViewLoggedIn: View {
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
                    SentMessages(
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

#Preview {
    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: PlatformsRequestedType = .available
    @State var requestedMessage: Messages? = nil
    @State var emailIsRequested: Bool = false
    @State var textIsRequested: Bool = false
    @State var messageIsRequested: Bool = false
    @State var composeNewMessagesIsRequested: Bool = false
    @State var requestedPlatformName = "gmail"

    NoSentMessages(
        selectedTab: $selectedTab,
        platformRequestType: $platformRequestType,
        requestedPlatformName: $requestedPlatformName,
        composeNewMessageRequested: $composeNewMessagesIsRequested,
        composeTextRequested: $textIsRequested,
        composeMessageRequested: $messageIsRequested,
        composeEmailRequested: $emailIsRequested
    )
}

struct SentMessages_Preview: PreviewProvider {

    static var previews: some View {
        @State var selectedTab: HomepageTabs = .recents
        @State var platformRequestType: PlatformsRequestedType = .available

        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)


        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested: Bool = false
        @State var textIsRequested: Bool = false
        @State var messageIsRequested: Bool = false
        @State var requestedPlatformName = "gmail"
        @State var composeNewMessagesIsRequested: Bool = false

        return SentMessages(
            selectedTab: $selectedTab,
            platformRequestType: $platformRequestType,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested,
            textIsRequested: $textIsRequested,
            messageIsRequested: $messageIsRequested,
            requestedPlatformName: $requestedPlatformName,
            composeNewMessageRequested: $composeNewMessagesIsRequested,
            composeTextRequested: $textIsRequested,
            composeMessageRequested: $messageIsRequested,
            composeEmailRequested: $emailIsRequested
        ).environment(\.managedObjectContext, container.viewContext)
    }
}
