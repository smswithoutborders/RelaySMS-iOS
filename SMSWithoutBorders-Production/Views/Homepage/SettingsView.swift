//
//  SettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI
import CoreData

public func logoutAccount(context: NSManagedObjectContext) {
    do {
        try Vault.resetKeystore(context: context)
        try DataController.resetDatabase(context: context)
    } catch {
        print("Error loging out: \(error)")
    }
}

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
                Section(header: Text("Account")) {
                    Button("Log out") {
                        showIsLoggingOut.toggle()
                    }.confirmationDialog("", isPresented: $showIsLoggingOut) {
                        Button("Log out", role: .destructive, action: logout)
                    } message: {
                        Text(String(localized:"You can log back in at anytime. All the messages sent would be deleted.", comment: "Explains that you can log into your account at any time, and all the messages sent would be deleted"))
                    }
                    .disabled(!isLoggedIn)

                    if deleteProcessing {
                        ProgressView()
                    } else {
                        Button("Delete Account", role: .destructive) {
                            showIsDeleting.toggle()
                        }.confirmationDialog("", isPresented: $showIsDeleting) {
                            Button("Continue Deleting", role: .destructive, action: deleteAccount)
                        } message: {
                            Text(String(localized:"You can create another account anytime. All your stored tokens would be revoked from the Vault and all data deleted", comment: "Explains that you can always create an account at a later date, but all previously stored tokens and platforms for your old account will be revoked and data deleted"))
                        }
                        .disabled(!isLoggedIn)
                    }
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func logout() {
        logoutAccount(context: viewContext)
        do {
            isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print(error)
        }
        dismiss()
    }
    
    
    func deleteAccount() {
        deleteProcessing = true
        DispatchQueue.background(background: {
            do {
                let llt = try Vault.getLongLivedToken()
                try Vault.completeDeleteEntity(
                    context: viewContext,
                    longLiveToken: llt,
                    storedTokenEntities: storedPlatforms,
                    platforms: platforms)
            } catch {
                print("Error deleting: \(error)")
            }
        }, completion: {
            DispatchQueue.main.async {
                logoutAccount(context: viewContext)
                do {
                    isLoggedIn = try !Vault.getLongLivedToken().isEmpty
                } catch {
                    print(error)
                }
                dismiss()
            }
        })
    }
}

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    
    @AppStorage(SecuritySettingsView.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false
    
    @State private var showLanguageChangeConfirmationAlert = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        Button("Language"){
                            showLanguageChangeConfirmationAlert.toggle()
                        }
                        .alert("Change App Language", isPresented: $showLanguageChangeConfirmationAlert) {
                            Button("Cancel", role: .cancel){
                                showLanguageChangeConfirmationAlert.toggle()
                            }
                            Button("Open Settings"){
                                // Open language settings page instead
                                if let url: URL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                                
                            }
                        } message: {
                            Text(String(localized: "Continue to iOS settings and select your preferred language for RelaySMS.", comment: "Instructions for chnaging application langueg via system settings.") )
                        }
                        .padding(.bottom, 10)
                    }
                    
                    Section {
                        NavigationLink(destination: SecuritySettingsView(isLoggedIn: $isLoggedIn)) {
                            Text("Security")
                        }
                    }

                    Section {
                        VStack(alignment: .leading) {
                            Toggle("Message with phone number", isOn: $messageWithPhoneNumber)
                            Text(String(localized:"Turn this on to publish the message using your phone number and not your DeviceID.\n\nThis can help reduce the size of the SMS message", comment: "Says that enabling this setting will allow you to use your phone number instead of your DeviceID, which can help reduce the size of the SMS message"))
                                .font(.caption)
                                .padding(.trailing, 60)
                                .foregroundColor(.secondary)
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
        
        @State var isLoggedIn = false
        return SettingsView(isLoggedIn: $isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
