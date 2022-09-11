//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI

struct EmailView: View {
    @State private var composeTo :String = ""
    @State private var composeCC :String = ""
    @State private var composeBCC :String = ""
    @State private var composeSubject :String = ""
    @State private var composeBody :String = ""
    
    @State private var encryptedInput: String = ""
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("To: ")
                    Spacer()
                    TextEditor(text: $composeTo)
                        .frame(width: 300.0, height: 50.0)
                        .overlay(RoundedRectangle(cornerRadius: 1)
                            .stroke(Color.black))
                }
                
                HStack {
                    Text("cc: ")
                    Spacer()
                    TextEditor(text: $composeCC)
                        .frame(width: 300.0, height: 50.0)
                        .overlay(RoundedRectangle(cornerRadius: 1)
                            .stroke(Color.black))
                }
                
                HStack {
                    Text("bcc: ")
                    Spacer()
                    TextEditor(text: $composeBCC)
                        .frame(width: 300.0, height: 50.0)
                        .overlay(RoundedRectangle(cornerRadius: 1)
                            .stroke(Color.black))
                }
                
                HStack {
                    Text("subject: ")
                    Spacer()
                    TextEditor(text: $composeSubject)
                        .frame(width: 300.0, height: 50.0)
                        .overlay(RoundedRectangle(cornerRadius: 1)
                            .stroke(Color.black))
                }
                
            }
            Spacer()
            VStack(alignment: .leading) {
                Text("Compose Email")
                    .multilineTextAlignment(.leading)
                TextEditor(text: $composeBody)
                    .frame(height: 450.0)
                    .foregroundColor(Color.gray)
                    .overlay(RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.black))
                
            }
            VStack {
                Button("Send", action: {
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
