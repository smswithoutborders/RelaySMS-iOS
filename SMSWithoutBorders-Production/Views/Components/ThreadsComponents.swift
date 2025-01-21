//
//  ThreadsComponents.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

struct Card: View {
    @State var logo: Image
    @State var subject: String
    @State var toAccount: String
    @State var messageBody: String
    @State var date: Int
    
    let radius = 20.0
    var squareSide: CGFloat {
        2.0.squareRoot() * radius
    }

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: radius * 2, height: radius * 2)
                logo
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: squareSide, height: squareSide)
                
            }
            VStack {
                HStack {
                    Text(subject)
                        .bold()
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Date(timeIntervalSince1970: TimeInterval(date)), formatter: RelativeDateTimeFormatter())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.caption)
                }
                .padding(.bottom, 3)

                Text(toAccount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)

                Text(messageBody)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    Card(
        logo: Image("Logo"),
        subject: "Hello world",
        toAccount: "sample@relaysms.me",
        messageBody: "Hello world",
        date: 123456789
    )
}
