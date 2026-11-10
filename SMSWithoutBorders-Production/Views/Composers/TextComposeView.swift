//
//  TextComposeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 05/10/2026.
//

import SwiftUI

struct TextComposeView: View {
    @Binding var content: String
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $content)
                    .textInputAutocapitalization(.sentences)
                    .scrollContentBackground(.hidden)
                    .frame(height: 180)
                    .padding(8)
                
                if content.isEmpty {
                    Text(String(localized: "Content"))
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    @Previewable @State var to = "to"
    @Previewable @State var content = "content"
    TextComposeView(
        content: $content
    )
}
