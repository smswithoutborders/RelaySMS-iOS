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
    
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    
    @State var requestedMessage: Messages?
    
    @State var emailIsRequested: Bool = false
    @State var textIsRequested: Bool = false
    @State var messageIsRequested: Bool = false

    init() {
        _platforms = FetchRequest(entity: PlatformsEntity.entity(), sortDescriptors: [])
    }
    
    var body : some View {
        VStack {
            VStack {
                if requestedMessage != nil {
                    NavigationLink(
                        destination: EmailPlatformView(message: requestedMessage!),
                        isActive: $emailIsRequested
                    ) {
                        EmptyView()
                    }
                    
                    NavigationLink(
                        destination: TextPlatformView(message: requestedMessage!),
                        isActive: $textIsRequested
                    ) {
                        EmptyView()
                    }
                    
                    NavigationLink(
                        destination: MessagingView(
                            platformName: requestedMessage!.platformName,
                            message: requestedMessage!
                        ),
                        isActive: $messageIsRequested
                    ) {
                        EmptyView()
                    }
                }
            }
            
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    List(messages, id: \.self) { message in
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
                        }, label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(.title))
                                .frame(width: 57, height: 50)
                                .foregroundColor(Color.white)
                                .padding(.bottom, 7)
                        })
                        .background(Color.blue)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.3),
    
                                radius: 3,
                                x: 3,
                                y: 3)
    
                    }
    
                    VStack {
                        Button(action: {
                        }, label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(.title))
                                .frame(width: 57, height: 50)
                                .foregroundColor(Color.white)
                                .padding(.bottom, 7)
                        })
                        .background(Color.blue)
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
                    selectedTab = .platforms
                    platformRequestType = .compose
                } label: {
                    Text("Send new message")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 10)
                
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
                
            }
            .padding()
            .padding(.bottom, 32)
        }
    }
}

struct RecentsViewLoggedIn: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: PlatformsRequestedType
    
    var body: some View {
        NavigationView {
            VStack {
                NoSentMessages(
                    selectedTab: $selectedTab,
                    platformRequestType: $platformRequestType
                )
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
    
    NoSentMessages(
        selectedTab: $selectedTab,
        platformRequestType: $platformRequestType
    )
}

struct SentMessages_Preview: PreviewProvider {

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return SentMessages()
            .environment(\.managedObjectContext, container.viewContext)
    }
}
