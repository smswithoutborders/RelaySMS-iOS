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
    
    let recipientLabel = LocalizedStringResource("Recipients", comment: "Label for where the receipient emails go")
    let subjectLabel = LocalizedStringResource("Subject", comment: "Label for where the subject goes")

    var body: some View {VStack(spacing: 12) {
        // 1. "To" Field
        HStack(spacing: 8) {
            Text(LocalizedStringResource("To:"))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            TextField(text: $to, prompt: Text(recipientLabel)) {
                Text(recipientLabel)
            }
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
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
        
        // 2. "Subject" Field
        HStack(spacing: 8) {
            Text(LocalizedStringResource("Subject:"))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            TextField(text: $subject, prompt: Text(subjectLabel)) {
                Text(subjectLabel)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        
        // MARK: 3. Content TextEditor Field
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
    .padding()}
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
