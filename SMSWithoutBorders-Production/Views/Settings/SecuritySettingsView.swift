//
//  SecuritySettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct SettingsKeys {
    public static let SETTINGS_MESSAGE_WITH_PHONENUMBER: String =
        "SETTINGS_MESSAGE_WITH_PHONENUMBER"
    public static let SETTINGS_STORE_PLATFORMS_ON_DEVICE: String =
        "SETTINGS_STORE_PLATFORMS_ON_DEVICE"
    public static let SETTINGS_DO_NOT_NOTIFY_OF_MISSING_TOKENS: String = "SETTINGS_DO_NOT_NOTIFY_OF_MISSING_TOKENS"
    
    public static let SETTINGS_NOTIFY_OF_NEW_FEATURE: String = "SETTINGS_NOTIFY_OF_NEW_FEATURE"
}

enum SecurityAlertType {
   case migrationStatus
   case disableLocalTokenStorageConfirmation
//   case revocationConfirmation
//   case revocationStatus
}

struct SecuritySettingsView: View {

    @State private var selected: UUID?
    @State private var deleteProcessing = false

    @State private var isShowingRevoke = false
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false
    @State var isPerformingAccountAction: Bool = false
    
    @State var showAlert: Bool = false
    @State var activeAlertType: SecurityAlertType? = nil
    @State var migrationSuccessful: Bool = false
    @State var revokingSuccessful: Bool = false
    
    @State private var isLoading = false
    @State private var loadingMessage: String?

    @AppStorage(SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
    private var storeTokensOnDevice: Bool = false

    @Binding var isLoggedIn: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: []) var storedPlatforms:
        FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms:
        FetchedResults<PlatformsEntity>
    
    func migratePlatforms() {
        // Trigger a refresh
        let vault = Vault()
        do {
            isLoading = true
            loadingMessage = "Migrating platforms..."
//            let migrationAttemptedPreviously = storedPlatforms.contains { $0.isStoredOnDevice}
            
            let llt: String = try Vault.getLongLivedToken()
            try vault.refreshStoredTokens(
                llt: llt,
                context: viewContext,
                storedTokenEntities: storedPlatforms
            )
            
            viewContext.refreshAllObjects()
            
            activeAlertType = .migrationStatus
            showAlert = true
            migrationSuccessful = true
        } catch {
            activeAlertType = .migrationStatus
            showAlert = true
            migrationSuccessful = false
            print("Migration error: \(error)")
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section(header: Text("OAuth Tokens")) {
                    Toggle("Store Tokens On-device", isOn: $storeTokensOnDevice)
                        .disabled(!isLoggedIn)
                        .onChange(of: storeTokensOnDevice) { newValue in
                        
                        // Do not invoke this onChanged if the user is perfomaing an account action like logging out or deleting their account
                        guard !isPerformingAccountAction else {
                            print("onChange(storeTokensOnDevice) skipped due to account action.")
                            return
                        }
                        
                        if newValue {
                            migratePlatforms()
                        } else {
                            var migrationAttemptedPreviously = false
                            for account in storedPlatforms {
                                if account.is_stored_on_device {
                                    migrationAttemptedPreviously = true
                                    break
                                }
                            }
                      
                            if migrationAttemptedPreviously {
                                activeAlertType = .disableLocalTokenStorageConfirmation
                                showAlert = true
                            }
                        }
                    }.alert(isPresented: $showAlert) {
                        switch activeAlertType {
                        case .migrationStatus:
                            return Alert(
                                title: Text(migrationSuccessful ? "Success" : "Error"),
                                message: Text(
                                    migrationSuccessful ?
                                    "Your platforms have been downloaded to this device successfully!" :
                                        "An error occured while downloading your tokens to this device "
                                ),
                                dismissButton: .default(
                                    Text("OK"),
                                    action: {
                                        dismiss()
                                    })
                            )
                            
                        case .disableLocalTokenStorageConfirmation:
                            return Alert(
                                title: Text("Please note"),
                                message: Text("Turning this off will take effect when next you add a platform, your current platforms will continue to use the tokens available on this device."
                                ),
                                primaryButton: .default(
                                    Text("Continue"),
                                    action: {
                                        storeTokensOnDevice = false
                                        dismiss()
                                    }
                                ),
                                secondaryButton: .default(Text("Cancel")) {
                                    storeTokensOnDevice = true
                                    showAlert = false
                                    activeAlertType = nil
                                }
                            )
                        
                        case nil:
                          return Alert(
                                title: Text("Dummy Alert"),
                                message: Text("Dummy Alert"),
                                dismissButton: .default(
                                    Text("OK"),
                                    action: {
                                        dismiss()
                                    })
                            )
                        
                        }
                    }.padding([.top], 12)
                    Text(String(localized: "When adding accounts for platforms that utilize OAuth2.0 (e.g Gmail, X), enabling this makes sure your access tokens are rather stored on your current device"
                        )
                    )
                    .font(RelayTypography.bodyMedium)
                    .foregroundStyle(
                        RelayColors.colorScheme.onSurface.opacity(0.6)
                    ).padding([.bottom], 12)
                }.listRowSeparator(.hidden)

                Section(header: Text("Account")) {
                    Button("Log out") {
                        showIsLoggingOut.toggle()
                       
                    }
                    .confirmationDialog("", isPresented: $showIsLoggingOut) {
                        Button("Log out", role: .destructive) {
                            isPerformingAccountAction = true
                            logout()
                        }
                    } message: {
                        Text(
                            String(
                                localized: "You can log back in at anytime. All the messages sent would be deleted.",
                                comment: "Explains that you can log into your account at any time, and all the messages sent would be deleted"
                            ))
                    }
                    .disabled(!isLoggedIn)
                    if deleteProcessing {
                        ProgressView()
                    } else {
                        Button("Delete Account", role: .destructive) {
                            showIsDeleting.toggle()
                        }.confirmationDialog("", isPresented: $showIsDeleting) {
                            Button(
                                "Continue Deleting", role: .destructive) {
                                    isPerformingAccountAction = true
                                    deleteAccount()
                                }
                        } message: {
                            Text(
                                String(localized:"You can create another account anytime. All your stored tokens would be revoked from the Vault and all data deleted",
                                    comment: "Explains that you can always create an account at a later date, but all previously stored tokens and platforms for your old account will be revoked and data deleted"
                                ))
                        }
                        .disabled(!isLoggedIn)
                    }
                }.listRowSeparator(.hidden)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black
                        .opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView(loadingMessage ?? "Revoking...")  //.foregroundStyle(Color.white)
                        .padding()
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
        DispatchQueue.background(
            background: {
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
                deleteProcessing = false
            },
            completion: {
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

struct SecuritySettingsView_Preview: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""

    static var previews: some View {
        @State var isLoggedIn = true
        SecuritySettingsView(isLoggedIn: $isLoggedIn)
    }
}
