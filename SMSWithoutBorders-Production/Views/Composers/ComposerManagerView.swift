//
//  ComposerManagerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI

struct ComposerManagerView: View {
    @State var account: Tokens
    @State var catId: V1ContentCategories
    @State private var viewModel = ComposerViewModel()
    
    init(
        account: Tokens,
        catId: V1ContentCategories,
    ) {
        self.account = account
        self.catId = catId
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch(self.catId) {
                case V1ContentCategories.email:
                    EmailComposeView()
                case V1ContentCategories.message:
                    MessagingComposeView()
                case V1ContentCategories.text:
                    TextComposeView()
                }
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

