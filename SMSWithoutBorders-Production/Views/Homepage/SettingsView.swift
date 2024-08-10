//
//  SettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI


struct SecuritySettingsView: View {
    @State private var selected: UUID?
    @State private var deleteProcessing = false
    
    @State private var isShowingRevoke = false
    
    @Binding var isLoggedIn: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Vault")) {
                        Button("Revoke Platforms") {
                            isShowingRevoke = true
                        }.sheet(isPresented: $isShowingRevoke) {
                            OfflineAvailablePlatformsSheetsView(isRevoke: true)
                        }
                    }
                    
                    Section(header: Text("Account")) {
                        Button("Log out", action: logoutAccount)

                        if deleteProcessing {
                            ProgressView()
                        } else {
                            Button("Delete Account", role: .destructive, action: deleteAccount)
                        }
                    }
                }
            }.navigationTitle("Settings")
        }
    }
    
    
    func logoutAccount() {
        do {
            Vault.resetKeystore()
            try Vault.resetDatastore(context: viewContext )
            try Vault.resetStates(context: viewContext)
            
            isLoggedIn = false
            
            dismiss()
        } catch {
            print("Error loging out: \(error)")
        }
    }
    
    func deleteAccount() {
        deleteProcessing = true
        Task {
            do {
                let llt = try Vault.getLongLivedToken()
                try Vault.completeDeleteEntity(
                    longLiveToken: llt,
                    storedTokenEntities: storedPlatforms,
                    platforms: platforms)
            } catch {
                print("Error deleting: \(error)")
            }
            deleteProcessing = false
        }
    }
}

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SecuritySettingsView(isLoggedIn: $isLoggedIn)) {
                    Text("Security")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    @State var isLoggedIn = true
    SecuritySettingsView(isLoggedIn: $isLoggedIn)
}
