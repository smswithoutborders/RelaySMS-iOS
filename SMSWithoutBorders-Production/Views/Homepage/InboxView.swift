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
    @State var placeHolder = "Click here to paste message...\n\nExample\n\nRelaySMS Reply Please paste this entire message in your RelaySMS app \n3AAAAGUoAAAAAAAAAAAAAADN2pJG+1g5bNt1ziT84plbYcgwbbp+PbQHBf7ekxkOOdpLAg8QZuFSOH1mJPm4KY4W+CVXW8wsAcV5DnFjkrS9fOfA238QMJr+AwDsIg307O3HQFGEU1lePLknJX59vmx/nI7qmSzAkUlBhbIMWfNK0+oHgtH6sOzkvohhCnTmn/+AhMP3UfVSlzD9wNyCC7FMLgfdbPrv/Jh42WZeTX57Jcx/tSvfxYlzNbnktE0Ny2JSsjGxZp1poTypO2Bn104u1Arqdlc1m5E/MaivXEUT"

    var body: some View {
        VStack {
            Text("Paste encrypted text into this box...")
            VStack {
                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .disabled(true)
                    }
                    TextEditor(text: $textBody)
                        .font(.body)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                }
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
            }
        }
        .padding()
        .navigationTitle("Inbox")
    }
}

struct NoMessagesInbox: View {
    var body: some View {
        VStack {
            VStack {
                Text("No messages in inbox")
                
            }
            VStack {
                Button {
                    
                } label: {
                    Text("Paste new incoming message")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct InboxView: View {
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                InboxDecryptMessageView()
            }
        }
    }
}

#Preview {
    InboxView()
}
