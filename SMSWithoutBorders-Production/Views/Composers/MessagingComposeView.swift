//
//  MessagingComposeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 05/10/2026.
//

import SwiftUI

struct MessagingComposeView: View {
    @State private var to: String = ""
    @State private var content: String = ""
    
    var body: some View {
        VStack {
            LabeledContent {
                TextField("", text: $to)
                    .textFieldStyle(.roundedBorder)
            } label: {
                Text("To:")
            }
            
            TextField("Body", text: $content)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}

#Preview {
    MessagingComposeView()
}
