//
//  InboxView.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 23/02/2025.
//

import SwiftUI

struct InboxDecryptMessageView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    
    @State var textBody = ""
    @State var placeHolder = "Click to paste..."

    var body: some View {
        VStack {
            VStack {
                Text("Paste encrypted text into this box...")
                    .font(.subheadline)
                    .padding(.bottom, 32)

                Text(String(localized:"An example message...\n\nRelaySMS Reply Please paste this entire message in your RelaySMS app\n3AAAAGUoAAAAAAAAAAAAAADN2pJG+1g5bNt1ziT84plbYcgwbbp+PbQHBf7ekxkOO...", comment: "Shows an explain message which can be pasted into the inbox view and decrypted"))
                    .font(.caption2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
            }
            .padding()

            VStack {
                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .disabled(true)
                    }
                    TextEditor(text: $textBody)
                        .font(.caption)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(textBody.isEmpty ? .secondary : .primary, lineWidth: 4)
                )
            }
            
            VStack {
                Button {
                    do {
                        let decryptedText = try Bridges.decryptIncomingMessages(
                            context: context,
                            text: textBody
                        )
                        print(decryptedText)
                        DispatchQueue.background(background: {
                            let date = Int(Date().timeIntervalSince1970)
                            
                            var messageEntities = MessageEntity(context: context)
                            messageEntities.id = UUID()
                            messageEntities.platformName = Bridges.SERVICE_NAME
                            messageEntities.fromAccount = decryptedText.fromAccount
                            messageEntities.toAccount = ""
                            messageEntities.cc = decryptedText.cc
                            messageEntities.bcc = decryptedText.bcc
                            messageEntities.subject = decryptedText.subject
                            messageEntities.body = decryptedText.body
                            messageEntities.date = decryptedText.date
                            messageEntities.type = Bridges.SERVICE_NAME_INBOX

                            DispatchQueue.main.async {
                                do {
                                    try context.save()
                                } catch {
                                    print("Failed to save message entity: \(error)")
                                }
                            }
                        }, completion: {
                            dismiss()
                        })
                    } catch {
                        print("Error decrypting: \(error)")
                    }
                } label: {
                    Text("Decrypt message")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)
                .disabled(textBody.isEmpty)
            }
        }
        .padding()
    }
}

struct NoMessagesInbox: View {
    @Binding var pasteIncomingRequested: Bool
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Image(systemName: "tray")
                    .resizable()
                    .foregroundStyle(Color("SecondaryColor"))
                    .frame(width: 150, height: 120)
                    .padding(.bottom, 7)
                
                Text("No messages in inbox")
                    .foregroundStyle(Color("AccentColor"))
            }
            
            Spacer()
            
            VStack {
                Button {
                    pasteIncomingRequested.toggle()
                } label: {
                    Text("Paste new incoming message")
                }
                .tint(Color("SecondaryColor"))
                .foregroundStyle(Color("AccentColor"))
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 50)
            }
        }
        .navigationTitle("Inbox")
    }
}

struct MessagesPresentInbox: View {
    @FetchRequest var inboxMessages: FetchedResults<MessageEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @Binding var pasteIncomingRequested: Bool
    
    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    init(
        pasteIncomingRequested: Binding<Bool>,
        requestedMessage: Binding<Messages?>,
        emailIsRequested: Binding<Bool>
    ) {
        _pasteIncomingRequested = pasteIncomingRequested
        _requestedMessage = requestedMessage
        _emailIsRequested = emailIsRequested
        
        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "type == %@", Bridges.SERVICE_NAME_INBOX)
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                List(inboxMessages, id: \.self) { message in
                    Card(
                        logo: getImageForPlatform(name: message.platformName!),
                        subject: message.subject!,
                        toAccount: message.toAccount!,
                        messageBody: message.body!,
                        date: Int(message.date)
                    )
                    .onTapGesture {
                        requestedMessage = Messages(
                            subject: message.subject!,
                            data: message.body!,
                            fromAccount: message.fromAccount!,
                            toAccount: message.toAccount!,
                            platformName: message.platformName!,
                            date: Int(message.date)
                        )
                        if message.type == Bridges.SERVICE_NAME_INBOX ||
                            message.type == Bridges.SERVICE_NAME {
                            emailIsRequested.toggle()
                        }
                    }
                }
            }
            VStack {
                Button {
                    pasteIncomingRequested.toggle()
                } label: {
                    Image(systemName: "document.on.clipboard")
                        .font(.system(.title))
                        .frame(width: 57, height: 50)
                        .foregroundColor(Color.white)
                        .padding(.bottom, 7)
                }
                .background(.blue)
                .cornerRadius(18)
                 .shadow(color: Color.black.opacity(0.3),
                         radius: 3,
                         x: 3,
                         y: 3
                 )
            }
            .padding()
        }
        .navigationTitle("Inbox")
    }
    
    func getImageForPlatform(name: String) -> Image {
        let image = platforms.filter { $0.name == name}.first?.image
        if image != nil {
            return Image( uiImage: UIImage(data: image!)!)
        }
        return Image("Logo")
    }
}

struct InboxView: View {
    @FetchRequest var inboxMessages: FetchedResults<MessageEntity>
    
    @State var pasteIncomingMessage = false
    
    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    init(requestedMessage: Binding<Messages?>, emailIsRequested: Binding<Bool>) {
        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "type == %@", Bridges.SERVICE_NAME_INBOX)
        )
        _requestedMessage = requestedMessage
        _emailIsRequested = emailIsRequested
    }
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination: InboxDecryptMessageView(),
                    isActive: $pasteIncomingMessage
                ) {
                    EmptyView()
                }
                
                if inboxMessages.isEmpty {
                    NoMessagesInbox(pasteIncomingRequested: $pasteIncomingMessage)
                } else {
                    MessagesPresentInbox(
                        pasteIncomingRequested: $pasteIncomingMessage,
                        requestedMessage: $requestedMessage,
                        emailIsRequested: $emailIsRequested
                    )
                }
            }
        }
    }
}

struct InboxView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested: Bool = false

        @State var pasteIncomingRequested = false
        return InboxView(
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
        .environment(\.managedObjectContext, container.viewContext)
    }
}

#Preview {
    InboxDecryptMessageView()
}

#Preview {
    @State var pasteIncomingMessage = false
    NoMessagesInbox(pasteIncomingRequested: $pasteIncomingMessage)
}

struct MessagesPresent_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested: Bool = false

        @State var pasteIncomingRequested = false
        return MessagesPresentInbox(
            pasteIncomingRequested: $pasteIncomingRequested,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}
