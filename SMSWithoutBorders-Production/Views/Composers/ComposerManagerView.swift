//
//  ComposerManagerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import SwiftUI
import SwiftData

private struct FromViewComponent: View {
    @State var accountName: String
    @State var platformName: String
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 20)
            
            VStack(alignment: .leading) {
                Text(accountName)
                Text(platformName)
            }
        }
    }
}

private struct FromView: View {
    @Query private var accounts: [Tokens]
    @Binding var selectedAccount: Tokens?
    
    let name: String
    
    init(
        name: String,
        fromAccount: Binding<Tokens?>
    ) {
        self.name = name
        _selectedAccount = fromAccount
        
        let predicate = #Predicate<Tokens> { token in
            return token.platformName == name
        }
        
        _accounts = Query(filter: predicate, sort: [SortDescriptor(\.date)])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                Picker(selectedAccount?.account ?? String(localized: "Select an account"), selection: $selectedAccount) {
                    ForEach(accounts, id: \.self) { account in
                        FromViewComponent(
                            accountName: account.account,
                            platformName: account.platformName
                        )
                        .tag(account)
                    }
                }
                .pickerStyle(.inline) // Removes the default picker section separation
            } label: {
                HStack {
                    Text(selectedAccount?.account ?? String(localized: "Select an account..."))
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding()
    }
}

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
    @Environment(\.dismiss) private var dismiss
    @Query private var gatewayClients: [GatewayClients]

    @State private var account: Tokens? = nil
    @State var platformName: String
    @State var platformDisplayName: String
    @State var catId: V1ContentCategories? = nil
    @State var debugSendIsPresented: Bool = false
    @State var isOfflineFirst: Bool = false
    
    @State private var isRoutingRequired: Bool = false

    @State private var viewModel = ComposerViewModel()
    
    @State var to: String = ""
    @State var subject: String = ""
    @State var content: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                if isOfflineFirst {
                    EmailComposeView(
                        to: $to,
                        subject: $subject,
                        content: $content
                    )
                } else {
                    FromView(name: platformName, fromAccount: $account)
                    
                    switch(self.catId!) {
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
                        ProgressView(String(localized: "Getting things ready.."))
                            .progressViewStyle(.circular)
                            .tint(.blue)
                            .controlSize(.large)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle(platformDisplayName + " " + String(localized: "compose"))
            .sheet(isPresented: $debugSendIsPresented, onDismiss: { viewModel.payload = nil }) {
                if viewModel.payload != nil {
                    VStack {
                        ComposerOnlineSender(payload: viewModel.payload!)
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(item: $viewModel.payload, onDismiss: { viewModel.payload = nil }) { item in
                MessageComposer(
                    body: viewModel.payload!,
                    recipients: [gatewayClients.first{ $0.isDefault == true }?.msisdn ?? gatewayClients.first?.msisdn ?? ""],
                ) { result in
                    switch result {
                        case .sent:
                        print("Sent")
                        dismiss()
                        
                        case .cancelled:
                        print("Cancelled")
                        case .failed:
                        print("Failed")
                        @unknown default: break
                    }
                }
            }
            .sheet(isPresented: $isRoutingRequired, onDismiss: {
            }) {
                GatewayClientsView(
                    isSending: true,
                    isSendingCallback: {
                        sendTask()
                        #if DEBUG
                        debugSendIsPresented = true
                        #endif
                        isRoutingRequired = false
                    }
                )
            }
            .toolbar {
                #if DEBUG
                Button(action: {
                    isRoutingRequired = true
                }) {
                    Label("Send", systemImage: "cloud")
                }
                .disabled(viewModel.composeState == .loading)
                #endif
                
                Button(action: {
                    isRoutingRequired = true
                }) {
                    Label(String(localized: "Send"), systemImage: "paperplane.circle")
                }
                .disabled(
                    viewModel.composeState == .loading ||
                    (!isOfflineFirst && account == nil) ||
                    content.isEmpty
                )
            }
        }
    }
    
    private func sendTask() {
        Task {
            do {
                if account != nil && catId != nil {
                    try await viewModel.publishOnlineFirst(
                        catId: catId!,
                        body: content,
                        platformName: account!.platformName,
                        platformDisplayName: platformDisplayName,
                        tokenId: account!.id,
                        to: to,
                        subject: subject,
                        account: account!.account,
                        into: modelContext.container
                    )
                } else {
                    try await viewModel.publishOfflineFirst(
                        platformName: "rmail",
                        platformDisplayName: platformDisplayName,
                        catId: V1ContentCategories.email,
                        body: content,
                        to: to,
                        subject: subject,
                        into: modelContext.container
                    )
                }
            } catch {
                print(error)
            }
        }
    }
}


#Preview {
    ComposerOnlineSender(payload: "Sample payload")
}

#Preview {
    FromViewComponent(accountName: "person@relaysms.me", platformName: "relaysms")
}
