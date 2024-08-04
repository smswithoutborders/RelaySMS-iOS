//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import SwiftUI
import CoreData

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
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    
    private var platformName: String
    private var isRevoke: Bool

    @State private var isRevokeSheetShown: Bool = false
    @State private var isRevoking: Bool = false

    init(filter: String, isRevoke: Bool = false) {
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
        NavigationView {
            List(storedPlatforms) { platform in
                if !isRevoke {
                    NavigationLink(destination: getDestinationForPlatform(fromAccount: platform.account!)) {
                        accountView(accountName: platform.account!, platformName: platform.name!)
                    }
                } else {
                    Button(action: {
                        isRevokeSheetShown.toggle()
                    }) {
                        accountView(accountName: platform.account!, platformName: platform.name!)
                    }
                    .confirmationDialog(String("Revoke?"),
                                        isPresented: $isRevokeSheetShown) {
                        if isRevoking {
                            ProgressView()
                        }
                        else {
                            Button("Revoke", role: .destructive) {
                                do {
                                    let llt = try Vault.getLongLivedToken()
                                    let publisher = Publisher()
                                    let response = try publisher.revokePlatform(
                                        llt: llt, platform: platform.name!, account: platform.account!, protocolType: getPlatformType(storedPlatform: platform))
                                    
                                    if response {
                                        viewContext.delete(platform)
                                        try viewContext.save()
                                    }
                                } catch {
                                    print("Error revoking: \(error)")
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    } message: {
                        Text("Revoking removes the ability to send messages from this account. You can store the acocunt again at anytime.")
                    }
                }
            }
            .navigationTitle("\(platformName) Accounts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    @ViewBuilder func getDestinationForPlatform(fromAccount: String) -> some View {
        ForEach(platforms) { platform in
            switch platform.service_type {
                case "email":
                EmailView(platformName: platform.name!, fromAccount: fromAccount)
                default:
                    EmptyView()
            }
        }
    }
    
    private func getPlatformType(storedPlatform: StoredPlatformsEntity) -> String {
        for platform in platforms {
            if platform.name == storedPlatform.name {
                return platform.protocol_type!
            }
        }
        return ""
    }
}

struct AccountSheetView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return AccountSheetView(filter: "telegram", isRevoke: true)
            .environment(\.managedObjectContext, container.viewContext)
//        return RevokeAccountView()
    }
}
