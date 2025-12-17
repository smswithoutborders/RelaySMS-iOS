//
//  NotLoggedInMessagesPresentInbox.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//
import SwiftUI

struct NotLoggedInMessagesPresentInbox: View {
    @FetchRequest var inboxMessages: FetchedResults<MessageEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    @State var composeNewRequested = false

    @Binding var composeNewMessageRequested: Bool
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequested: Bool

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    init(
        composeNewMessageRequested: Binding<Bool>,
        loginSheetRequested: Binding<Bool>,
        createAccountSheetRequested: Binding<Bool>,
        requestedMessage: Binding<Messages?>,
        emailIsRequested: Binding<Bool>
    ) {
        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [
                NSSortDescriptor(
                    keyPath: \MessageEntity.date,
                    ascending: false
                )
            ],
            predicate: NSPredicate(format: "type != %@", Bridges.SERVICE_NAME_INBOX)
        )

        _composeNewMessageRequested = composeNewMessageRequested
        _loginSheetRequested = loginSheetRequested
        _createAccountSheetRequested = createAccountSheetRequested
        _requestedMessage = requestedMessage
        _emailIsRequested = emailIsRequested
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                List(inboxMessages, id: \.self) { message in
                    MessageCard(
                        logo: getImageForPlatform(name: message.platformName!),
                        subject: message.subject!,
                        toAccount: message.toAccount!,
                        messageBody: message.body ?? "unkown message",
                        date: Int(message.date)
                    )
                        .onTapGesture {
                            requestedMessage = Messages(
                                id: message.id!,
                                subject: message.subject!,
                                data: message.body!,
                                fromAccount: message.fromAccount!,
                                toAccount: message.toAccount!,
                                platformName: message.platformName!,
                                date: Int(message.date),
                                type: message.type!,
                                image: message.rawImage == nil ? nil : [UInt8](Data(base64Encoded: message.rawImage!)!)
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
                    composeNewRequested.toggle()
                } label: {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                        .frame(width: 48, height: 48)
                        .foregroundColor(Color.white)
                }
                .background(Color("AccentColor"))
                .cornerRadius(12)
        
            }
            .padding()
        }
        .onChange(of: composeNewMessageRequested) { newValue in
            if newValue && requestedMessage == nil {
                composeNewRequested.toggle()
            }
        }
        .onChange(of: loginSheetRequested) { newValue in
            if newValue {
                composeNewRequested.toggle()
            }
        }
        .onChange(of: createAccountSheetRequested) { newValue in
            if newValue {
                composeNewRequested.toggle()
            }
        }
        .sheet(isPresented: $composeNewRequested) {
            VStack(alignment: .center) {
                Text("Get Started")
                    .font(.headline)

                NotLoggedInNoMessages(
                    composeNewMessageRequested: $composeNewMessageRequested,
                    loginSheetRequested: $loginSheetRequested,
                    createAccountSheetRequested: $createAccountSheetRequested
                )
            }
            .padding()
        }
    }

    func getImageForPlatform(name: String) -> Image {
        let image = platforms.filter {
            $0.name == name
        }
        .first?.image
        if image != nil {
            return Image(uiImage: UIImage(data: image!)!)
        }
        return Image("Logo")
    }
}

