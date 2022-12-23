//
//  MessengerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 12/22/22.
//

import SwiftUI
import MessageUI


func formatMessageForViewing(decryptedData: String) -> (platformLetter: String, messageContact: String, messageBody: String) {
    let splitString = decryptedData.components(separatedBy: ":")
    
    let platformLetter: String = splitString[0]
    let messageContact: String = splitString[1]
    let messageBody: String = splitString[1]
    
    return (platformLetter, messageContact, messageBody)
}

func formatMessageForPublishing(
    platformLetter: String,
    messageBody: String, messageContact: String) -> String {
        
        let formattedString: String = platformLetter + ":" + messageContact + ":" + messageBody
        
        return formattedString
}

extension MessageView {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
            controller.dismiss(animated: true)
        }
    }
}

struct MessageView: View {
    
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(entity: GatewayClientsEntity.entity(), sortDescriptors: []) var gatewayClientsEntities: FetchedResults<GatewayClientsEntity>

    @State var platform: PlatformsEntity?
    @State var encryptedContent: EncryptedContentsEntity?
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    @State var messageBody :String = ""
    @State var messageContact :String = ""
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    VStack{
                        HStack {
                            Text("To ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField("", text: $messageContact)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    VStack {
                        TextEditor(text: $messageBody)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Color.primary.opacity(0.25))
                            .cornerRadius(16)
                            .accessibilityLabel("textBody")
                            .padding()
                    }
                }
            }
            .navigationBarTitle("Compose Tweet", displayMode: .inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Get formatted input
                        let formattedOutput = formatMessageForPublishing(platformLetter: self.platform!.platform_letter!, messageBody: messageBody, messageContact: messageContact)
                        
                        let encryptedFormattedContent = formatForPublishing(formattedContent: formattedOutput)
                        
                        print("Encrypted formatted content: \(encryptedFormattedContent)")
                        
                        let gatewayClientHandler = GatewayClientHandler(gatewayClientsEntities: gatewayClientsEntities)
                        
                        let defaultGatewayClient: String = gatewayClientHandler.getDefaultGatewayClientMSISDN()
                        
                        print("Default Gateway client: " + defaultGatewayClient)
                        
                        sendSMS(message: encryptedFormattedContent, receipient: defaultGatewayClient, messageComposeDelegate: self.messageComposeDelegate)
                        
                        EncryptedContentHandler.store(datastore: self.datastore, encryptedContentBase64: encryptedFormattedContent, gatewayClientMSISDN: defaultGatewayClient, platformName: self.platform?.platform_name ?? "unknown")
                        
                        self.dismiss()
                    }) {
                        Text("Send")
                    }
                }
            })
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
