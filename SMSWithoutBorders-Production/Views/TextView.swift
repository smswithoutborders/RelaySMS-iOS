//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import SwiftUI
import MessageUI

func formatTextForViewing(decryptedData: String) -> (platformLetter: String, textBody: String) {
    let splitString = decryptedData.components(separatedBy: ":")
    
    let platformLetter: String = splitString[0]
    let textBody: String = splitString[1]
    
    return (platformLetter, textBody)
}

extension UITextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear //<<here clear
//            drawsBackground = true
        }

    }
}

func formatTextForPublishing(
    platformLetter: String, textBody: String) -> String {
        
        let formattedString: String = platformLetter + ":" + textBody
        
        return formattedString
}

extension TextView {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
            controller.dismiss(animated: true)
        }
    }
}

struct TextView: View {
    @State var textBody :String = ""
    
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(entity: GatewayClientsEntity.entity(), sortDescriptors: []) var gatewayClientsEntities: FetchedResults<GatewayClientsEntity>

    @State var platform: PlatformsEntity?
    @State var encryptedContent: EncryptedContentsEntity?
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    TextEditor(text: $textBody)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.primary.opacity(0.25))
                        .cornerRadius(16)
                        .accessibilityLabel("textBody")
                        .padding()
                }
                .onAppear() {
                    UITextView.appearance().backgroundColor = .clear
                }
                .onDisappear() {
                    UITextView.appearance().backgroundColor = nil
                }
            }
            .navigationBarTitle("Compose Tweet", displayMode: .inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Get formatted input
//                        let formattedOutput = formatTextForPublishing(platformLetter: self.platform!.platform_letter!, textBody: textBody)
//                        
//                        let encryptedFormattedContent = formatForPublishing(formattedContent: formattedOutput)
//                        
//                        print("Encrypted formatted content: \(encryptedFormattedContent)")
//                        
//                        let gatewayClientHandler = GatewayClientHandler(gatewayClientsEntities: gatewayClientsEntities)
//                        
//                        let defaultGatewayClient: String = gatewayClientHandler.getDefaultGatewayClientMSISDN()
//                        
//                        print("Default Gateway client: " + defaultGatewayClient)
//                        
//                        sendSMS(message: encryptedFormattedContent, receipient: defaultGatewayClient, messageComposeDelegate: self.messageComposeDelegate)
//                        
//                        EncryptedContentHandler.store(datastore: self.datastore, encryptedContentBase64: encryptedFormattedContent, gatewayClientMSISDN: defaultGatewayClient, platformName: self.platform?.platform_name ?? "unknown")
                        
                        self.dismiss()
                    }) {
                        Text("Tweet")
                    }
                }
            })
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextView()
    }
}
