//
//  TextPlatformView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 09/08/2024.
//

import SwiftUI

struct TextPlatformView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @State var message: Messages
    
    @Binding var textComposeRequested: Bool
    @Binding var requestPlatformName: String

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                    
                    HStack {
                        Text(Date(timeIntervalSince1970: TimeInterval(message.date)), formatter: RelativeDateTimeFormatter())
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(message.data)
                    .padding()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .navigationTitle(message.fromAccount)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        requestPlatformName = message.platformName
                        textComposeRequested = true
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Messages.deleteMessage(context: context, message: message)
                        dismiss()
                    } label: {
                        Image(systemName: "trash.circle")
                    }
                }
            })
        }
    }
}

struct TextPlatformView_Preview: PreviewProvider {
    static var previews: some View {
        @State var textComposeRequested: Bool = false
        @State var requestedPlatformName: String = "twitter"

        @State var message = Messages(
            id: UUID(),
            subject: "Hello world",
            data: "The scroll view displays its content within the scrollable content region. As the user performs platform-appropriate scroll gestures, the scroll view adjusts what portion of the underlying content is visible. ScrollView can scroll horizontally, vertically, or both, but does not provide zooming functionality.",
            fromAccount: "@afkanerd",
            toAccount: "toAccount@gmail.com",
            platformName: "twitter",
            date: Int(Date().timeIntervalSince1970))
        TextPlatformView(
            message: message,
            textComposeRequested: $textComposeRequested,
            requestPlatformName: $requestedPlatformName
        )
    }
}
