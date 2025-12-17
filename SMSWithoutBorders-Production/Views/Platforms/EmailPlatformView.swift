//
//  EmailView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 09/08/2024.
//

import SwiftUI

struct EmailPlatformView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State var message: Messages
    
    @Binding var composeNewMessageRequested: Bool
    @Binding var emailComposeRequested: Bool
    @Binding var requestedPlatformName: String
    @Binding var showImageTransmissionView: Bool

    @State private var showEditImage: Bool = false
    @State private var attachmentImage: Image?

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()

                    VStack(alignment: .leading) {
                        HStack {
                            Text(message.fromAccount)
                                .bold()
                            Text(Date(timeIntervalSince1970: TimeInterval(message.date)), formatter: RelativeDateTimeFormatter())
                                .font(.caption)
                        }
                        .padding(.bottom, 8)

                        Text(message.toAccount)
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                    
                Text(message.data)
                    .padding()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                VStack {
                    EmailAttachmentView(
                        image: $attachmentImage,
                        closeable: false
                    )
                    .border(Color.gray)
                }
                .padding()
            }
            .task {
                if(message != nil) {
                    let uIImage = UIImage(data: Data(bytes: message.image ?? []))
                    attachmentImage = Image(uiImage: uIImage!)
                }
            }
            .navigationTitle(message.subject)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        requestedPlatformName = message.platformName
                        if message.platformName.isEmpty ||
                            message.type == Bridges.SERVICE_NAME { composeNewMessageRequested = true
                        } else {
                            emailComposeRequested = true
                        }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showImageTransmissionView = true
                    } label: {
                        Image(systemName: "paperclip.circle")
                    }
                }
            })
        }
    }
}

struct EmailPlatformView_Preview: PreviewProvider {
    static var previews: some View {
        @State var composeNewMessageRequested: Bool = false
        @State var emailComposeRequested: Bool = false
        @State var showImageTransmissionView: Bool = false
        @State var requestedPlatformName: String = ""
        
        let image: Image? = Image("OnboardingTryExample")
        let pngImage = ImageRenderer(content: image).uiImage?.pngData()

        @State var message = Messages(
            id: UUID(),
            subject: "Hello world",
            data: "Hello world",
            fromAccount: "a@g.com",
            toAccount: "toAccount@gmail.com",
            platformName: "gmail",
            date: Int(Date().timeIntervalSince1970),
            image: [UInt8](pngImage!)
        )
        EmailPlatformView(
            message: message,
            composeNewMessageRequested: $composeNewMessageRequested,
            emailComposeRequested: $emailComposeRequested,
            requestedPlatformName: $requestedPlatformName,
            showImageTransmissionView: $showImageTransmissionView
        )
    }
}
