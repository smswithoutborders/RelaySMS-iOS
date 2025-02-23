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
    
    var callback: () -> Void = {}
    
    init(
        filter: String,
        fromAccount: Binding<String>,
        dismissParent: Binding<Bool>,
        callback: @escaping () -> Void = {}
    ) {
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [], 
            predicate: NSPredicate(format: "name == %@", filter))
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", filter))
        
        self.platformName = filter
        _fromAccount = fromAccount
        _dissmissParent = dismissParent
        
        self.callback = callback
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List(storedPlatforms, id: \.self) { platform in
                    Button(action: {
                        if fromAccount != nil {
                            fromAccount = platform.account!
                        }
                        callback()
                        dismiss()
                    }) {
                        AccountView(
                            accountName: platform.account!,
                            platformName: platform.name!
                        )
                    }
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
        )
        .environment(\.managedObjectContext, container.viewContext)
    }
}
