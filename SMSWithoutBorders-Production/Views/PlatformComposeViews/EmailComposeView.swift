//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import CoreData
import CryptoKit
import MessageUI
import SwiftUI

struct EmailComposeForm: View {
    @Binding var composeTo: String
    @Binding var composeFrom: String
    @Binding var composeCC: String
    @Binding var composeBCC: String
    @Binding var composeSubject: String
    @Binding var composeBody: String
    @Binding var fromAccount: String

    var isBridge: Bool

    var body: some View {
        VStack {
            VStack {
                if !isBridge {
                    HStack {
                        Text("From")
                        TextField("From", text: $fromAccount)
                    }
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .disabled(true)
                }
                
                HStack {
                    Text("To")
                    TextField("", text: $composeTo)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                }

                HStack {
                    Text("CC")
                    TextField("", text: $composeCC)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)

                }
                
                HStack {
                    Text("BCC")
                    TextField("", text: $composeBCC)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                }
                
                HStack {
                    Text("Subject")
                    TextField("", text: $composeSubject)
                    .autocapitalization(.sentences)
                }
            }
            .textFieldStyle(.roundedBorder)
            

            Spacer()
            VStack {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $composeBody)
                        .frame(height: 400)
                        .background(Color(.systemGray6)) // Optional: Add a light background color
                        .clipShape(RoundedRectangle(cornerRadius: 15)) // Clips the editor's background to a rounded shape
                        .overlay( // Adds the actual border overlay
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .autocapitalization(.sentences)
                    
                    if composeBody.isEmpty {
                        Text("Content")
                        .foregroundColor(Color(.systemGray3))
                        .padding(.top, 16) // Adjust padding to align with TextEditor's text
                        .padding(.leading, 12)
                        .allowsHitTesting(false) // Allows taps to pass through to the TextEditor
                    }
                }
            }
        }
    }
}

struct EmailComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

    #if DEBUG
        private var defaultGatewayClientMsisdn: String =
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]
                == "1"
            ? ""
            : UserDefaults.standard.object(
                forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String
                ?? ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        private var defaultGatewayClientMsisdn: String = ""
    #endif

    @AppStorage(SettingsKeys.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false

    @State private var encryptedFormattedContent: String = ""
    @State var isShowingMessages: Bool = false
    @State var isSendingRequest: Bool = false
    @State var requestToChooseAccount: Bool = false
    @State var composeFrom: String = ""
    @State var fromAccount: String = ""

    @State var dismissRequested = false

    private var isBridge: Bool = false

    @Binding var message: Messages?
    @Binding var platformName: String

    @State var composeTo: String = ""
    @State var composeCC: String = ""
    @State var composeBCC: String = ""
    @State var composeSubject: String = ""
    @State var composeBody: String = ""

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoading = false

    init(
        platformName: Binding<String>,
        isBridge: Bool = false,
        message: Binding<Messages?>
    ) {
        print("Requested platform name: \(platformName.wrappedValue )")
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "name == %@", platformName.wrappedValue))
        _message = message

        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "name == %@", platformName.wrappedValue))

        _platformName = platformName
        self.isBridge = isBridge
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    EmailComposeForm(
                        composeTo: $composeTo,
                        composeFrom: $composeFrom,
                        composeCC: $composeCC,
                        composeBCC: $composeBCC,
                        composeSubject: $composeSubject,
                        composeBody: $composeBody,
                        fromAccount: $fromAccount,
                        isBridge: isBridge
                    )
                    Spacer(minLength: 24)

                    Button(
                        action: {
                            isSendingRequest = true
                            DispatchQueue.background(background: {
                                do {
                                    encryptedFormattedContent =
                                        try getEncryptedContent(
                                            isBridge: self.isBridge)
                                } catch {
                                    print(
                                        "Some error occured while sending: \(error)"
                                    )
                                }
                                isShowingMessages.toggle()
                                isSendingRequest = false
                            })
                        },
                        label: {
                            if isSendingRequest {
                                ProgressView()
                            } else {
                                Text("Send")
                            }
                        }
                    )
                    .buttonStyle(.relayButton(variant: .secondary))
                    .disabled(!isBridge && fromAccount.isEmpty)
                    .sheet(isPresented: $isShowingMessages) {
                        SMSComposeMessageUIView(
                            recipients: [defaultGatewayClientMsisdn],
                            body: $encryptedFormattedContent,
                            completion: handleCompletion(_:)
                        )
                        .ignoresSafeArea()
                    }
                }
                .padding()
            }

            .sheet(isPresented: $requestToChooseAccount) {
                SelectAccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested,
                    callback:  {
                        requestToChooseAccount.toggle()
                        if self.message != nil {
                            composeTo = self.message!.toAccount
                            composeCC = self.message!.cc
                            composeBCC = self.message!.bcc
                            composeSubject = self.message!.subject
                            composeBody = self.message!.data
                        }
                    },
                    isSendingMessage: true
                )
                .applyPresentationDetentsIfAvailable()
                .interactiveDismissDisabled(true)
            }
        }
        .onChange(of: dismissRequested) { state in
            if state {
                dismiss()
            }
        }
        .task {
            if storedPlatforms.count > 0 && !isBridge {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestToChooseAccount = true
                }
            }
            if isBridge {
                requestToChooseAccount = false
                if self.message != nil {
                    composeTo = self.message!.toAccount
                    composeCC = self.message!.cc
                    composeBCC = self.message!.bcc
                    composeSubject = self.message!.subject
                    composeBody = self.message!.data
                }
            }
        }
        .navigationTitle("Compose email")
    }

    func getEncryptedContent(isBridge: Bool = false) throws -> String {
        if !isBridge {
            let messageComposer = try Publisher.publish(context: context)
            let shortcode: UInt8 = "g".data(using: .utf8)!.first!

            // Get the stored platform and use the tokens if the platform tokens exist
            let storedPlatformEntity = storedPlatforms.first {
                $0.account == fromAccount
            }  // Gets the speciic account that matches the currently selected fromAccount

            return try messageComposer.emailComposerV1(
                platform_letter: shortcode,
                from: fromAccount,
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                accessToken: storedPlatformEntity?.access_token ?? nil,
                refreshToken: storedPlatformEntity?.refresh_token ?? nil
            )
        } else {
            let (cipherText, clientPublicKey) = try Bridges.compose(
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                context: context
            )
            if try !Vault.getLongLivedToken().isEmpty {
                return try Bridges.payloadOnly(
                    context: context, cipherText: cipherText)!
            } else {
                return try Bridges.authRequestAndPayload(
                    context: context,
                    cipherText: cipherText,
                    clientPublicKey: clientPublicKey!
                )!
            }
        }
    }

    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Yep cancelled")
            #if DEBUG
                saveMessageEntity()
            #endif
            break
        case .failed:
            print("Yep failed")
            #if DEBUG
                saveMessageEntity()
            #endif
            break
        case .sent:
            saveMessageEntity()
            dismiss()
            break
        @unknown default:
            print("Not even sure what this means")
            break
        }
    }

    private func saveMessageEntity() {
        DispatchQueue.background(background: {
            let messageEntities = MessageEntity(context: context)
            messageEntities.id = UUID()
            messageEntities.platformName = platformName
            messageEntities.fromAccount = fromAccount
            messageEntities.toAccount = composeTo
            messageEntities.cc = composeCC
            messageEntities.bcc = composeBCC
            messageEntities.subject = composeSubject
            messageEntities.body = composeBody
            messageEntities.date = Int32(Date().timeIntervalSince1970)

            if isBridge {
                messageEntities.type = Bridges.SERVICE_NAME
            }

            DispatchQueue.main.async {
                do {
                    try context.save()
                    dismiss()
                } catch {
                    print("Failed to save message entity: \(error)")
                }
            }
        })
    }

    func formatEmailForViewing(decryptedData: String) -> (
        platformLetter: String, to: String, cc: String, bcc: String,
        subject: String, body: String
    ) {
        let splitString = decryptedData.components(separatedBy: ":")

        let platformLetter: String = splitString[0]
        let to: String = splitString[1]
        let cc: String = splitString[2]
        let bcc: String = splitString[3]
        let subject: String = splitString[4]
        let body: String = splitString[5]

        return (platformLetter, to, cc, bcc, subject, body)
    }

}

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        @State var message: Messages? = Messages(
            id: UUID(),
            subject: "Test subject",
            data: "Test body",
            fromAccount: "from@test.com",
            toAccount: "to@test.com",
            platformName: "test platform",
            date: 0
        )

        @State var platformName = ""
        return EmailComposeView(
            platformName: $platformName, message: $message
        )
    }
}

struct EmailCompose_Preview: PreviewProvider {
    static var previews: some View {
        @State var composeTo: String = ""
        @State var composeFrom: String = ""
        @State var composeCC: String = ""
        @State var composeBCC: String = ""
        @State var composeSubject: String = ""
        @State var composeBody: String = ""
        @State var fromAccount: String = ""

        return EmailComposeForm(
            composeTo: $composeTo,
            composeFrom: $composeFrom,
            composeCC: $composeCC,
            composeBCC: $composeBCC,
            composeSubject: $composeSubject,
            composeBody: $composeBody,
            fromAccount: $fromAccount,
            isBridge: false
        )
    }
}
