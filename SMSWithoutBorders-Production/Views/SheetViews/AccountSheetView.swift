//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import SwiftUI
import CoreData

func getProtocolTypeForPlatform(storedPlatform: StoredPlatformsEntity,
                                platforms: FetchedResults<PlatformsEntity>) -> String {
    for platform in platforms {
        if platform.name == storedPlatform.name {
            return platform.protocol_type!
        }
    }
    return ""
}


@ViewBuilder func accountView(accountName: String, platformName: String) -> some View {
    VStack {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
            VStack {
                Text(accountName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(platformName)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct AccountSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    
    private var platformName: String
    private var isRevoke: Bool

    @State private var isRevokeSheetShown: Bool = false
    @State private var isRevoking: Bool = false
    @State private var revokingShown: Bool = false
    
    @State private var isLinkActive: Bool = false

    init(filter: String, globalDismiss: Binding<Bool>, isRevoke: Bool = false) {
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [], 
            predicate: NSPredicate(format: "name == %@", filter))
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", filter))
        
        self.platformName = filter
        self.isRevoke = isRevoke
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List(storedPlatforms, id: \.self) { platform in
                if !isRevoke {
                    Button(action:{
                        isLinkActive = true
                    }) {
                        accountView(accountName: platform.account!, platformName: platform.name!)
                    }.background(
                        NavigationLink(
                            destination: getDestinationForPlatform(fromAccount: platform.account!),
                            isActive: $isLinkActive) { EmptyView() }.hidden()
                    )
                } else {
                    if isRevoking {
                        ProgressView()
                    }
                    else {
                        Button(action: {
                            isRevokeSheetShown.toggle()
                        }) {
                            accountView(accountName: platform.account!, platformName: platform.name!)
                        }
                        .confirmationDialog(String("Revoke?"),
                                            isPresented: $isRevokeSheetShown) {

                            Button("Revoke", role: .destructive) {
                                isRevoking = true
                                let backgroundQueueu = DispatchQueue(label: "revokeAccountQueue", qos: .background)
                                backgroundQueueu.async {
                                    do {
                                        let llt = try Vault.getLongLivedToken()
                                        let publisher = Publisher()
                                        let response = try publisher.revokePlatform(
                                            llt: llt,
                                            platform: platform.name!,
                                            account: platform.account!,
                                            protocolType: getProtocolTypeForPlatform(
                                                storedPlatform: platform, platforms: platforms))
                                        
                                        if response {
                                            viewContext.delete(platform)
                                            try viewContext.save()
                                        }
                                        
                                        DispatchQueue.main.async {
                                            dismiss()
                                        }
                                    } catch {
                                        print("Error revoking: \(error)")
                                    }
                                }
                            }
//                            Button("Cancel", role: .cancel) {}
                            
                        } message: {
                            Text("Revoking removes the ability to send messages from this account. You can store the acocunt again at anytime.")
                        }
                    }
                }
            }
        }
        .navigationTitle("\(platformName) accounts")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    @ViewBuilder func getDestinationForPlatform(fromAccount: String) -> some View {
        ForEach(platforms) { platform in
            switch platform.service_type {
            case "email":
                EmailView(platformName: platform.name!, fromAccount: fromAccount)
            case "text":
                TextView(platformName: platform.name!, fromAccount: fromAccount)
            case "message":
                MessagingView(platformName: platform.name!, fromAccount: fromAccount,
                              message: nil,
                              vc: nil)
            default:
                EmptyView()
            }
        }
    }
    
}

struct AccountSheetView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var globalDismiss = false
        @State var messagePlatformViewRequested = false
        @State var messagePlatformViewFromAccount: String = ""
        return AccountSheetView(
            filter: "twitter",
            globalDismiss: $globalDismiss,
            isRevoke: true)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
