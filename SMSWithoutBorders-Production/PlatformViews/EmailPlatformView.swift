//
//  EmailView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 09/08/2024.
//

import SwiftUI

struct EmailPlatformView: View {
    @State var message: Messages
    
    @Binding var composeNewMessageRequested: Bool
    @Binding var emailComposeRequested: Bool
    @Binding var requestedPlatformName: String

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(message.fromAccount)
                                    .bold()
                                Text(Date(timeIntervalSince1970: TimeInterval(message.date)), formatter: RelativeDateTimeFormatter())
                                    .font(.caption)
                            }
                            HStack {
                                Text(message.toAccount)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    
                }
                    
                Text(message.data)
                    .padding()
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
            }
            .navigationTitle(message.subject)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        requestedPlatformName = message.platformName
                        if message.platformName == Bridges.SERVICE_NAME {
                            composeNewMessageRequested.toggle()
                        } else {
                            emailComposeRequested = true
                        }
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        
                    } label: {
                        Image(systemName: "trash.circle")
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
        @State var requestedPlatformName: String = ""

        @State var message = Messages(
            subject: "Hello world",
            data: "Hello world",
            fromAccount: "fromAccount@gmail.com",
            toAccount: "toAccount@gmail.com",
            platformName: "gmail",
            date: Int(Date().timeIntervalSince1970))
        EmailPlatformView(
            message: message,
            composeNewMessageRequested: $composeNewMessageRequested,
            emailComposeRequested: $emailComposeRequested,
            requestedPlatformName: $requestedPlatformName
        )
    }
}
