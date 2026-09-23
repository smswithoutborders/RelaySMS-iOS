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

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    
    @AppStorage(SettingsKeys.SETTINGS_MESSAGE_WITH_PHONENUMBER)
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
