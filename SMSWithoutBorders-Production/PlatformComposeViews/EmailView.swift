//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import MessageUI
import CryptoKit


extension EmailView {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
            controller.dismiss(animated: true)
        }
    }
}

struct EmailView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""
    
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

    @State var composeTo: String = ""
    @State var composeFrom: String = ""
    @State var composeCC: String = ""
    @State var composeBCC: String = ""
    @State var composeSubject: String = ""
    @State var composeBody: String = ""
    
    private var platformName: String
    private var fromAccount: String

    init(platformName: String, fromAccount: String) {
        self.platformName = platformName
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))
        
        print("Searching platform: \(platformName)")

        self.fromAccount = fromAccount
    }
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    VStack{
                        HStack {
                            Text("From ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField(fromAccount, text: $composeFrom)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(true)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    Spacer(minLength: 9)
                    
                    VStack{
                        HStack {
                            Text("To ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField("", text: $composeTo)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    Spacer(minLength: 9)
                    
                    VStack {
                        HStack {
                            Text("Cc ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField("", text: $composeCC)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    Spacer(minLength: 9)
                    
                    VStack {
                        HStack {
                            Text("Bcc ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField("", text: $composeBCC)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    Spacer(minLength: 9)
                    
                    VStack {
                        HStack {
                            Text("Subject ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField("", text: $composeSubject)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    Spacer(minLength: 9)
                    
                    VStack {
                        TextEditor(text: $composeBody)
                            .accessibilityLabel("composeBody")
                    }
                }
            }
            .padding()
            .navigationTitle("Compose email")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        for platform in platforms {
                            do {
                                let messageComposer = try Publisher.publish(platform: platform, context: context)
                                
                                var shortcode: UInt8? = nil
                                shortcode = platform.shortcode!.bytes[0]
                                
                                let encryptedFormattedContent = try messageComposer.emailComposer(
                                    platform_letter: shortcode!,
                                    from: fromAccount,
                                    to: composeTo,
                                    cc: composeCC,
                                    bcc: composeBCC,
                                    subject: composeSubject,
                                    body: composeBody)
                                print("Transmitting to sms app: \(encryptedFormattedContent)")
                                
                                var messageEntities = MessageEntity(context: context)
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

                                SMSHandler.sendSMS(message: encryptedFormattedContent,
                                                   receipient: defaultGatewayClientMsisdn,
                                        messageComposeDelegate: self.messageComposeDelegate)
                            } catch {
                                print("Some error occured while sending: \(error)")
                            }
                            
                            break
                        }
                        
                        self.dismiss()
                    }) {
                        Text("Send")
                    }
                }
        })
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
        
        return EmailView(platformName: "gmail", 
                         fromAccount: "dev@relay.sms")
            .environment(\.managedObjectContext, container.viewContext)
    }
}
