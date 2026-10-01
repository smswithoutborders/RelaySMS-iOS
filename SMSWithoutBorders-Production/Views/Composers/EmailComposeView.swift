//
//  EmailComposeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI

struct EmailComposeView: View {
    @State private var to: String = ""
    @State private var subject: String = ""
    @State private var content: String = ""
    
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
    EmailComposeView()
}
