//
//  SupportedPlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 30/09/2026.
//

import SwiftUI
import SwiftData

struct AccountView: View {
    let accountId: String
    let displayName: String
    var body: some View {

        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(accountId)
                    .font(.headline)
                Text(displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            Button(action: {
                
            }) {
                Image(systemName: "trash")
                    .foregroundColor(Color.red)
            }
        }
    
    }
}

struct SupportedPlatformView: View {
    let displayName: String
    var body: some View {
        VStack {
            Text(displayName)
        }
        .padding()
    }
}

struct PlatformSelectedView: View {
    @Query private var accounts: [Tokens]
    
    let displayName: String
    let name: String
    var onAddNewClick: () -> Void
    var onAccountClicked: (Tokens?) -> Void
    var onClose: () -> Void
    
    init(
        displayName: String,
        name: String,
        onAddNewClick: @escaping () -> Void,
        onAccountClicked: @escaping (Tokens?) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.displayName = displayName
        self.name = name
        self.onAddNewClick = onAddNewClick
        self.onAccountClicked = onAccountClicked
        self.onClose = onClose
        
        let predicate = #Predicate<Tokens> { token in
            return token.platformName == name
        }
        
        _accounts = Query(filter: predicate, sort: [SortDescriptor(\.date)])
    }

    var body: some View {
        VStack {
            HStack {
                Text(String(localized: "Your \(displayName) account(s)"))
                Spacer()
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "x.circle")
                }
            }
            .padding()
            
            Button(action: {
                onAddNewClick()
            }) {
                Label(String(localized: "Add new"), systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 10)
            
            if accounts.isEmpty {
                Spacer()
                    .frame(maxHeight: 50)
                
                Text(String(localized: "You have not saved any account yet. Click the add button to connect your \(displayName) account."))
            } else {
                Spacer()
                    .frame(maxHeight: 30)
                List {
                    ForEach(accounts) { account in
                        AccountView(
                            accountId: account.account,
                            displayName: account.platformName,
                        )
                        .onTapGesture {
                            onAccountClicked(account)
                        }
                    }
                }
            }
        }
    }
}

struct SupportedPlatformsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \SupportedPlatforms.name)
    private var supportedPlatforms: [SupportedPlatforms]
    
    @State private var viewModel = SupportedPlatformsViewModel()
    @State private var platformSelected = false
    @State private var selectedPlatform: SupportedPlatforms? = nil
    
    @StateObject private var oauthManager = OAuthManager()

    var body: some View {
        VStack {
            List {
                if case .loading = viewModel.fetchState {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                }
                
                ForEach(supportedPlatforms) { sp in
                    SupportedPlatformView( displayName: sp.displayName )
                    .onTapGesture {
                        selectedPlatform = sp
                    }
                }
            }
        }
        .sheet(item: $selectedPlatform) { platform in
            Group {
                if viewModel.isStoring {
                    ProgressView("Getting things ready..")
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .controlSize(.large)
                } else {
                    PlatformSelectedView(
                        displayName: platform.displayName,
                        name: platform.name,
                        onAddNewClick: {
                            Task {
                                await oauthRequested()
                                platformSelected = false
                            }
                        },
                        onAccountClicked: { _ in
                        },
                        onClose: {
                            selectedPlatform = nil
                        }
                    )
                }
            }
            .presentationDetents([.medium, .large])
            .padding()
        }
        .task {
            await viewModel.fetch(into: modelContext.container)
        }
        .task(id: oauthManager.isCancelled) {
            if oauthManager.isCancelled {
                selectedPlatform = nil
                dismiss()
                oauthManager.reset()
                viewModel.setIsStoring(isStoring: false)
            }
        }
        .task(id: oauthManager.isAuthenticated) {
            if oauthManager.isAuthenticated {
                oauthManager.reset()
                viewModel.setIsStoring(isStoring: false)
            }
        }
    }

    private func oauthRequested() async{
        do {
            try await viewModel.requestOAuthUrl(
                platform: selectedPlatform!,
                into: modelContext.container,
                oauthManager: oauthManager
            )
        } catch {
            print(error)
        }
    }
}

#Preview {
    SupportedPlatformView(displayName: "RMail")
}

#Preview {
    PlatformSelectedView(
        displayName: "RMail",
        name: "rmail",
        onAddNewClick: {},
        onAccountClicked: { _ in },
        onClose: {},
    )
}

#Preview {
    AccountView(
        accountId: "developer@relaysms.org",
        displayName: "relaysms"
    )
}
