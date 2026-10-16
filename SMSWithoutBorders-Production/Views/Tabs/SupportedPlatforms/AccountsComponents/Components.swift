//
//  Components.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 15/10/2026.
//

import SwiftUI
import SwiftData

struct AccountStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State var account: Tokens
    
    @State private var numberOfKeys: Int = 0
    @State private var viewModel = TokensViewModel()

    var body: some View {
        VStack {
            Button(action: {
                Task {
                    do {
                        try await viewModel.refreshKeys(
                            account: account,
                            into: modelContext.container
                        )
                        
                        numberOfKeys = viewModel.getCount(
                            tokenId: account.id,
                            into: modelContext.container
                        )
                    } catch {
                        print(error)
                    }
                }
            }) {
                if case .loading = viewModel.tokenStates {
                    ProgressView("")
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .controlSize(.large)
                        .presentationDetents([.medium])
                } else {
                    Text(String(localized: "Refresh keys"))
                }
            }
            
            Text(String(localized: "Number of keys"))
            Text(String(numberOfKeys))
        }
        .task {
            Task {
                numberOfKeys = viewModel.getCount(
                    tokenId: account.id,
                    into: modelContext.container
                )
            }
        }
    }
}

struct RevokeConfirmationView: View {
    @State var account: String
    
    var onCancelClick: () -> Void
    var onYesClicked: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(String(localized: "Are you sure you want to remove this account"))
            Text("\(account)?")
                .bold()

            Spacer()
                .frame(height: 50)
            HStack {
                Spacer()
                Button(String(localized: "Cancel")) {
                    onCancelClick()
                }
                
                Spacer()
                    .frame(width: 20)
                Button(String(localized: "Yes, remove.")) {
                    onYesClicked()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(.red, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

struct AccountView: View {
    let accountId: String
    let displayName: String
    
    var onClick: () -> Void
    var onTrashClicked: () -> Void

    var body: some View {
        HStack {
            Group {
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
                }
            }
            .onTapGesture {
                onClick()
            }
            
            Spacer()
            Button(action: {
                onTrashClicked()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(Color.red)
            }
        }
    
    }
}

//#Preview {
//    AccountView(
//        accountId: "developer@relaysms.org",
//        displayName: "relaysms",
//        onClick: {},
//        onTrashClicked: {}
//    )
//}

#Preview {
    RevokeConfirmationView(
        account: "developer@relaysms.org",
        onCancelClick: {},
        onYesClicked: {}
    )
}
