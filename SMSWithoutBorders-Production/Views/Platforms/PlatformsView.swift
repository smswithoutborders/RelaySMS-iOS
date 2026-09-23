//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

enum PlatformsRequestedType: CaseIterable {
    case available
    case compose
    case revoke
}

struct PlatformsView: View {
    @Environment(\.managedObjectContext) var context

    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(
            keyPath: \PlatformsEntity.name,
            ascending: true)
    ]
    ) var platforms: FetchedResults<PlatformsEntity>

    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(
            keyPath: \StoredPlatformsEntity.name,
            ascending: true)
    ]
    ) var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    @State private var publishablePlatforms: [StoredPlatformsEntity] = []
    @State private var isRefreshing = false
    @State private var hasInitiallyLoaded = false

    @Binding var requestType: PlatformsRequestedType
    @Binding var requestedPlatformName: String
    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool

    var callback: (() -> Void)?

    let columns = [
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Use your RelaySMS account")
                        .font(RelayTypography.titleSmall)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)

                    PlatformCard(
                        isEnabled: true,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        platformRequestType: $requestType,
                        composeViewRequested: getBindingComposeVariable(
                            type: "email"),
                        parentRefreshRequested: .constant(false),
                        requestedPlatformName: $requestedPlatformName,
                        platform: nil,
                        serviceType: Publisher.ServiceTypes.BRIDGE,
                        callback: callback
                    ).padding(.bottom, 32)

                    HStack {
                        Text("Use your online accounts")
                            .font(RelayTypography.titleSmall)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 10)
                    }
                    
                    if isRefreshing {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading Platforms...")
                                .font(RelayTypography.bodyMedium)
                        }.frame(maxWidth: .infinity)
                            .padding()
                    } else if requestType == .compose && publishablePlatforms.isEmpty {
                        VStack(alignment: .center) {
                            Spacer().frame(height: 32)
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 64))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    RelayColors.colorScheme.primary)
                            Text(
                                "No online platforms saved yet... You can save more platforms below"
                            ).padding(16)
                                .multilineTextAlignment(.center)
                                .frame(alignment: Alignment.center)
                        }

                    } else if platforms.isEmpty && !isRefreshing {
                        VStack(alignment: .center, spacing: 16) {
                            Text("No online platforms saved yet...")
                                .font(RelayTypography.bodyMedium)
                                .multilineTextAlignment(.center).frame(
                                alignment: Alignment.center)
                            Button("Load Platforms") {
                                refreshPlatforms()
                            }.buttonStyle(.relayButton(variant: .text))
                                .frame(
                                alignment: .center)
                        }

                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 20
                        ) {
                            if requestType == .compose {
                                ForEach(filterForStoredPlatforms(), id: \.objectID) { item in
                                    createPlatformCard(for: item)
                                }
                            } else {
                                ForEach(platforms, id: \.objectID) { item in
                                    createPlatformCard(for: item)
                                }
                            }
                        }
                    }

                }.padding([.leading, .trailing], 16)

                Button {
                    requestType =
                        requestType == .compose ? .available : .compose
                } label: {
                    if requestType == .compose {
                        Text("Save more platforms...")
                    } else {
                        Text("Send new message...")
                    }
                }.buttonStyle(.relayButton(variant: .secondary))
                    .padding([.leading, .trailing], 16)
                    .padding([.top, .bottom], 32)

            }
            .navigationTitle(getRequestTypeText(type: requestType))
        }.onAppear {
            
            if !hasInitiallyLoaded {
                hasInitiallyLoaded = true
                
                if platforms.isEmpty {
                    refreshPlatforms()
                } else {
                    getPublishablePlatforms()
                }
            }
        }.onChange(of: platforms.count) { _ in
            getPublishablePlatforms()
        }.onChange(of: storedPlatforms.count) { _ in
            getPublishablePlatforms()
        }
    }
    
    
    
    public func refreshPlatforms() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Publisher.refreshPlatforms(context: context) { success in
            DispatchQueue.main.async {
                self.isRefreshing = false
                if success {
                    self.getPublishablePlatforms()
                }
            }
        }
    }

    func filterForStoredPlatforms() -> [PlatformsEntity] {
        var _storedPlatforms: Set<PlatformsEntity> = []

        for platform in platforms {
            if publishablePlatforms.contains(where: { $0.name == platform.name }
            ) {
                _storedPlatforms.insert(platform)
            }
        }
        return Array(_storedPlatforms)
    }

    private func createPlatformCard(for item: PlatformsEntity) -> some View {
        let serviceType = item.service_type ?? ""
        let composeBinding = getBindingComposeVariable(type: serviceType)
        let platformServiceType = getServiceType(type: serviceType)

        // Check if paltform is publishable
        var isEnabled: Bool = false

        let storedPlatform = publishablePlatforms.first {
            $0.name == item.name
        }
        if storedPlatform != nil {
            isEnabled = true
        }
        return PlatformCard(
            isEnabled: isEnabled,
            composeNewMessageRequested: $composeNewMessageRequested,
            platformRequestType: $requestType,
            composeViewRequested: composeBinding,
            parentRefreshRequested: .constant(false),
            requestedPlatformName: $requestedPlatformName,
            platform: item,
            serviceType: platformServiceType,
            callback: callback
        )
    }

    func getBindingComposeVariable(type: String) -> Binding<Bool> {
        @State var defaultNil: Bool? = false
        switch type {
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

    func getPublishablePlatforms() {
        publishablePlatforms.removeAll()
        for account in storedPlatforms {
            if !account.isMissing {
                publishablePlatforms.append(account)
            }
        }
    }

    func getRequestTypeText(type: PlatformsRequestedType) -> String {
        switch type {
        case .compose:
            return String(localized: "Send a message")
        case .revoke:
            return String(localized: "Remove a platform")
        default:
            return String(localized: "Available Platforms")
        }
    }

    func getServiceType(type: String) -> Publisher.ServiceTypes {
        switch type {
        case Publisher.ServiceTypes.EMAIL.rawValue:
            return Publisher.ServiceTypes.EMAIL
        case Publisher.ServiceTypes.MESSAGE.rawValue:
            return Publisher.ServiceTypes.MESSAGE
        case Publisher.ServiceTypes.TEXT.rawValue:
            return Publisher.ServiceTypes.TEXT

        default:
            return Publisher.ServiceTypes.BRIDGE
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









//struct PlatformsCompose_Preview: PreviewProvider {
//    static var previews: some View {
//
//        let container = createInMemoryPersistentContainer()
//        populateMockData(container: container)
//
//        @State var requestedPlatformName: String = "gmail"
//        @State var platformRequestType: PlatformsRequestedType = .compose
//        @State var composeNewMessage: Bool = false
//        @State var composeTextRequested: Bool = false
//        @State var composeMessageRequested: Bool = false
//        @State var composeEmailRequested: Bool = false
//        @State var requestedFromAccount: String? = "example@gmail.com"
//        return PlatformsView(
//            requestType: $platformRequestType,
//            requestedPlatformName: $requestedPlatformName,
//            composeNewMessageRequested: $composeNewMessage,
//            composeTextRequested: $composeTextRequested,
//            composeMessageRequested: $composeMessageRequested,
//            composeEmailRequested: $composeEmailRequested
//        )
//            .environment(\.managedObjectContext, container.viewContext)
//    }
//}
