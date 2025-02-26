//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

struct SavingRevokingNewPlatformView: View {
    var name: String
    
    @Binding var isSaving: Bool
    @Binding var isRevoking: Bool

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
            else if(isRevoking) {
                Text("Revoking account for \(name)...")
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
    var composeDescription: String

    @State var loading = false
    @State var isRevoking = false
    @State var savingNewPlatform = false
    @State var failed: Bool = false
    @State var phoneNumberAuthenticationRequested: Bool = false
    @State var sheetComposeNewPresented = false
    @State var accountSheetRequested = false
    @State var revokeConfirmSheetRequested = false

    @State var errorMessage: String = ""

    var platform: PlatformsEntity?
    @State private var codeVerifier: String = ""
    @State private var fromAccount: String = ""

    @Binding var parentIsEnabled: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var platformRequestedType: PlatformsRequestedType
    @Binding var composeViewRequested: Bool
    @Binding var refreshParent: Bool

    init(
        description: String,
        composeDescription: String,
        platform: PlatformsEntity?,
        isEnabled: Binding<Bool>,
        composeNewMessageRequested: Binding<Bool>,
        platformRequestedType: Binding<PlatformsRequestedType>,
        composeViewRequested: Binding<Bool>,
        refreshParent: Binding<Bool>
    ) {
        self.description = description
        self.composeDescription = composeDescription
        self.platform = platform
        
        _parentIsEnabled = isEnabled
        _composeNewMessageRequested = composeNewMessageRequested
        _platformRequestedType = platformRequestedType
        _composeViewRequested = composeViewRequested
        _refreshParent = refreshParent
    }
    
    var body: some View {
        VStack {
            if (isRevoking || loading) && platform != nil {
                SavingRevokingNewPlatformView(
                    name: platform!.name!,
                    isSaving: $savingNewPlatform,
                    isRevoking: $isRevoking
                )
            }
            else if accountSheetRequested && platform != nil {
                AccountSheetView(
                    filter: platform!.name!,
                    fromAccount: $fromAccount,
                    dismissParent: $parentIsEnabled
                ) {
                    revokeConfirmSheetRequested.toggle()
                }
                .confirmationDialog(String("Revoke?"), isPresented: $revokeConfirmSheetRequested) {
                    Button("Revoke", role: .destructive) {
                        isRevoking = true
//                        accountSheetRequested = false
                        
                        let backgroundQueueu = DispatchQueue(label: "revokeAccountQueue", qos: .background)
                        backgroundQueueu.async {
                            do {
                                let llt = try Vault.getLongLivedToken()
                                let publisher = Publisher()
                                let response = try publisher.revokePlatform(
                                    llt: llt,
                                    platform: platform!.name!,
                                    account: fromAccount,
                                    protocolType: platform!.protocol_type!
                                )

                                if response {
                                    let vault = Vault()
                                    do {
                                        let llt = try Vault.getLongLivedToken()
                                        try vault.refreshStoredTokens(
                                            llt: llt,
                                            context: context
                                        )
                                    } catch {
                                        print(error)
                                    }
                                }

                                DispatchQueue.main.async {
                                    isRevoking = false
                                    refreshParent.toggle()
                                    dismiss()
                                }
                            } catch {
                                print("Error revoking: \(error)")
                            }
                        }
                    }
                } message: {
                    Text("Revoking removes the ability to send messages from this account. You can store the acocunt again at anytime.")
                }
            }
            else {
                VStack(alignment:.center) {
                    (platform != nil && platform!.image != nil ?
                     Image(uiImage: UIImage(data: platform!.image!)!) : Image("Logo")
                    )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding()
                    
                    if platformRequestedType == .compose {
                        Text(composeDescription)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        Text(description)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
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
                                if platformRequestedType == .compose {
                                    composeViewRequested.toggle()
                                    dismiss()
                                }
                                else {
                                    triggerPlatformRequest(platform: platform!)
                                }
                            } else {
                                composeNewMessageRequested.toggle()
                                dismiss()
                            }
                        } label: {
                            if platform == nil || platformRequestedType == .compose {
                                Text("Send new message")
                                    .frame(maxWidth: .infinity, maxHeight: 35)
                            } else {
                                Text("Add Account")
                                    .frame(maxWidth: .infinity, maxHeight: 35)
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding()
                        
                        if platform != nil && platformRequestedType == .available && parentIsEnabled {
                            Button("Remove Accounts", role: .destructive) {
                                accountSheetRequested = true
                            }
                        }
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
                    dismiss()
                } catch {
                    print(error)
                    failed = true
                    errorMessage = error.localizedDescription
                }
            }, completion: {
                loading = false
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
    @Binding var platformRequestType: PlatformsRequestedType
    @Binding var composeViewRequested: Bool
    @Binding var parentRefreshRequested: Bool
    @Binding var requestedPlatformName: String

    let platform: PlatformsEntity?
    let protocolType: Publisher.ProtocolTypes

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Button(action: {
                        if platform != nil {
                            requestedPlatformName = platform!.name!
                        }
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
                            description: getProtocolDescription(protocolType: protocolType),
                            composeDescription: "",
                            platform: platform,
                            isEnabled: $isEnabled,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            platformRequestedType: $platformRequestType,
                            composeViewRequested: $composeViewRequested,
                            refreshParent: $parentRefreshRequested
                        )
                        .applyPresentationDetentsIfAvailable(
                            canLarge: platform?.protocol_type == Publisher.ProtocolTypes.PNBA.rawValue)
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

enum PlatformsRequestedType: CaseIterable {
    case available
    case compose
    case revoke
}

struct PlatformsView: View {
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(
            key: "name",
            ascending: true,
            selector: #selector(NSString.localizedStandardCompare))]
    ) var platforms: FetchedResults<PlatformsEntity>
    
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    
    @State private var id = UUID()
    @State private var refreshRequested = false

    @Binding var requestType: PlatformsRequestedType
    @Binding var requestedPlatformName: String
    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool

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
                        platformRequestType: $requestType,
                        composeViewRequested: getBindingComposeVariable(type: "email"),
                        parentRefreshRequested: $refreshRequested,
                        requestedPlatformName: $requestedPlatformName,
                        platform: nil,
                        protocolType: Publisher.ProtocolTypes.BRIDGE
                    ).padding(.bottom, 32)

                    HStack {
                        Text("Use your online accounts")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 10)
                    }
                    
                    if platforms.isEmpty {
                        Text("No online platforms saved yet...")
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                            if requestType == .compose {
                                ForEach(filterForStoredPlatforms(), id: \.name) { item in
                                    PlatformCard(
                                        composeNewMessageRequested: $composeNewMessageRequested,
                                        platformRequestType: $requestType,
                                        composeViewRequested: getBindingComposeVariable(
                                            type: item.service_type!),
                                        parentRefreshRequested: $refreshRequested,
                                        requestedPlatformName: $requestedPlatformName,
                                        platform: item,
                                        protocolType: getProtocolType(type: item.protocol_type!)
                                    )
                                }
                            }
                            else {
                                ForEach(platforms, id: \.name) { item in
                                    PlatformCard(
                                        composeNewMessageRequested: $composeNewMessageRequested,
                                        platformRequestType: $requestType,
                                        composeViewRequested: getBindingComposeVariable(
                                            type: item.service_type!),
                                        parentRefreshRequested: $refreshRequested,
                                        requestedPlatformName: $requestedPlatformName,
                                        platform: item,
                                        protocolType: getProtocolType(type: item.protocol_type!)
                                    )
                                }
                            }
                        }
                    }
                    
                }
                .id(id)
                .onChange(of: refreshRequested) { refresh in
                    if refresh {
                        id = UUID()
                    }
                }
                
                VStack(alignment: .center) {
                    Button {
                        requestType = requestType == .compose ? .available : .compose
                    } label: {
                        if requestType == .compose {
                            Text("Save more platforms...")
                        } else {
                            Text("Send new message...")
                        }
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle(getRequestTypeText(type: requestType))
            .padding(16)
        }
        .task {
            print("Number of platforms: \(platforms.count)")
        }
    }
    
    func filterForStoredPlatforms() -> [PlatformsEntity] {
        var _storedPlatforms: Set<PlatformsEntity> = []
        
        for platform in platforms {
            if storedPlatforms.contains(where: { $0.name == platform.name }) {
                _storedPlatforms.insert(platform)
            }
        }
        return Array(_storedPlatforms)
    }
    
    func getBindingComposeVariable(type: String) -> Binding<Bool> {
        @State var defaultNil : Bool? = false
        switch(type) {
        case Publisher.ServiceTypes.EMAIL.rawValue:
            return $composeEmailRequested
        case Publisher.ServiceTypes.MESSAGE.rawValue:
            return $composeMessageRequested
        case Publisher.ServiceTypes.TEXT.rawValue:
            return $composeTextRequested
        default:
            return $composeEmailRequested
        }
    }
    
    func getRequestTypeText(type: PlatformsRequestedType) -> String {
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
struct Platforms_Preview: PreviewProvider {
    static var previews: some View {
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var requestedFromAccount: String? = "example@gmail.com"
        @State var requestedPlatformName: String = "gmail"
        
        @State var platformRequestType: PlatformsRequestedType = .available
        @State var composeNewMessage: Bool = false
        @State var composeTextRequested: Bool = false
        @State var composeMessageRequested: Bool = false
        @State var composeEmailRequested: Bool = false
        return PlatformsView(
            requestType: $platformRequestType,
            requestedPlatformName: $requestedPlatformName,
            composeNewMessageRequested: $composeNewMessage,
            composeTextRequested: $composeTextRequested,
            composeMessageRequested: $composeMessageRequested,
            composeEmailRequested: $composeEmailRequested
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}

struct PlatformsCompose_Preview: PreviewProvider {
    static var previews: some View {
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var requestedPlatformName: String = "gmail"
        @State var platformRequestType: PlatformsRequestedType = .compose
        @State var composeNewMessage: Bool = false
        @State var composeTextRequested: Bool = false
        @State var composeMessageRequested: Bool = false
        @State var composeEmailRequested: Bool = false
        @State var requestedFromAccount: String? = "example@gmail.com"
        return PlatformsView(
            requestType: $platformRequestType,
            requestedPlatformName: $requestedPlatformName,
            composeNewMessageRequested: $composeNewMessage,
            composeTextRequested: $composeTextRequested,
            composeMessageRequested: $composeMessageRequested,
            composeEmailRequested: $composeEmailRequested
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}

#Preview {
    var description = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book"
    var composeDescription = "[Compose] Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book"
    
    @State var saveRequested = false
    @State var codeVerifier: String = ""
    @State var isEnabled: Bool = false
    @State var composeNewMessage: Bool = false
    @State var composeViewRequested: Bool = false
    @State var platformRequestedType: PlatformsRequestedType = .available

    PlatformSheetView(
        description: description,
        composeDescription: composeDescription,
        platform: nil,
        isEnabled: $isEnabled,
        composeNewMessageRequested: $composeNewMessage,
        platformRequestedType: $platformRequestedType,
        composeViewRequested: $composeViewRequested,
        refreshParent: $isEnabled
    )
}

struct PlatformCardDisabled_Preview: PreviewProvider {
    
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        @State var parentRefreshRequested: Bool = false
        @State var composeNewMessage: Bool = false
        @State var composeViewRequested: Bool = false
        @State var platformRequestedType: PlatformsRequestedType = .available
        @State var requestedPlatformName: String = "gmail"

        PlatformCard(
            isEnabled: true,
            composeNewMessageRequested: $composeNewMessage,
            platformRequestType: $platformRequestedType,
            composeViewRequested: $composeViewRequested,
            parentRefreshRequested: $parentRefreshRequested,
            requestedPlatformName: $requestedPlatformName,
            platform: nil,
            protocolType: Publisher.ProtocolTypes.BRIDGE
        )
    }
}


struct PlatformCardEnabled_Preview: PreviewProvider {
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        @State var parentRefreshRequested: Bool = false
        @State var composeNewMessage: Bool = false
        @State var composeViewRequested: Bool = false
        @State var platformRequestedType: PlatformsRequestedType = .available
        
        @State var requestedPlatformName: String = "gmail"

        PlatformCard(
            isEnabled: false,
            composeNewMessageRequested: $composeNewMessage,
            platformRequestType: $platformRequestedType,
            composeViewRequested: $composeViewRequested,
            parentRefreshRequested: $parentRefreshRequested,
            requestedPlatformName: $requestedPlatformName,
            platform: nil,
            protocolType: Publisher.ProtocolTypes.BRIDGE
        )
    }
}

#Preview {
    @State var savingPlatform = true
    @State var isRevoking = false
    SavingRevokingNewPlatformView(
        name: "RelaySMS",
        isSaving: $savingPlatform,
        isRevoking: $isRevoking
    )
}

