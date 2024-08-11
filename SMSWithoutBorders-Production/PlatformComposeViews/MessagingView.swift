//
//  MessengerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 12/22/22.
//

import SwiftUI
import MessageUI
import CryptoKit
import ContactsUI
import Combine

struct TextInputField: View {
    let placeHolder: String
    @Binding var textValue: String
    @State var endIcon: Image?
    @State var function: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeHolder)
                .foregroundColor(Color(.placeholderText))
                .offset(y: textValue.isEmpty ? 0 : -25)
                .scaleEffect(textValue.isEmpty ? 1: 0.8, anchor: .leading)
            TextField("", text: $textValue)
        }
        .padding(.top, textValue.isEmpty ? 0 : 15)
        .frame(height: 52)
        .padding(.horizontal, 16)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1).foregroundColor(.gray))
        .overlay(alignment: .trailing) {
            if endIcon != nil {
                Button {
                    function()
                } label: {
                    endIcon!
                        .resizable()
                        .frame(width: 30.0, height: 30.0)
                }
                .padding()
            }
        }
        .animation(.default)
    }
}

struct FieldMultiEntryTextDynamic: View {
    var text: Binding<String>
    
    var body: some View {
        TextEditor(text: text)
            .padding(.vertical, -8)
            .padding(.horizontal, -4)
            .frame(minHeight: 0, maxHeight: 150)
            .font(.custom("HelveticaNeue", size: 17, relativeTo: .headline))
            .foregroundColor(.primary)
            .dynamicTypeSize(.medium ... .xxLarge)
            .fixedSize(horizontal: false, vertical: true)
    } // End Var Body
} // End Struct


extension MessagingView {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
//            controller.dismiss(animated: true)
        }
    }
}

struct MessagingView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    @State var platform: PlatformsEntity?
    
    var decoder: Decoder?
    private let messageComposeDelegate = MessageComposerDelegate()
    
    @State var messageBody :String = ""
    @State var messageContact :String = ""
    
    
    @FetchRequest var messages: FetchedResults<MessageEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    private var platformName: String
    private var fromAccount: String
    
    @FocusState private var isFocused: Bool
    
    
    @State private var pickedNumber: String?
    @StateObject private var coordinator = Coordinator()
    
    var message: Messages?
    @State private var showMessages = false

    init(platformName: String, fromAccount: String, message: Messages? = nil) {
        self.platformName = platformName
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))
        
        if message != nil {
            _messages = FetchRequest<MessageEntity>(
                sortDescriptors: [],
                predicate: NSPredicate(
                    format: "platformName == %@ and toAccount == %@ and fromAccount == %@",
                    platformName, message!.toAccount, message!.fromAccount))
            print("toAccount: \(message!.toAccount), fromAccount: \(message!.fromAccount)")
        }
        else {
            _messages = FetchRequest<MessageEntity>(
                sortDescriptors: [],
                predicate: NSPredicate(
                    format: "platformName == %@", platformName))
        }

        print("Searching platform: \(platformName)")

        self.fromAccount = fromAccount
        self.message = message
    }
    

    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    Text("Select a contact to send a message")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("Make sure phone code e.g +237 is included in the selected number")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    VStack {
                        Text("From: \(fromAccount)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        TextInputField(
                            placeHolder: "To: ",
                            textValue: $messageContact,
                            endIcon: Image("Phonebook"), function: {
                                openContactPicker()
                            })
                        .keyboardType(.phonePad)
                        
                    }
                    .padding()
                    
                    if messages.isEmpty {
                        Spacer()
                        Text("No messages sent")
                            .font(.title)
                        Spacer()
                    }
                    else {
                        List{
                            if message != nil || showMessages {
                                ForEach(messages, id: \.id) { inbox in
                                    Button(action: {}) {
                                        VStack {
                                            Text(inbox.body!)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                            Text(Date(timeIntervalSince1970: TimeInterval(inbox.date)), style: .time)
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack {
                        FieldMultiEntryTextDynamic(text: $messageBody)
                            .padding()
                            .multilineTextAlignment(.leading)
                            .keyboardType(.alphabet)
                            .focused($isFocused)

                        Button {
                            for platform in platforms {
                                do {
                                    let messageComposer = try Publisher.publish(
                                        platform: platform, context: context)
                                    
                                    var shortcode: UInt8? = nil
                                    shortcode = platform.shortcode!.bytes[0]
                                    
                                    messageContact = messageContact.filter{ $0.isWholeNumber }
                                    let encryptedFormattedContent = try messageComposer.messageComposer(
                                        platform_letter: shortcode!,
                                        sender: fromAccount,
                                        receiver: messageContact,
                                        message: messageBody)
                                    
                                    print("Transmitting to sms app: \(encryptedFormattedContent)")
                                    
                                    let date = Int(Date().timeIntervalSince1970)
                                    if message == nil {
                                        showMessages = true
                                    }
                                    
                                    var messageEntities = MessageEntity(context: context)
                                    messageEntities.id = UUID()
                                    messageEntities.platformName = platformName
                                    messageEntities.fromAccount = fromAccount
                                    messageEntities.toAccount = messageContact
                                    messageEntities.subject = messageContact
                                    messageEntities.body = messageBody
                                    messageEntities.date = Int32(date)
                                    
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
                                messageBody = ""
                                break
                            }
                            
                        } label: {
                            Image("MessageSend")
                                .resizable()
                                .frame(width: 25.0, height: 25.0)
                        }
                        .padding()
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 1))
                    .padding()
                }
            }
            .onReceive(coordinator.$pickedNumber, perform: { phoneNumber in
                self.messageContact = phoneNumber ?? ""
            })
            .navigationBarTitle("Compose Message")
        }
        .task {
            if message != nil {
                self.messageContact = message!.toAccount
            }
            print(messages)
        }
    }
    
    func openContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = coordinator
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
        contactPicker.predicateForSelectionOfProperty = NSPredicate(format: "key == 'phoneNumbers'")
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(contactPicker, animated: true, completion: nil)
    }
     
    class Coordinator: NSObject, ObservableObject, CNContactPickerDelegate {
        @Published var pickedNumber: String?
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Clear the pickedNumber initially
            self.pickedNumber = nil
            
            // Check if the contact has selected phone numbers
            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                handlePhoneNumber(phoneNumber)
            }
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            
            if contactProperty.key == CNContactPhoneNumbersKey,
               let phoneNumber = contactProperty.value as? CNPhoneNumber {
                
                let phoneNumberString = phoneNumber.stringValue
                // Now phoneNumberString contains the phone number
                print("Phone Number: \(phoneNumberString)")
                
                // You can now use phoneNumberString as needed
                handlePhoneNumber(phoneNumberString)
            }
        }
        
        private func handlePhoneNumber(_ phoneNumber: String) {
            let phoneNumberWithoutSpace = phoneNumber.replacingOccurrences(of: " ", with: "")
            
            // Check if the phone number starts with "+"
            let sanitizedPhoneNumber = phoneNumberWithoutSpace.hasPrefix("+") ? String(phoneNumberWithoutSpace.dropFirst()) : phoneNumberWithoutSpace
            
            DispatchQueue.main.async {
                self.pickedNumber = sanitizedPhoneNumber
            }
        }
    }
}

struct MessageView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        let message = Messages(
            subject: "Subject",
            data: "Hello world",
            fromAccount: "+137123456781",
            toAccount: "+137123456781", platformName: "telegram",
            date: Int(Date().timeIntervalSince1970))
        
        return MessagingView(platformName: "telegram", fromAccount: "+237123456789", message: message)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
