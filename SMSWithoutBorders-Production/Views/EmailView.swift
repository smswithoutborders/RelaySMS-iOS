//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI

struct EmailView: View {
    @State private var userInput :String = "";
    var body: some View {
        VStack {
            VStack {
                // Let's put encrypted text here
                Text(userInput)
            }
            Spacer()
            VStack {
                TextEditor(text: $userInput)
                    .frame(width: 300.0, height: 100.0)
                    .foregroundColor(Color.gray)
                    .overlay(RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.black))
                
                Button("Click me", action: {
                    userInput = ""
                })
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        EmailView()
    }
}
