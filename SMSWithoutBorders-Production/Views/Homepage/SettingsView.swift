//
//  SettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI


struct SecuritySettingsView: View {
    public static var SETTINGS_MESSAGE_WITH_PHONENUMBER = "SETTINGS_MESSAGE_WITH_PHONENUMBER"
    @State private var selected: UUID?
    @State private var deleteProcessing = false
    
    @State private var isShowingRevoke = false
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false

    @Binding var isLoggedIn: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section(header: Text("Vault")) {
                    NavigationLink {
                        OfflineAvailablePlatformsSheetsView(isRevoke: true)
                    } label: {
                        Text("Revoke stored platforms")
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
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    func logoutAccount() {
        do {
            Vault.resetKeystore()
            try DataController.resetDatabase(context: viewContext)
            try Vault.resetStates(context: viewContext)
            
            dismiss()
        } catch {
            print("Error loging out: \(error)")
        }
    }
    
    func deleteAccount() {
        deleteProcessing = true
        DispatchQueue.background(background: {
            do {
                let llt = try Vault.getLongLivedToken()
                try Vault.completeDeleteEntity(
                    longLiveToken: llt,
                    storedTokenEntities: storedPlatforms,
                    platforms: platforms)
            } catch {
                print("Error deleting: \(error)")
            }
        }, completion: {
            DispatchQueue.main.async {
                logoutAccount()
            }
        })
    }
}

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    
    @AppStorage(SecuritySettingsView.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false


    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        VStack(alignment: .leading) {
                            Toggle("Message with phone number", isOn: $messageWithPhoneNumber)
                            Text("Turn this on to publish the message using your phone number and not your DeviceID.\n\nThis can help reduce the size of the SMS message")
                                .font(.caption)
                                .padding(.trailing, 60)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        NavigationLink(destination: SecuritySettingsView(isLoggedIn: $isLoggedIn)) {
                            Text("Security")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SecuritySettingsView_Preview: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""

    static var previews: some View {
        @State var isLoggedIn = true
        SecuritySettingsView(isLoggedIn: $isLoggedIn)
    }
}

struct SettingsView_Preview: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var isLoggedIn = true
        return SettingsView(isLoggedIn: $isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
