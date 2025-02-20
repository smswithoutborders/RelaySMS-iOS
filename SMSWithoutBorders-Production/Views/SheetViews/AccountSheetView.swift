//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import SwiftUI
import CoreData

struct AccountView: View {
    var accountName: String
    var platformName: String
    var body : some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack {
                    Text(accountName)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
//                    Text(platformName)
//                        .font(.caption2)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .foregroundStyle(.gray)
                }
                .padding()
            }
        }
    }
}

struct AccountSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    
    @Binding var fromAccount: String
    @Binding var dissmissParent: Bool
    private var platformName: String
    
    init(filter: String, fromAccount: Binding<String>, dismissParent: Binding<Bool>) {
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [], 
            predicate: NSPredicate(format: "name == %@", filter))
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", filter))
        
        self.platformName = filter
        _fromAccount = fromAccount
        _dissmissParent = dismissParent
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List(storedPlatforms, id: \.self) { platform in
                    Button(action: {
                        fromAccount = platform.account!
                        dismiss()
                    }) {
                        AccountView(
                            accountName: platform.account!,
                            platformName: platform.name!
                        )
                    }
    //                .confirmationDialog(String("Revoke?"), isPresented: $isRevokeSheetShown) {
    //                    Button("Revoke", role: .destructive) {
    //                        isRevoking = true
    //                        let backgroundQueueu = DispatchQueue(label: "revokeAccountQueue", qos: .background)
    //                        backgroundQueueu.async {
    //                            do {
    //                                let llt = try Vault.getLongLivedToken()
    //                                let publisher = Publisher()
    //                                let response = try publisher.revokePlatform(
    //                                    llt: llt,
    //                                    platform: platform.name!,
    //                                    account: platform.account!,
    //                                    protocolType: Publisher.getProtocolTypeForPlatform(
    //                                        storedPlatform: platform,
    //                                        platforms: platforms
    //                                    )
    //                                )
    //
    //                                if response {
    //                                    context.delete(platform)
    //                                    try context.save()
    //                                }
    //
    //                                DispatchQueue.main.async {
    //                                    dismiss()
    //                                }
    //                            } catch {
    //                                print("Error revoking: \(error)")
    //                            }
    //                        }
    //                    }
    //                } message: {
    //                    Text("Revoking removes the ability to send messages from this account. You can store the acocunt again at anytime.")
    //                }
                }
            }
            .navigationTitle("\(platformName) accounts")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dissmissParent.toggle()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
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
        @State var fromAccount: String = ""

        return AccountSheetView(
            filter: "twitter",
            fromAccount: $fromAccount,
            dismissParent: $globalDismiss
        ).environment(\.managedObjectContext, container.viewContext)
    }
}
