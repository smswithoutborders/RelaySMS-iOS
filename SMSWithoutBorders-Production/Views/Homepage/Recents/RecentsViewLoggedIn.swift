//
//  RecentsViewLoggedIn.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 17/02/2025.
//

import SwiftUI

@ViewBuilder
func getPlatformView(message: Messages, type: Publisher.ServiceTypes) -> some View {
    switch(type){
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
    
    
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: PlatformsRequestedType
    
    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool
    @Binding var textIsRequested: Bool
    @Binding var messageIsRequested: Bool
    

    var body : some View {
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
                                break
                            }
                        }
                        
                    }
                }
                
                VStack {
                    VStack {
                        Button(action: {
                            selectedTab = .platforms
                            platformRequestType = .compose
                        }, label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(.title))
                                .frame(width: 57, height: 50)
                                .foregroundColor(Color.white)
                                .padding(.bottom, 7)
                        })
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.3),
    
                                radius: 3,
                                x: 3,
                                y: 3)
    
                    }
    
                    VStack {
                        Button(action: {
                            selectedTab = .platforms
                            platformRequestType = .available
                        }, label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(.title))
                                .frame(width: 57, height: 50)
                                .foregroundColor(Color.white)
                                .padding(.bottom, 7)
                        })
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.3),
                                radius: 3,
                                x: 3,
                                y: 3)
                    }
                }
                .padding()
            }
            
        }
    }
    
    func getServiceTypeForPlatform(name: String) -> String {
        return platforms.filter { $0.name == name }.first?.service_type ?? ""
    }
//    
    func getImageForPlatform(name: String) -> Image {
        let image = platforms.filter { $0.name == name}.first?.image
        if image != nil {
            return Image( uiImage: UIImage(data: image!)!)
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
            
            VStack {
                Image("NoRecents")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 20)
                Text("No recent messages")
            }
            
            Spacer()

            VStack {
                Button {
//                    selectedTab = .platforms
                    platformRequestType = .compose
                    platformIsRequested.toggle()
                } label: {
                    Text("Send new message")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 10)
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
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundStyle(.secondary)
                
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
                        messageIsRequested: $messageIsRequested
                    )
                }
                else {
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

        return SentMessages(
            selectedTab: $selectedTab,
            platformRequestType: $platformRequestType,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested,
            textIsRequested: $textIsRequested,
            messageIsRequested: $messageIsRequested
        ).environment(\.managedObjectContext, container.viewContext)
    }
}
