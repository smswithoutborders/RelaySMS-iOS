//
//  MessagingComposeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 05/10/2026.
//

import SwiftUI

struct MessagingComposeView: View {
    @Binding var to: String
    @Binding var content: String
    
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
    @Previewable @State var to = "to"
    @Previewable @State var content = "content"
    MessagingComposeView(
        to: $to,
        content: $content
    )
}
