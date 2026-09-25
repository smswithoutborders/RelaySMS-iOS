//
//  InboxView.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 23/02/2025.
//

import SwiftUI


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
                    destination: DecryptMessageView(),
                    isActive: $pasteIncomingMessage
                ) {
                    EmptyView()
                }

                if inboxMessages.isEmpty {
                    NoMessagesInbox(pasteIncomingRequested: $pasteIncomingMessage)
                } else {
                    MessagesList(
                        pasteIncomingRequested: $pasteIncomingMessage,
                        requestedMessage: $requestedMessage,
                        emailIsRequested: $emailIsRequested
                    )
                }
            }
            .navigationTitle("Inbox")
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



