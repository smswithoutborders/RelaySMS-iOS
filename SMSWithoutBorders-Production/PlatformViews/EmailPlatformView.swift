//
//  EmailView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 09/08/2024.
//

import SwiftUI

struct EmailPlatformView: View {
    @State var message: Messages
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(message.subject)
                        .font(.title)
                        .padding()

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
        }
        .navigationBarTitle(Text(""), displayMode: .inline)
    }
}

struct EmailPlatformView_Preview: PreviewProvider {
    static var previews: some View {
        @State var message = Messages(
            subject: "Hello world",
            data: "Hello world",
            fromAccount: "fromAccount@gmail.com",
            toAccount: "toAccount@gmail.com",
            platformName: "gmail",
            date: Int(Date().timeIntervalSince1970))
        EmailPlatformView(message: message)
    }
}
