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
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false

    @Binding var isLoggedIn: Bool
    @State var messagePlatformViewRequested: Bool = false
    @State var messagePlatformViewPlatformName: String = ""
    @State var messagePlatformViewFromAccount: String = ""

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
                            OfflineAvailablePlatformsSheetsView(
                                messagePlatformViewRequested: $messagePlatformViewRequested, 
                                messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
                                messagePlatformViewFromAccount: $messagePlatformViewFromAccount,
                                isRevoke: true)
                        }
                    }
                    
                    Section(header: Text("Account")) {
                        Button("Log out") {
                            showIsLoggingOut.toggle()
                        }.confirmationDialog("", isPresented: $showIsLoggingOut) {
                            Button("Log out", role: .destructive, action: logoutAccount)
                        } message: {
                            Text("You can log back in at anytime. All the messages sent would be deleted.")
                        }

                        if deleteProcessing {
                            ProgressView()
                        } else {
                            Button("Delete Account", role: .destructive) {
                                showIsDeleting.toggle()
                            }.confirmationDialog("", isPresented: $showIsDeleting) {
                                Button("Continue Deleting", role: .destructive, action: deleteAccount)
                            } message: {
                                Text("You can create another account anytime. All your stored tokens would be revoked from the Vault and all data deleted")
                            }
                        }
                    }
                }
            }.navigationTitle("Settings")
        }
    }
    
    
    func logoutAccount() {
        do {
            Vault.resetKeystore()
            try DataController.resetDatabase(context: viewContext)
            try Vault.resetStates(context: viewContext)
            
            isLoggedIn = false
            
            dismiss()
        } catch {
            print("Error loging out: \(error)")
        }
    }
    
    func deleteAccount() {
        deleteProcessing = true
        let backgroundQueueu = DispatchQueue(label: "deleteAccountQueue", qos: .background)
        backgroundQueueu.async {
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
