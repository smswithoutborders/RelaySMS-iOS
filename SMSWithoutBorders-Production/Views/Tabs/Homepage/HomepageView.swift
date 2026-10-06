//
//  HomepageView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 02/10/2026.
//

import SwiftUI
import SwiftData

struct PlatformView: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 8) {
                
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 40)
                
                Text("RMail")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct PlatformsPresentedView: View {
    @Query private var supportedPlatforms: [SupportedPlatforms]
    @Query(sort: \Tokens.platformName) private var accounts: [Tokens]
    
    @State private var selectedPlatform: SupportedPlatforms? = nil
    @State private var selectedAccount: Tokens? = nil
    
    @State var onClick: (Tokens?) -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var groupedAccounts: [SupportedPlatforms] {
        let grouped = Dictionary(grouping: accounts, by: { $0.platformName })
        return supportedPlatforms.filter{ sp in grouped.contains { sp.name == $0.key }}
    }

    var body: some View {
        VStack() {
            HStack {
                Text(String(localized: "Send with..."))
                    .font(.title2)
                Spacer()
            }
            .padding()
            
            if accounts.isEmpty {
                Text(String(localized: "You do not have any platformed saved. Go to platforms to save one, or use the no account option below."))
                    .padding()
            }
            else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(groupedAccounts, id: \.self) { account in
                            PlatformView()
                                .onTapGesture {
                                    selectedPlatform = account
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(item: $selectedPlatform) { platform in
            Group {
                PlatformSelectedView(
                    displayName: platform.displayName,
                    name: platform.name,
                    onAddNewClick: {},
                    onAccountClicked: { account in
                        onClick(account)
                    },
                    onClose: {
                        selectedPlatform = nil
                    }
                )
            }
            .presentationDetents([.medium, .large])
            .padding()
        }
        
    }
}

struct HomepageView: View {
    @State private var isPlatformsPresented = false
    @State private var selectedAccount: Tokens? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                EmptyView()
                    .ignoresSafeArea()
                Spacer()
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    isPlatformsPresented.toggle()
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding() // Adds space from screen edges
            }
            .navigationDestination(item: $selectedAccount) { account in
                ComposerManagerView(
                    account: account,
                    catId: getContentCategories(account)!
                )
            }
            .navigationTitle("Recents")
            .sheet(isPresented: $isPlatformsPresented) {
                Group {
                    PlatformsPresentedView { account in
                        isPlatformsPresented.toggle()
                        selectedAccount = account
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .padding()
        }
    }
    
    private func getContentCategories(_ account: Tokens) -> V1ContentCategories?{
        do {
            return try v1ContentCategoryFromU8(value: UInt8(account.catId))
        } catch {
            print(error)
        }
        return nil
    }
}

#Preview {
    HomepageView()
}

#Preview {
    PlatformsPresentedView { _ in }
}

#Preview {
    PlatformView()
}
