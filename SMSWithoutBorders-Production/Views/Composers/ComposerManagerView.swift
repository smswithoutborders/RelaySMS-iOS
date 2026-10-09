//
//  ComposerManagerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI

private struct ComposerOnlineSender: View {
    @State var payload: String
    @State private var viewModel = OnlineFirstPublisherViewModel()

    var body: some View {
        VStack(alignment: .center) {
            Text("Debug online transmission")
                .font(.headline)
        }
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text("Payload")
                    .foregroundColor(.secondary)
                Text(payload)
            }
            .padding()

            VStack(alignment: .leading) {
                Text("Response")
                    .foregroundColor(.secondary)
                if case .failure(let reason) = viewModel.sendOnlineState {
                    Text(reason)
                        .foregroundStyle(.red)
                } else if case .success(let reason) = viewModel.sendOnlineState {
                    Text(reason)
                        .foregroundStyle(.blue)
                }
            }
            .padding()

            VStack(alignment: .leading) {
                if case .loading = viewModel.sendOnlineState {
                    ProgressView("Getting things ready..")
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .controlSize(.large)
                }
                Button {
                    Task {
                        do {
                            try await viewModel.sendJsonData(payload)
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Send")
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

extension String: Identifiable {
    public var id: String { self }
}

struct ComposerManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @State var account: Tokens
    @State var catId: V1ContentCategories
    @State private var viewModel = ComposerViewModel()
    
    @State private var to: String = ""
    @State private var subject: String = ""
    @State private var content: String = ""

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
                    EmailComposeView(
                        to: $to,
                        subject: $subject,
                        content: $content
                    )
                case V1ContentCategories.message:
                    MessagingComposeView(
                        to: $to,
                        content: $content
                    )
                case V1ContentCategories.text:
                    TextComposeView(content: $content)
                }
                
                if case .failure(let reason) = viewModel.composeState {
                    Text(reason)
                        .foregroundColor(.red)
                }
                
                if case .loading = viewModel.composeState {
                    ProgressView("Getting things ready..")
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .controlSize(.large)
                }
            }
            .navigationTitle("Compose manager")
            .sheet( item: $viewModel.payload, onDismiss: { viewModel.payload = nil }) { item in
                if !item.isEmpty {
                    VStack {
                        ComposerOnlineSender(payload: item)
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .toolbar {
                Button(action: {
                    Task {
                        do {
                            try await viewModel.publish(
                                catId: catId,
                                body: content,
                                platformName: account.platformName,
                                tokenId: account.id,
                                to: to,
                                subject: subject,
                                into: modelContext.container
                            )
                        } catch {
                            print(error)
                        }
                    }
                }) {
                    Label("Send", systemImage: "paperplane.circle")
                }
                .disabled(viewModel.composeState == .loading)
            }
        }
    }
}


#Preview {
    ComposerOnlineSender(payload: "Sample payload")
}
