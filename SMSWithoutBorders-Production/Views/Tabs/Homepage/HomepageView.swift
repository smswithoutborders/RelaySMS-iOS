//
//  HomepageView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 02/10/2026.
//

import SwiftUI
import SwiftData

struct PlatformView: View {
    @State var displayName: String
    
    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 8) {
                
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 40)
                
                Text(displayName)
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
    
    @State var onClick: (SupportedPlatforms) -> Void
    @State var onOfflineClick: () -> Void

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
        VStack(spacing: 20) {
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
                        ForEach(groupedAccounts, id: \.self) { platform in
                            PlatformView(displayName: platform.displayName)
                                .onTapGesture {
                                    onClick(platform)
                                }
                        }
                    }
                }
            }
            
            Text(String(localized: "Always available - No setup required."))
            Button(action: onOfflineClick) {
                Form {
                    Section {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "No account. Sends from a random address e.g 123abc@relaysms.me."))
                                    .font(.subheadline)
                                Text(String(localized: "You cannot get replies here."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
    }
}

private struct Contents : Identifiable {
    let id: UUID = UUID()
    var to: String
    var subject: String
    var content: String
    var date: Int64
}


private struct PayloadViews: View {
    @State var contents: Contents

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                HStack {
                    let dateFromSeconds = Date(timeIntervalSince1970: TimeInterval(contents.date))
                    Text("To:")
                        .bold()
                    Text(contents.to)
                        .bold()
                        .lineLimit(1)
                    Spacer()
                    Text(dateFromSeconds.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                }
                .padding(.bottom, 2)
                Text(contents.subject)
                    .padding(.bottom, 2)
                    .lineLimit(1)
                Text(contents.content)
                    .lineLimit(1)
            }
        }
    }
}

struct HomepageView: View {
    @State private var isPlatformsPresented = false
    @State private var isOfflinePresented = false
    @State private var selectedPlatform: SupportedPlatforms? = nil
    
    @Query(sort: \Payloads.date, order: .reverse)
    private var payloads: [Payloads]
    
    private var contents: [Contents] {
        payloads.compactMap { payload in
            do {
                let cc = try V1ContentsContainer.deserializeFromStorage(bytes: payload.content)
                return Contents(
                    to: String(data: cc.getTo()!, encoding: .utf8) ?? "",
                    subject: String(data: cc.getSubject()!, encoding: .utf8) ?? "",
                    content: String(data: cc.getBody(), encoding: .utf8) ?? "",
                    date: payload.date
                )
            } catch {
                print("Failed to deserialize payload:", error)
                return nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                    .ignoresSafeArea()
                List {
                    ForEach(contents) { content in
                        PayloadViews(contents: content)
                            .padding()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("RelaySMS")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    isPlatformsPresented.toggle()
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title)
                        .padding()
                        .background(Color(.primary))
                        .foregroundColor(Color(.onPrimary))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding() // Adds space from screen edges
            }
            .navigationDestination(isPresented: $isOfflinePresented) {
                ComposerManagerView(
                    platformName: "rmail",
                    platformDisplayName: "R-Mail"
                )
            }
            .navigationDestination(item: $selectedPlatform) { platform in
                ComposerManagerView(
                    platformName: platform.name,
                    platformDisplayName: platform.displayName,
                    catId: getContentCategories(platform.catId)
                )
            }
            .sheet(isPresented: $isPlatformsPresented) {
                Group {
                    PlatformsPresentedView(
                        onClick: { platform in
                            isPlatformsPresented.toggle()
                            selectedPlatform = platform
                        },
                        onOfflineClick: {
                            isPlatformsPresented = false
                            isOfflinePresented = true
                        }
                    )
                }
                .presentationDetents([.medium, .large])
            }
            .padding()
            
        }
    }
    
    private func getContentCategories(_ catId: Int) -> V1ContentCategories?{
        do {
            return try v1ContentCategoryFromU8(value: UInt8(catId))
        } catch {
            print(error)
        }
        return nil
    }
}

#Preview {
    let content = Contents(
        to: "developers@afkanerd.com",
        subject: "meeting reminder",
        content: "The design has to communicate indentity vs",
        date: 0
    )
    PayloadViews(contents: content)
}

#Preview {
    HomepageView()
}

#Preview {
    PlatformsPresentedView(
        onClick: { _ in },
        onOfflineClick: {}
    )
}

#Preview {
    PlatformView(
        displayName: "Bluesky"
    )
}

