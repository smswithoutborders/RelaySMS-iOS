//
//  ComposerManagerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI

struct ComposerManagerView: View {
    @State private var viewModel = ComposerViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                EmailComposeView()
            }
            .navigationTitle("Compose manager")
            .toolbar {
                Button(action: {
                    viewModel.publish()
                }) {
                    Label("Send", systemImage: "paperplane.circle")
                }
            }
        }
    }
}

#Preview {
    ComposerManagerView()
}
