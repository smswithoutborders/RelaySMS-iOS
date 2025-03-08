//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import MessageUI
import CryptoKit
import CoreData

struct EmailComposerView: View {
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
            if(!isBridge) {
                VStack{
                    HStack {
                        Text("From ")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        TextField(fromAccount, text: $composeFrom)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(true)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                }
                Spacer(minLength: 9)
                
            }
            
            VStack{
                HStack {
                    Text("To ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeTo)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)
            
            VStack {
                HStack {
                    Text("Cc ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeCC)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)
            
            VStack {
                HStack {
                    Text("Bcc ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeBCC)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)
            
            VStack {
                HStack {
                    Text("Subject ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeSubject)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)
            
            VStack {
                TextEditor(text: $composeBody)
                    .accessibilityLabel("composeBody")
            }
        }
    
    }
}


struct EmailComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    #if DEBUG
    private var defaultGatewayClientMsisdn: String = 
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ? "" : UserDefaults.standard.object(forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String ?? ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        private var defaultGatewayClientMsisdn: String = ""
    #endif
    
    @AppStorage(SecuritySettingsView.SETTINGS_MESSAGE_WITH_PHONENUMBER)
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

    init(
        platformName: Binding<String>,
        isBridge: Bool = false,
        message: Binding<Messages?>
    ) {
        print("Requested platform name: \(platformName)")
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName.wrappedValue))
        _message = message

        _platformName = platformName
        self.isBridge = isBridge
    }
    
    var body: some View {
        NavigationView {
            VStack {
                EmailComposerView(
                    composeTo: $composeTo,
                    composeFrom: $composeFrom,
                    composeCC: $composeCC,
                    composeBCC: $composeBCC,
                    composeSubject: $composeSubject,
                    composeBody: $composeBody,
                    fromAccount: $fromAccount,
                    isBridge: isBridge
                )
            }
            .padding()
            .sheet(isPresented: $requestToChooseAccount) {
                AccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested
                ) {
                    requestToChooseAccount.toggle()
                    if self.message != nil {
                        composeTo = self.message!.toAccount
                        composeCC = self.message!.cc
                        composeBCC = self.message!.bcc
                        composeSubject = self.message!.subject
                        composeBody = self.message!.data
                        self.message = nil
                        self.platformName = ""
                    }
                }
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
            if storedPlatforms.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestToChooseAccount = true
                }
            }
            if(isBridge) {
                if self.message != nil {
                    composeTo = self.message!.toAccount
                    composeCC = self.message!.cc
                    composeBCC = self.message!.bcc
                    composeSubject = self.message!.subject
                    composeBody = self.message!.data
                    self.message = nil
                    self.platformName = ""
                }
            }
        }
        .navigationTitle("Compose email")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSendingRequest {
                    ProgressView()
                }
                else {
                    Button("Send") {
                        isSendingRequest = true
    //                    let platform = platforms.first!
                        DispatchQueue.background(background: {
                            do {
                                encryptedFormattedContent = try getEncryptedContent(isBridge: self.isBridge)
                            } catch {
                                print("Some error occured while sending: \(error)")
                            }
                            isShowingMessages.toggle()
                            isSendingRequest = false
                        })
                    }
                    .disabled(!isBridge && fromAccount.isEmpty)
                    .sheet(isPresented: $isShowingMessages) {
                        SMSComposeMessageUIView(
                            recipients: [defaultGatewayClientMsisdn],
                            body: $encryptedFormattedContent,
                            completion: handleCompletion(_:))
                        .ignoresSafeArea()
                    }
                }
            }
        })
    }

    func getEncryptedContent(isBridge: Bool = false) throws -> String {
        if(!isBridge) {
            let messageComposer = try Publisher.publish(context: context)
            let shortcode: UInt8 = "g".data(using: .utf8)!.first!
            
            return try messageComposer.emailComposer(
                platform_letter: shortcode,
                from: fromAccount,
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody)
        } else {
            let (cipherText, clientPublicKey) = try Bridges.compose(
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                context: context
            )
            if(try !Vault.getLongLivedToken().isEmpty) {
                return try Bridges.payloadOnly(context: context, cipherText: cipherText)!
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
             var messageEntities = MessageEntity(context: context)
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
                } catch {
                    print("Failed to save message entity: \(error)")
                }
            }
        })
    }
    
    func formatEmailForViewing(decryptedData: String) -> (platformLetter: String, to: String, cc: String, bcc: String, subject: String, body: String) {
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

        return EmailComposerView(
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
