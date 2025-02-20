//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

struct SavingNewPlatformView: View {
    var name: String
    
    @Binding var isSaving: Bool
    
    @State var isAnimating = false

    var body: some View {
        VStack {
            if(isSaving) {
                Text("Saving new account for \(name)...")
                    .padding()
                    .scaleEffect(isAnimating ? 1.0 : 1.2)
                    .onAppear() {
                        withAnimation(
                            .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                        ) {
                            isAnimating = true
                        }
                    }

            }
            ProgressView()
        }
    }
}

struct PlatformSheetView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    var description: String
    
    @State var loading = false
    @State var savingNewPlatform = false
    @State var failed: Bool = false
    @State var phoneNumberAuthenticationRequested: Bool = false
    @State var sheetComposeNewPresented = false

    @State var errorMessage: String = ""

    var platform: PlatformsEntity?
    @State private var codeVerifier: String = ""
    
    @Binding var parentIsEnabled: Bool
    @Binding var composeNewMessageRequested: Bool

    init(
        description: String,
        platform: PlatformsEntity?,
        isEnabled: Binding<Bool>,
        composeNewMessageRequested: Binding<Bool>
    ) {
        self.description = description
        self.platform = platform
        
        _parentIsEnabled = isEnabled
        _composeNewMessageRequested = composeNewMessageRequested
    }
    
    var body: some View {
        VStack {
            if loading && platform != nil {
                SavingNewPlatformView(
                    name: platform!.name!,
                    isSaving: $savingNewPlatform
                )
            } else {
                VStack(alignment:.center) {
                    (platform != nil && platform!.image != nil ?
                     Image(uiImage: UIImage(data: platform!.image!)!) : Image("Logo")
                    )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding()
                    
                    Text(description)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                    
                    if phoneNumberAuthenticationRequested {
                        PhoneNumberSheetView(
                            completed: $parentIsEnabled,
                            platformName: platform!.name!
                        )
                    }
                    else {
                        Button {
                            if(platform != nil) {
                                triggerPlatformRequest(platform: platform!)
                            } else {
                                composeNewMessageRequested.toggle()
                                dismiss()
                            }
                        } label: {
                            if platform == nil {
                                Text("Send new message")
                                    .frame(maxWidth: .infinity, maxHeight: 35)
                            } else {
                                Text("Add Account")
                                    .frame(maxWidth: .infinity, maxHeight: 35)
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding()

                    }
                }

            }
        }
        .onOpenURL { url in
            print("Received new url: \(url)")
            DispatchQueue.background(background: {
                savingNewPlatform = true
                do {
                    try Publisher.processIncomingUrls(
                        context: context,
                        url: url,
                        codeVerifier: codeVerifier
                    )
                    parentIsEnabled = true
                } catch {
                    print(error)
                    failed = true
                    errorMessage = error.localizedDescription
                }
            }, completion: {
                loading = false
                dismiss()
            })
        }
        .alert(isPresented: $failed) {
            Alert(
                title: Text("Error! You did nothing wrong..."),
                message: Text(errorMessage),
                dismissButton: .default(Text("Not my fault!"))
            )
        }
    }
    
    private func triggerPlatformRequest(platform: PlatformsEntity) {
        let backgroundQueueu = DispatchQueue(label: "addingNewPlatformQueue", qos: .background)
        
        switch platform.protocol_type {
        case Publisher.ProtocolTypes.OAUTH2.rawValue:
            loading = true
            backgroundQueueu.async {
                do {
                    let publisher = Publisher()
                    let response = try publisher.getOAuthURL(
                        platform: platform.name!,
                        supportsUrlSchemes: platform.support_url_scheme)
                    codeVerifier = response.codeVerifier
                    openURL(URL(string: response.authorizationURL)!)
                }
                catch {
                    print("Some error occured: \(error)")
                }
            }
        case Publisher.ProtocolTypes.PNBA.rawValue:
            phoneNumberAuthenticationRequested = true
        case .none:
            Task {}
        case .some(_):
            Task {}
        }
    }
}

struct PlatformCard: View {
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(
            key: "name",
            ascending: false,
            selector: #selector(NSString.localizedStandardCompare))]
    ) var storedPlatforms: FetchedResults<StoredPlatformsEntity>


    @State var sheetIsPresented: Bool = false
    @State var isEnabled: Bool = false
    
    @Binding var composeNewMessageRequested: Bool

    let platform: PlatformsEntity?
    let protocolType: Publisher.ProtocolTypes

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Button(action: {
                        sheetIsPresented.toggle()
                    }) {
                        VStack {
                            (platform != nil && platform!.image != nil ?
                             Image(uiImage: UIImage(data: platform!.image!)!) : Image("Logo")
                            )
                                .resizable()
                                .renderingMode(isEnabled ? .none : .template)
                                .foregroundColor(isEnabled ? .clear : .gray)
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                                .padding()

                            Text(platform != nil ? (platform!.name ?? "") : "")
                                .font(.caption2)
                                .foregroundColor(isEnabled ? .primary : .gray)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(isEnabled ? .accentColor : .gray)
                    .sheet(isPresented: $sheetIsPresented) {
                        PlatformSheetView(
                            description: getProtocolDescription( protocolType: protocolType),
                            platform: platform,
                            isEnabled: $isEnabled,
                            composeNewMessageRequested: $composeNewMessageRequested
                        ).applyPresentationDetentsIfAvailable()
                    }
                }
                if(isEnabled) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 50, y: -50)
                }
            }
        }
        .onAppear {
            isEnabled = platform != nil ? isStored(platformEntity: platform!) : true
        }
    }
    
    func getProtocolDescription(protocolType: Publisher.ProtocolTypes) -> String {
        switch(protocolType) {
        case .BRIDGE:
            return Publisher.ProtocolDescriptions.BRIDGE.rawValue
        case .OAUTH2:
            return Publisher.ProtocolDescriptions.OAUTH2.rawValue
        case .PNBA:
            return Publisher.ProtocolDescriptions.PNBA.rawValue
        }
    }
    
    func isStored(platformEntity: PlatformsEntity) -> Bool {
        return storedPlatforms.contains(where: { $0.name == platformEntity.name })
    }

}

enum RequestType: CaseIterable {
    case available
    case compose
    case revoke
}

struct PlatformsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(
            key: "name",
            ascending: true,
            selector: #selector(NSString.localizedStandardCompare))]
    ) var platforms: FetchedResults<PlatformsEntity>
    
    @State private var sheetIsRequested: Bool = false
    @State private var platformsSheetIsRequested: Bool = false
    
    @Binding var requestType: RequestType
    @Binding var composeNewMessageRequested: Bool

    let columns = [
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Use your RelaySMS account")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                    
                    PlatformCard(
                        isEnabled: true,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        platform: nil,
                        protocolType: Publisher.ProtocolTypes.BRIDGE
                    ).padding(.bottom, 32)

                    Text("Use your online accounts")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(platforms, id: \.name) { item in
                            PlatformCard(
                                composeNewMessageRequested: $composeNewMessageRequested,
                                platform: item,
                                protocolType: getProtocolType(type: item.protocol_type!)
                            )
                        }
                    }
                    
                }
            }
            .navigationTitle(getRequestTypeText(type: requestType))
            .padding(16)
        }
    }
    
    func getRequestTypeText(type: RequestType) -> String {
        switch(type) {
        case .compose:
            return "Send a message"
        case .revoke:
            return "Remove a platform"
        default:
            return "Available Platforms"
        }
    }
    
    
    func getProtocolType(type: String) -> Publisher.ProtocolTypes {
        switch(type) {
        case Publisher.ProtocolTypes.OAUTH2.rawValue:
            return Publisher.ProtocolTypes.OAUTH2
            
        case Publisher.ProtocolTypes.PNBA.rawValue:
            return Publisher.ProtocolTypes.PNBA
            
        default:
            return Publisher.ProtocolTypes.BRIDGE
        }
    }
    
    
}

#Preview {
    @State var savingPlatform = true
    SavingNewPlatformView(
        name: "RelaySMS",
        isSaving: $savingPlatform
    )
}

#Preview {
    var description = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book"
    @State var saveRequested = false
    @State var codeVerifier: String = ""
    @State var isEnabled: Bool = false
    @State var composeNewMessage: Bool = false

    PlatformSheetView(
        description: description,
        platform: nil,
        isEnabled: $isEnabled,
        composeNewMessageRequested: $composeNewMessage
    )
}

struct Platforms_Preview: PreviewProvider {
    static var previews: some View {
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var platformRequestType: RequestType = .available
        @State var composeNewMessage: Bool = false
        return PlatformsView(
            requestType: $platformRequestType,
            composeNewMessageRequested: $composeNewMessage
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}

struct PlatformCardDisabled_Preview: PreviewProvider {
    
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        @State var composeNewMessage: Bool = false

        PlatformCard(
            isEnabled: true,
            composeNewMessageRequested: $composeNewMessage,
            platform: nil,
            protocolType: Publisher.ProtocolTypes.BRIDGE
        )
    }
}

struct PlatformCardEnabled_Preview: PreviewProvider {
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        @State var composeNewMessage: Bool = false

        PlatformCard(
            isEnabled: false,
            composeNewMessageRequested: $composeNewMessage,
            platform: nil,
            protocolType: Publisher.ProtocolTypes.BRIDGE
        )
    }
}
