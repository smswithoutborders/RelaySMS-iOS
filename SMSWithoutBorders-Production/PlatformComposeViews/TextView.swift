//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import SwiftUI
import MessageUI

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
    @State var placeHolder: String = "What's happening?"

    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    @State var platform: PlatformsEntity?
    @State var encryptedContent: EncryptedContentsEntity?
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
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

    var body: some View {
        VStack {
            NavigationView {
                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                                .font(.body)
                                .foregroundColor(.gray)
                                .disabled(true)
                                .padding()
                    }
                    TextEditor(text: $textBody)
                        .font(.body)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                }
            }
            .navigationBarTitle("Compose Post")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        for platform in platforms {
                            do {
                                let messageComposer = try Publisher.publish(platform: platform, context: datastore)
                                
                                var shortcode: UInt8? = nil
                                shortcode = platform.shortcode!.bytes[0]
                                
                                let encryptedFormattedContent = try messageComposer.textComposer(
                                    platform_letter: shortcode!,
                                    sender: fromAccount,
                                    text: textBody)
                                print("Transmitting to sms app: \(encryptedFormattedContent)")
                                
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
                        Text("Post")
                    }
                }
            })
        }
    }
}

struct TextView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return TextView(platformName: "twitter", fromAccount: "@relaysms")
            .environment(\.managedObjectContext, container.viewContext)
    }
}
