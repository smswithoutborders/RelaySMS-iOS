//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import MessageUI


struct EmailView: View {
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(entity: GatewayClientsEntity.entity(), sortDescriptors: []) var gatewayClientsEntities: FetchedResults<GatewayClientsEntity>

    @State var platform: PlatformsEntity?
    @State var encryptedContent: EncryptedContentsEntity?
    
    @State var composeTo :String = ""
    @State var composeCC :String = ""
    @State var composeBCC :String = ""
    @State var composeSubject :String = ""
    @State var composeBody :String = ""
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    var body: some View {
        NavigationView {
            Group {
                VStack {
                    VStack{
                        HStack {
                            Text("To ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField(self.composeTo, text: $composeTo)
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
        }
        .navigationBarTitle("Compose email", displayMode: .inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // TODO: Get formatted input
                    let formattedEmail = formatEmailForPublishing(platformLetter: self.platform!.platform_letter!, to: composeTo, cc: composeCC, bcc: composeBCC, subject: composeSubject, body: composeBody)
                    
                    let encryptedFormattedContent = formatForPublishing(formattedContent: formattedEmail)
                    
                    print("Encrypted formatted content: \(encryptedFormattedContent)")
                    
                    let gatewayClientHandler = GatewayClientHandler(gatewayClientsEntities: gatewayClientsEntities)
                    
                    let defaultGatewayClient: String = gatewayClientHandler.getDefaultGatewayClientMSISDN()
                    
                    print("Default Gateway client: " + defaultGatewayClient)
                    
                    self.sendSMS(message: encryptedFormattedContent, receipient: defaultGatewayClient)
                    
                    EncryptedContentHandler.store(datastore: datastore, encryptedContentBase64: encryptedFormattedContent, gatewayClientMSISDN: defaultGatewayClient, platformName: platform?.platform_name ?? "unknown")
                    
                    self.dismiss()
                }) {
//                    Image(systemName: "paperplane.circle.fill")
//                        .imageScale(.large)
                    Text("Send")
                }
            }
        })
    }
}

extension EmailView {
    public func sendSMS(message: String, receipient: String) {
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self.messageComposeDelegate
        messageVC.recipients = [receipient]
        messageVC.body = message
        
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        
        if MFMessageComposeViewController.canSendText() {
            vc?.present(messageVC, animated: true)
        }
        else {
            print("User hasn't setup Messages.app")
        }
    }
    
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
            controller.dismiss(animated: true)
        }
    }
}

struct EmailView_Preview: PreviewProvider {
    @State static var platforms: PlatformsEntity?
    @State static var encryptedContent: EncryptedContentsEntity?
    static var previews: some View {
        EmailView(platform: platforms, encryptedContent: encryptedContent)
    }
}
