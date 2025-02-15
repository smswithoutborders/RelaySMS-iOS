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

struct EmailView: View {

    @Environment(\.managedObjectContext) var context
    
    #if DEBUG
        private var defaultGatewayClientMsisdn: String = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ? "" : ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        private var defaultGatewayClientMsisdn: String = ""
    #endif
    
    @AppStorage(SecuritySettingsView.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false

//    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

    @State private var encryptedFormattedContent: String = ""
    
    @State var isShowingMessages: Bool = false
    @State var isSendingRequest: Bool = false

    private var platformName: String
    private var isBridge: Bool = false

    @State var composeTo: String = ""
    @State var composeFrom: String = ""
    @State var composeCC: String = ""
    @State var composeBCC: String = ""
    @State var composeSubject: String = ""
    @State var composeBody: String = ""
    @State var fromAccount: String? = nil

    init(platformName: String, fromAccount: String?, isBridge: Bool = false) {
        self.platformName = platformName
        self.isBridge = isBridge
        
//        if(!isBridge) {
//            _platforms = FetchRequest<PlatformsEntity>(
//                sortDescriptors: [],
//                predicate: NSPredicate(format: "name == %@", platformName))
//            print("Searching platform: \(platformName)")
//        }

        self.fromAccount = fromAccount
    }
    
    
    var body: some View {
        EmailComposeView(
            composeTo: $composeTo,
            composeFrom: $composeFrom,
            composeCC: $composeCC,
            composeBCC: $composeBCC,
            composeSubject: $composeSubject,
            composeBody: $composeBody,
            fromAccount: $fromAccount)
        .disabled(isSendingRequest)
        .padding()
        .navigationTitle("Compose email")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                }.sheet(isPresented: $isShowingMessages) {
                    SMSComposeMessageUIView(
                        recipients: [defaultGatewayClientMsisdn],
                        body: $encryptedFormattedContent,
                        completion: handleCompletion(_:))
                    .ignoresSafeArea()
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
                from: fromAccount!,
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
            break
        case .failed:
            print("Damn... failed")
            break
        case .sent:
            print("Yep, all good")
            
            DispatchQueue.background(background: {
                var messageEntities = MessageEntity(context: context)
                messageEntities.id = UUID()
                messageEntities.platformName = platformName
                messageEntities.fromAccount = fromAccount
                messageEntities.toAccount = composeTo
                messageEntities.subject = composeSubject
                messageEntities.body = composeBody
                messageEntities.date = Int32(Date().timeIntervalSince1970)
                do {
                    try context.save()
                } catch {
                    print("Failed to save message entity: \(error)")
                }
                
            })
            break
        @unknown default:
            print("Not even sure what this means")
            break
        }
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
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var globalDimiss = false
        
        return EmailView(platformName: "gmail", 
                         fromAccount: "from1@gmail.com")
            .environment(\.managedObjectContext, container.viewContext)
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
        @State var fromAccount: String? = ""

        return EmailComposeView(
            composeTo: $composeTo,
            composeFrom: $composeFrom,
            composeCC: $composeCC,
            composeBCC: $composeBCC,
            composeSubject: $composeSubject,
            composeBody: $composeBody,
            fromAccount: $fromAccount
        )
    }
}
