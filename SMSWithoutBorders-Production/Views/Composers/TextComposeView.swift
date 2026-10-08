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
            TextField("Body", text: $content)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var to = "to"
    @Previewable @State var content = "content"
    TextComposeView(
        content: $content
    )
}
