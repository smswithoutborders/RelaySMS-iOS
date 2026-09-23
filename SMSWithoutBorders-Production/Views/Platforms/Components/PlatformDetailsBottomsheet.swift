//
//  PlatformDetailsBottomsheet.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 25/03/2025.
//

import SwiftUI

struct PlatformDetailsBottomsheet: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    var description: String
    var composeDescription: String

    @State var loading = false
    @State var isRevoking = false
    @State var savingNewPlatform = false
    @State var failed: Bool = false
    @State var phoneNumberAuthenticationRequested: Bool = false
    @State var sheetComposeNewPresented = false
    @State var accountSheetRequested = false
    @State var revokeConfirmSheetRequested = false

    @State var errorMessage: String = ""

    var platform: PlatformsEntity?
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(
        keyPath: \StoredPlatformsEntity.name,
        ascending: true)]
    ) private var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    
    
    @AppStorage(Publisher.PLATFORM_CODE_VERIFIER)
    var codeVerifier: String = ""
    
    @State private var fromAccount: String = ""

    @Binding var parentIsEnabled: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var platformRequestedType: PlatformsRequestedType
    @Binding var composeViewRequested: Bool
    @Binding var refreshParent: Bool
    @State var storePlatformOnDevice: Bool = false

    var callback: (() -> Void)?

    init(
        description: String,
        composeDescription: String,
        platform: PlatformsEntity?,
        isEnabled: Binding<Bool>,
        composeNewMessageRequested: Binding<Bool>,
        platformRequestedType: Binding<PlatformsRequestedType>,
        composeViewRequested: Binding<Bool>,
        refreshParent: Binding<Bool>,
        callback: (() -> Void)? = {}
    ) {
        self.description = description
        self.composeDescription = composeDescription
        self.platform = platform

        _parentIsEnabled = isEnabled
        _composeNewMessageRequested = composeNewMessageRequested
        _platformRequestedType = platformRequestedType
        _composeViewRequested = composeViewRequested
        _refreshParent = refreshParent
        self.callback = callback
        
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platform?.name ?? "unkown"))
    }

    var body: some View {
        VStack {
            if (isRevoking || loading) && platform != nil {
                SaveRevokePlatform(
                    name: platform!.name ?? "",
                    isSaving: $savingNewPlatform,
                    isRevoking: $isRevoking
                )
            }
            else if accountSheetRequested && platform != nil {
                SelectAccountSheetView(
                    filter: platform!.name!,
                    fromAccount: $fromAccount,
                    dismissParent: $parentIsEnabled
                ) {
                    revokeConfirmSheetRequested.toggle()
                }
                .confirmationDialog(String("Revoke?"), isPresented: $revokeConfirmSheetRequested) {
                    Button("Revoke", role: .destructive) {
                        isRevoking = true
//                        accountSheetRequested = false

                        let backgroundQueueu = DispatchQueue(label: "revokeAccountQueue", qos: .background)
                        backgroundQueueu.async {
                            do {
                                let llt = try Vault.getLongLivedToken()
                                let publisher = Publisher()
                                let response = try publisher.revokePlatform(
                                    llt: llt,
                                    platform: platform!.name!,
                                    account: fromAccount,
                                    protocolType: platform!.protocol_type!
                                )
                                
                                // Delete token for the account beign revoked
                                print("Searching for token for the platform for: \(platform!.name?.localizedCapitalized ?? "unkown" ) beign revoked to delete")
                                for storedEntity in storedPlatforms {
                                    if storedEntity.name  == platform!.name! {
                                        do {
                                            context.delete(storedEntity)
                                            try context.save()
                                        } catch {
                                            print(error)
                                            context.rollback()
                                        }
                                    }
                                }
                              
                                if response {
                                    let vault = Vault()
                                    do {
                                        let llt = try Vault.getLongLivedToken()
                                        try vault.refreshStoredTokens(
                                            llt: llt,
                                            context: context,
                                            storedTokenEntities: storedPlatforms
                                        )
                                    } catch {
                                        print(error)
                                    }
                                }

                                DispatchQueue.main.async {
                                    isRevoking = false
                                    refreshParent.toggle()
                                    dismiss()
                                }
                            } catch {
                                print("Error revoking: \(error)")
                            }
                        }
                    }
                } message: {
                    Text(String(localized: "Revoking removes the ability to send messages from this account. You can store the account again at anytime.", comment: "Sats that revoking a social platform will remove yout ability to send messages to that platform from your account, but you can always add the account again at anytime"))
                }
            }
            else {
                AvailablePlatformView(
                    platformRequestedType: $platformRequestedType,
                    phoneNumberAuthenticationRequested: $phoneNumberAuthenticationRequested,
                    parentIsEnabled: $parentIsEnabled,
                    composeNewMessageRequested: $composeNewMessageRequested,
                    accountSheetRequested: $accountSheetRequested,
                    composeViewRequested: $composeViewRequested,
                    loading: $loading,
                    platform: platform,
                    callback: callback,
                    description: description,
                    composeDescription: composeDescription
                )
                Spacer()
            }
        }
        .onOpenURL { url in
            print("Received new url: \(url)")
            DispatchQueue.background(background: {
                savingNewPlatform = true
                do {
                    if !codeVerifier.isEmpty {
                        print("Platofmr code verifier is available")
                        try Publisher.processIncomingUrls(
                            context: context,
                            url: url,
                            codeVerifier: codeVerifier,
                            storeOnDevice: storePlatformOnDevice,
                            storedTokenEntities: storedPlatforms
                        )
                        parentIsEnabled = true
               
                        codeVerifier = "" // Important!! - Set the code verifier back to empty so we do not keep stale code verifiers
                        print("Removed stale code verifier")
                    }
                    else {
                        failed = true
                        errorMessage = "An error occured please try again later: Missing code verifier"
                    }
             
                    dismiss()
                } catch {
                    print(error)
                    failed = true
                    errorMessage = error.localizedDescription
                }
            }, completion: {
                loading = false
            })
        }
        .alert(isPresented: $failed) {
            Alert(
                title: Text("Error! You did nothing wrong..."),
                message: Text(errorMessage),
                dismissButton: .default(Text("Not my fault!"))
            )
        }
    }


}


#Preview {
    var description: String = String(localized:"Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book", comment: "Explains some history about lorem Impsum")
    var composeDescription: String = String(localized:"[Compose] Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book", comment: "Explains some history about Lorem Ipsum")

    @State var saveRequested = false
    @State var codeVerifier: String = ""
    @State var isEnabled: Bool = false
    @State var composeNewMessage: Bool = false
    @State var composeViewRequested: Bool = false
    @State var platformRequestedType: PlatformsRequestedType = .available

    PlatformDetailsBottomsheet(
        description: description,
        composeDescription: composeDescription,
        platform: nil,
        isEnabled: $isEnabled,
        composeNewMessageRequested: $composeNewMessage,
        platformRequestedType: $platformRequestedType,
        composeViewRequested: $composeViewRequested,
        refreshParent: $isEnabled
    )
}
