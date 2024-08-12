//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import SwiftUI
import MessageUI

struct TextView: View {
    @State var textBody :String = ""
    @State var placeHolder: String = "What's happening?"

    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""
    
    @Binding var globalDismiss: Bool

    @State var platform: PlatformsEntity?
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    private var platformName: String
    private var fromAccount: String

    init(platformName: String, fromAccount: String, globalDismiss: Binding<Bool>) {
        self.platformName = platformName
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))
        
        print("Searching platform: \(platformName)")

        self.fromAccount = fromAccount
        self._globalDismiss = globalDismiss
    }

    var body: some View {
        VStack {
            NavigationView {
                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                                .font(.body)
                                .foregroundColor(.secondary)
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
                                let messageComposer = try Publisher.publish(
                                    platform: platform, context: context)
                                
                                var shortcode: UInt8? = nil
                                shortcode = platform.shortcode!.bytes[0]
                                
                                let encryptedFormattedContent = try messageComposer.textComposer(
                                    platform_letter: shortcode!,
                                    sender: fromAccount,
                                    text: textBody)
                                print("Transmitting to sms app: \(encryptedFormattedContent)")
                                
                                var messageEntities = MessageEntity(context: context)
                                messageEntities.id = UUID()
                                messageEntities.platformName = platformName
                                messageEntities.fromAccount = fromAccount
                                messageEntities.toAccount = ""
                                messageEntities.subject = ""
                                messageEntities.body = textBody
                                messageEntities.date = Int32(Date().timeIntervalSince1970)
                                
                                do {
                                    try context.save()
                                } catch {
                                    print("Failed to save message entity: \(error)")
                                }
                                
                                let vc = ViewController()
                                vc.sendSMS(
                                    message: encryptedFormattedContent,
                                    receipient: defaultGatewayClientMsisdn)
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
        
        @State var globalDismiss = false
        return TextView(platformName: "twitter", fromAccount: "@relaysms", globalDismiss: $globalDismiss)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
