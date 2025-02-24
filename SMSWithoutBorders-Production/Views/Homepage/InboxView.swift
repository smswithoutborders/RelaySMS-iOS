//
//  InboxView.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 23/02/2025.
//

import SwiftUI

struct InboxDecryptMessageView: View {
    @Environment(\.managedObjectContext) var context
    
    @State var textBody = ""
    @State var placeHolder = "Click to paste..."

    var body: some View {
        VStack {
            VStack {
                Text("Paste encrypted text into this box...")
                    .font(.subheadline)
                    .padding(.bottom, 32)

                Text("An example message...\n\nRelaySMS Reply Please paste this entire message in your RelaySMS app\n3AAAAGUoAAAAAAAAAAAAAADN2pJG+1g5bNt1ziT84plbYcgwbbp+PbQHBf7ekxkOO...")
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
                            messageEntities.type = Bridges.SERVICE_NAME

                            DispatchQueue.main.async {
                                do {
                                    try context.save()
                                } catch {
                                    print("Failed to save message entity: \(error)")
                                }
                            }
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
        .navigationTitle("Inbox")
    }
}

struct NoMessagesInbox: View {
    @Binding var pasteIncomingRequested: Bool
    
    var body: some View {
        VStack {
            VStack {
                Text("No messages in inbox")
            }
            VStack {
                Button {
                    pasteIncomingRequested.toggle()
                } label: {
                    Text("Paste new incoming message")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct MessagesPresentInbox: View {
    @FetchRequest var inboxMessages: FetchedResults<MessageEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @Binding var pasteIncomingRequested: Bool

    init(pasteIncomingRequested: Binding<Bool>) {
        _pasteIncomingRequested = pasteIncomingRequested
        
        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "type == %@", Bridges.SERVICE_NAME)
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
    
    init() {
        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "type == %@", Bridges.SERVICE_NAME)
        )
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
                    MessagesPresentInbox(pasteIncomingRequested: $pasteIncomingMessage)
                }
            }
        }
    }
}

struct InboxView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var pasteIncomingRequested = false
        return InboxView()
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
        
        @State var pasteIncomingRequested = false
        return MessagesPresentInbox(pasteIncomingRequested: $pasteIncomingRequested)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
