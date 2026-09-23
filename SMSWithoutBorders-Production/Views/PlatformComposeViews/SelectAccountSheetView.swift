//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import CoreData
import SwiftUI

struct AccountListItem: View {
    var platform: StoredPlatformsEntity? = nil
    private var platformIsTwitter: Bool
    private var accountName: String
    private var platformName: String
    var context: NSManagedObjectContext
    private var missing: Bool = false


    init(platform: StoredPlatformsEntity?,
         context: NSManagedObjectContext,
         missing: Bool = false
    ) {
            self.platform = platform
            self.accountName = platform?.account ?? "Unknown account"
            self.platformName = platform?.name ?? "Unknown platform"
        self.platformIsTwitter = platformName == "twitter"
        self.context = context
        self.missing = missing
    }
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(RelayColors.colorScheme.primary)
                VStack {
                    Text(platformIsTwitter ? "@\(accountName)" : accountName)
                        .font(RelayTypography.bodyMedium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text(platformName.localizedCapitalized)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .padding()
                if !missing {
                    Image(systemName: "checkmark.circle").foregroundStyle(
                        Color.green)
                } else {
                    Image(systemName: "x.circle").foregroundStyle(Color.red)
                }

            }
        }
    }
}

struct SelectAccountSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) private var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest(sortDescriptors: []) private var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    
    
    @State private var publishablePlatforms: [StoredPlatformsEntity] = []
    @State private var allStoredPlatforms: [StoredPlatformsEntity] = []

    @Binding var fromAccount: String
    @Binding var dissmissParent: Bool
    private var platformName: String
    var isSendingMessage: Bool

    var callback: () -> Void = {}

    init(
        filter: String,
        fromAccount: Binding<String>,
        dismissParent: Binding<Bool>,
        callback: @escaping () -> Void = {},
        isSendingMessage: Bool = false
    ) {
        self.isSendingMessage = isSendingMessage

        self.platformName = filter
        _fromAccount = fromAccount
        _dissmissParent = dismissParent

        self.callback = callback
    }

    // Only show accounts which can publish
    func getPublishablePlatorms(
        storedPlatforms: FetchedResults<StoredPlatformsEntity>,
        context: NSManagedObjectContext
    ) -> [StoredPlatformsEntity] {
        print("[SelectAccountSheetView] Searching for platforms which can publish")
        var publishableAccounts: [StoredPlatformsEntity] = []
        for account in allStoredPlatforms {
            if !account.isMissing{
                publishableAccounts.append(account)
            }
        }
        return publishableAccounts
    }
    

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List(isSendingMessage ? publishablePlatforms : allStoredPlatforms, id: \.self) { platform in
                    Button(action: {
                        if fromAccount != nil {
                            fromAccount = platform.account!
                        }
                        callback()
                    }) {
                        AccountListItem(
                            platform: platform, context: context)
                    }
                }
            }
            .navigationTitle("\(platformName.localizedCapitalized) accounts")
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
            .onAppear {
                allStoredPlatforms = []
                allStoredPlatforms =  storedPlatforms.filter { $0.name == platformName}
                publishablePlatforms = getPublishablePlatorms(
                            storedPlatforms: storedPlatforms, context: context)
                if isSendingMessage {
                    print("[SelectAccountSheetView] Is sending message, will only show publishable platforms")
                } else {
                    print("[SelectAccountSheetView] Is revoking, will show all platforms for that account")

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

        return SelectAccountSheetView(
            filter: "twitter",
            fromAccount: $fromAccount,
            dismissParent: $globalDismiss
        )
        .environment(\.managedObjectContext, container.viewContext)
    }
}
