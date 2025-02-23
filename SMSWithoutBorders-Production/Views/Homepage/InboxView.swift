//
//  InboxView.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 23/02/2025.
//

import SwiftUI

struct InboxView: View {
    @State var textBody = ""
    @State var placeHolder = "Paste text here..."

    var body: some View {
        VStack {
            Text("Paste encrypted text into this box...")
            VStack {
                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .disabled(true)
                    }
                    TextEditor(text: $textBody)
                        .font(.body)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            
            VStack {
                Button {
                    
                } label: {
                    Text("Decrypt message")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
    }
}

#Preview {
    InboxView()
}
