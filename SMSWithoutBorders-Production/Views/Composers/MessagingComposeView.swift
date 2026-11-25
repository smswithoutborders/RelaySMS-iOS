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
    
    let exampleLabel = LocalizedStringResource("e.g +237123456789", comment: "Label for where the examples goes")

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Text(LocalizedStringResource("To:"))
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .leading)
                    
                    TextField(text: $to, prompt: Text(exampleLabel)) {
                        Text(exampleLabel)
                    }
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .autocorrectionDisabled(true)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text(LocalizedStringResource("Enter the receipient number in international format. e.g +237123456789"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            }
            .padding(.bottom, 20)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $content)
                    .textInputAutocapitalization(.sentences)
                    .scrollContentBackground(.hidden)
                    .frame(height: 180)
                    .padding(8)
                
                if content.isEmpty {
                    Text(LocalizedStringResource("Content"))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.top, 16)
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
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
