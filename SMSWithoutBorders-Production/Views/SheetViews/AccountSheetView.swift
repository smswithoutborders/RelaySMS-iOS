//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import SwiftUI

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

func getLocalMockedStoredData(filter: String) -> [Vault.LocalStoredTokens] {
    return [
        Vault.LocalStoredTokens(name: "gmail", account: "dev@relay.com"),
        Vault.LocalStoredTokens(name: "twitter", account: "@relaydevelopers")
    ].filter {
        $0.name == filter
    }
}


struct AccountSheetView: View {
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    
    private var mockedStoredPlatforms: [Vault.LocalStoredTokens]

    private var mockData = false
    
    private var platformName: String
    
    init(filter: String, mockData: Bool = false) {
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [], predicate: NSPredicate(format: "name == %@", filter))
        
        self.mockedStoredPlatforms = getLocalMockedStoredData(filter: filter)
        self.mockData = mockData
        self.platformName = filter
    }
    
    var body: some View {
        NavigationView {
            if mockData {
                List(self.mockedStoredPlatforms) { platform in
                    accountView(accountName: platform.account,
                                platformName: platform.name)
                }
                .navigationTitle("\(platformName) Accounts")
                .navigationBarTitleDisplayMode(.inline)
            }
            else {
                List(storedPlatforms) { platform in
                    accountView(accountName: platform.account!,
                                platformName: platform.name!)
                }
                .navigationTitle("\(platformName) Accounts")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    @State var mockData = true
    AccountSheetView(filter: "twitter", mockData: mockData)
}
