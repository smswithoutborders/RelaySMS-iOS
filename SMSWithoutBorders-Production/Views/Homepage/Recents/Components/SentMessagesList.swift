//
//  SentMessagesList.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct SentMessagesList: View {
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
                        MessageCard(
                            logo: getImageForPlatform(name: message.platformName ?? "unknown"),
                            subject: message.subject ?? "unknown",
                            toAccount: message.toAccount ?? "unknown",
                            messageBody: message.body ?? "unknown",
                            date: Int(message.date)
                        )
                            .onTapGesture {
                                requestedMessage = Messages(
                                    id: message.id!,
                                    subject: message.subject ?? "unknown",
                                    data: message.body ?? "unknown",
                                    fromAccount: message.fromAccount ?? "unknown",
                                    toAccount: message.toAccount ?? "unknown",
                                    platformName: message.platformName ?? "unknown",
                                    date: Int(message.date),
                                    image: message.rawImage == nil ? nil : [UInt8](Data(base64Encoded: message.rawImage!)!)
                                )
                                switch getServiceTypeForPlatform(name: message.platformName ?? "unknown") {
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

struct SentMessagesList_Preview: PreviewProvider {
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

        return SentMessagesList(
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
