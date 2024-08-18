//
//  TextPlatformView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 09/08/2024.
//

import SwiftUI

struct TextPlatformView: View {
    @State var message: Messages

    var body: some View {
        NavigationView {
            VStack {
                Text(message.platformName)
                    .font(.title)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                    
                    HStack {
                        Text(message.fromAccount)
                            .bold()
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
        }
        .navigationBarTitle(Text(""), displayMode: .inline)
    }
}

struct TextPlatformView_Preview: PreviewProvider {
    static var previews: some View {
        @State var message = Messages(
            subject: "Hello world",
            data: "The scroll view displays its content within the scrollable content region. As the user performs platform-appropriate scroll gestures, the scroll view adjusts what portion of the underlying content is visible. ScrollView can scroll horizontally, vertically, or both, but does not provide zooming functionality.",
            fromAccount: "fromAccount@gmail.com",
            toAccount: "toAccount@gmail.com",
            platformName: "twitter",
            date: Int(Date().timeIntervalSince1970))
        TextPlatformView(message: message)
    }
}
