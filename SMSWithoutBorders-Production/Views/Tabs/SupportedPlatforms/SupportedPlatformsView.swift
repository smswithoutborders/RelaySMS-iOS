//
//  SupportedPlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 30/09/2026.
//

import SwiftUI
import SwiftData

struct SupportedPlatformView: View {
    let displayName: String
    @State var onClick: () -> Void
    
    var body: some View {
        VStack {
            Button(action: {
                onClick()
            }) {
                Text(displayName)
            }
        }
        .padding()
    }
}

struct PlatformSelectedView: View {
    @Query private var accounts: [Tokens]
    
    let displayName: String
    let name: String
    var onAddNewClick: () -> Void
    var onAccountClicked: (Tokens) -> Void
    var onClose: () -> Void
    var onRevoke: (Tokens) -> Void

    init(
        displayName: String,
        name: String,
        onAddNewClick: @escaping () -> Void,
        onAccountClicked: @escaping (Tokens) -> Void,
        onClose: @escaping () -> Void,
        onRevoke: @escaping (Tokens) -> Void,
    ) {
        self.displayName = displayName
        self.name = name
        self.onAddNewClick = onAddNewClick
        self.onAccountClicked = onAccountClicked
        self.onClose = onClose
        self.onRevoke = onRevoke

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
                            onClick: {
                                onAccountClicked(account)
                            },
                            onTrashClicked: {
                                onRevoke(account)
                            }
                        )
                    }
                }
            }
        }
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

struct SupportedPlatformsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \SupportedPlatforms.name)
    private var supportedPlatforms: [SupportedPlatforms]
    
    @State private var viewModel = SupportedPlatformsViewModel()
    
    @State private var platformSelected = false
    @State private var showAccountStats = false
    
    @State private var selectedPlatform: SupportedPlatforms? = nil
    
    @State private var selectedAccount: Tokens? = nil

    @State private var pnbaPhoneNumber: String = ""
    @State private var pnbaCode: String = ""
    @State private var pnbaPassword: String = ""

    @StateObject private var oauthManager = OAuthManager()

    var body: some View {
        VStack {
            List {
                ForEach(supportedPlatforms) { sp in
                    SupportedPlatformView(
                        displayName: sp.displayName,
                        onClick: {
                            selectedPlatform = sp
                        }
                    )
                }
            }
            if case .loading = viewModel.fetchState {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
        }
        .sheet(isPresented: $showAccountStats, onDismiss: {
            showAccountStats = false
            selectedAccount = nil
        }) {
            if selectedAccount != nil {
                AccountStatsView(account: selectedAccount!)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(item: $selectedPlatform, onDismiss: {
            viewModel.setIsStoring(isStoring: false)
            viewModel.setPnbaState(state: .idle)
            viewModel.setState(.idle)

            pnbaCode = ""
            pnbaPhoneNumber = ""
            pnbaPassword = ""
            
            oauthManager.reset()
            selectedPlatform = nil
        }) { platform in
            Group {
                if viewModel.isStoring {
                    ProgressView(String(localized: "Getting things ready.."))
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .controlSize(.large)
                        .presentationDetents([.medium])
                } else if viewModel.pnbaState != .idle {
                    PnbaComponentsView(
                        phoneNumber: $pnbaPhoneNumber,
                        code: $pnbaCode,
                        password: $pnbaPassword,
                        displayName: platform.displayName,
                        showCode: viewModel.pnbaState == .authCodeRequested || viewModel.pnbaState == .passwordRequested,
                        showPassword: viewModel.pnbaState == .passwordRequested,
                        errorMessage: viewModel.pnbaStateFailure,
                        onClick: {
                            Task {
                                await pnbaRequested()
                            }
                        }
                    )
                    .presentationDetents([.medium])
                } else if case .revoking = viewModel.fetchState {
                    RevokeConfirmationView(
                        account: selectedAccount!.account,
                        onCancelClick: {
                            selectedPlatform = nil
                        },
                        onYesClicked: {
                            Task {
                                await revoke()
                            }
                        }
                    )
                    .presentationDetents([.medium])
                }
                else {
                    PlatformSelectedView(
                        displayName: platform.displayName,
                        name: platform.name,
                        onAddNewClick: {
                            Task {
                                if platform.catId == V1PayloadsSupportedProtocols.pnba.rawValue {
                                    await pnbaRequested()
                                } else {
                                    await oauthRequested()
                                }
                                platformSelected = false
                            }
                        },
                        onAccountClicked: { account in
                            selectedAccount = account
                            showAccountStats = true
                        },
                        onClose: { dismiss() },
                        onRevoke: { account in
                            selectedAccount = account
                            viewModel.setState(.revoking)
                        },
                    )
                    .presentationDetents([.medium, .large])
                    .task {
                        selectedAccount = nil
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.fetch(into: modelContext.container)
        }
        .task(id: oauthManager.isCancelled) {
            if oauthManager.isCancelled {
                dismiss()
            }
        }
        .task(id: oauthManager.isAuthenticated) {
            if oauthManager.isAuthenticated {
                dismiss()
            }
        }
        .onChange(of: viewModel.pnbaState) { _, newState in
            if case .complete = newState {
                dismiss()
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
    
    private func pnbaRequested() async{
        do {
            if selectedPlatform!.authProvider == "self" {
                try await viewModel.requestPnba(
                    platform: selectedPlatform!,
                    phoneNumber: pnbaPhoneNumber,
                    code: pnbaCode,
                    password: pnbaPassword,
                    channel: selectedPlatform!.name,
                    into: modelContext.container
                )
            }
        } catch {
            print(error)
        }
    }
    
    private func revoke() async {
        do {
            try await viewModel.revoke(
                selectedAccount!,
                selectedPlatform!.protoId,
                into: modelContext.container
            )
        } catch {
            print(error)
        }
    }
}

#Preview {
    SupportedPlatformView(
        displayName: "RMail",
        onClick: {}
    )
}

#Preview {
    PlatformSelectedView(
        displayName: "RMail",
        name: "rmail",
        onAddNewClick: {},
        onAccountClicked: { _ in },
        onClose: {},
        onRevoke: { _ in },
    )
}

