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
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    
    private var platformName: String

    init(filter: String) {
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [], 
            predicate: NSPredicate(format: "name == %@", filter))
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", filter))
        self.platformName = filter
    }
    
    var body: some View {
        NavigationView {
            List(storedPlatforms) { platform in
                NavigationLink(destination: getDestinationForPlatform(fromAccount: platform.account!)) {
                    accountView(accountName: platform.account!, platformName: platform.name!)
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
                EmailView(platformName: platform.service_type!, fromAccount: fromAccount)
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
        
        return AccountSheetView(filter: "gmail")
            .environment(\.managedObjectContext, container.viewContext)
    }
}
