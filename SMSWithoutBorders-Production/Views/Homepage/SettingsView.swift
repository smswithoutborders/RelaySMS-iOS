//
//  SettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI

struct Items: Hashable, Identifiable {
    let title: String
    let id = UUID()
}

struct Sections: Identifiable {
    let header: String
    let items: [Items]
    let id = UUID()
}

let sections: [Sections] = [
    Sections(header: "Accounts",
             items: [Items(title: "Delete Account")])
]

struct SecuritySettingsView: View {
    @State private var selected: UUID?
    @State private var deleteProcessing = false
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(sections) { section in
                    Section(header: Text(section.header)) {
                        ForEach(section.items) { item in
                            Button(action: {
                                deleteProcessing = true
                                Task {
                                    do {
                                        let llt = try Vault.getLongLivedToken()
                                        try Vault.completeDeleteEntity(
                                            longLiveToken: llt,
                                            storedTokenEntities: storedPlatforms)
                                    } catch {
                                        print("Error deleting: \(error)")
                                    }
                                    deleteProcessing = false
                                }
                            }) {
                                if deleteProcessing {
                                    ProgressView()
                                } else {
                                    Text(item.title)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SecuritySettingsView()) {
                    Text("Security")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SecuritySettingsView()
}
