//
//  EmailComposeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI

struct EmailComposeView: View {
    @Binding var to: String
    @Binding var subject: String
    @Binding var content: String
    
    var body: some View {
        VStack {
            LabeledContent {
                TextField("", text: $to)
                    .textFieldStyle(.roundedBorder)
            } label: {
                Text("To:")
            }
            
            LabeledContent {
                TextField("", text: $subject)
                    .textFieldStyle(.roundedBorder)
            } label: {
                Text("Subject:")
            }
            
            TextField("Body", text: $content)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var to = "to"
    @Previewable @State var subject = "subject"
    @Previewable @State var content = "content"
    EmailComposeView(
        to: $to,
        subject: $subject,
        content: $content
    )
}
