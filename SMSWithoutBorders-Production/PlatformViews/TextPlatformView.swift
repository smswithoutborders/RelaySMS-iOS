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
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(message.platformName)
                    .font(.title)
                    .padding()

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
                Text(message.data)
                    .padding()
                    .frame(height: .infinity)

            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    @State var message = Messages(
        subject: "Hello world",
        data: "The scroll view displays its content within the scrollable content region. As the user performs platform-appropriate scroll gestures, the scroll view adjusts what portion of the underlying content is visible. ScrollView can scroll horizontally, vertically, or both, but does not provide zooming functionality.",
        fromAccount: "fromAccount@gmail.com",
        toAccount: "toAccount@gmail.com",
        platformName: "gmail",
        date: Int(Date().timeIntervalSince1970))
    TextPlatformView(message: message)
}
