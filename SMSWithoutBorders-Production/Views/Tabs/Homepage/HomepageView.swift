//
//  HomepageView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 02/10/2026.
//

import SwiftUI
import SwiftData

struct PlatformView: View {
    let name: String
    let displayName: String
    
    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 8) {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 40)
                
                Text(displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 75, height: 100)
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
                Text(LocalizedStringResource("Send with..."))
                    .font(.title2)
                Spacer()
            }
            .padding()
            
            if accounts.isEmpty {
                Text(LocalizedStringResource("You do not have any platformed saved. Go to platforms to save one, or use the no account option below."))
                    .padding()
            }
            else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(groupedAccounts, id: \.self) { platform in
                            PlatformView(
                                name: platform.name,
                                displayName: platform.displayName
                            )
                            .onTapGesture {
                                onClick(platform)
                            }
                        }
                    }
                }
            }
            
            Text(LocalizedStringResource("Always available - No setup required."))
            Button(action: onOfflineClick) {
                GroupBox {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringResource("No account. Sends from a random address e.g 123abc@relaysms.me."))
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            Text(LocalizedStringResource("e.g 123abc@relaysms.me."))
                                .font(.subheadline)
                                .padding(.bottom, 8)
                            Text(LocalizedStringResource("You cannot get replies here."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

private struct Contents : Identifiable {
    let id: UUID
    var to: String
    var subject: String
    var content: String
    var date: Int64
    var platformName: String
    var platformDisplayName: String
    var from: String
    var catId: V1ContentCategories
    var isOfflineFirst: Bool
}


private struct PayloadViews: View {
    let name: String
    @State var contents: Contents

    var body: some View {
        HStack(alignment: .top) {
            Image(name)
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
                .padding(.horizontal, 12)

            if !contents.to.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        let dateFromSeconds = Date(timeIntervalSince1970: TimeInterval(contents.date) / 1000.0)
                        Text(LocalizedStringResource("To:"))
                            .bold()
                        Text(contents.to)
                            .bold()
                            .lineLimit(1)
                        Spacer()
                        Text(dateFromSeconds.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                    }
                    .padding(.bottom, 2)
                    
                    if !contents.subject.isEmpty {
                        Text(contents.subject)
                            .padding(.bottom, 2)
                            .lineLimit(1)
                    }
                    
                    Text(contents.content)
                        .lineLimit(1)
                    
                }
            }
            else {
                VStack(alignment: .center) {
                    Text(contents.content)
                        .lineLimit(2)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

struct HomepageView: View {
    @AppStorage("backupFilenamePrefix") private var backupFilename: String?
    
    @State private var isPlatformsPresented = false
    @State private var isOfflinePresented = false
    @State private var isBackupPresented = false
    @State private var isBackedUpPresented = false
    @State private var selectedPlatform: SupportedPlatforms? = nil
    @State private var isSettingPresented = false
    
    @Query(sort: \Payloads.date, order: .reverse)
    private var payloads: [Payloads]
    
    private var contents: [Contents] {
        payloads.compactMap { payload in
            do {
                let cc = try V1ContentsContainer.deserializeFromStorage(bytes: payload.content)
                return Contents(
                    id: payload.id,
                    to: String(data: cc.getTo()!, encoding: .utf8) ?? "",
                    subject: String(data: cc.getSubject()!, encoding: .utf8) ?? "",
                    content: String(data: cc.getBody(), encoding: .utf8) ?? "",
                    date: payload.date,
                    platformName: payload.platformName,
                    platformDisplayName: payload.platformDisplayName,
                    from: payload.account,
                    catId: try v1ContentCategoryFromU8(value: UInt8(payload.catId)),
                    isOfflineFirst: payload.isOfflineFirst
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
                if contents.isEmpty {
                    VStack(alignment: .center) {
                        Image("no_message")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        Text(LocalizedStringResource("Compose your first message."))
                            .font(.headline)
                    }
                }
                else {
                    List {
                        ForEach(contents) { content in
                            NavigationLink {
                                ContentView(
                                    payloadId: content.id,
                                    catId: content.catId,
                                    platformName: content.platformName,
                                    platformDisplayName: content.platformDisplayName,
                                    subject: content.subject,
                                    from: content.from,
                                    to: content.to,
                                    text: content.content,
                                    isOfflineFirst: content.isOfflineFirst
                                )
                                .toolbar(.hidden, for: .tabBar)
                            } label: {
                                PayloadViews(
                                    name: content.platformName,
                                    contents: content
                                )
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("RelaySMS")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            if backupFilename != nil && !backupFilename!.isEmpty{
                                isBackedUpPresented.toggle()
                            } else {
                                isBackupPresented.toggle()
                            }
                        }) {
                            Label(LocalizedStringResource("Backups"), systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                        
    //                        Divider() // Separator line
    //
    //                        Button(role: .destructive, action: {
    //                        }) {
    //                            Label(LocalizedStringResource("Delete All"), systemImage: "trash")
    //                        }
                        Button(action: { isSettingPresented = true }) {
                            Label(LocalizedStringResource("Settings"), systemImage: "gearshape")
                        }
                    } label: {
                        // The button icon or text that triggers the menu
                        Image(systemName: "ellipsis.circle")
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
            .navigationDestination(isPresented: $isBackedUpPresented) {
                BackedUpView()
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(isPresented: $isBackupPresented) {
                BackupView(onContinueCallback: {
                    isBackedUpPresented.toggle()
                })
                .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(isPresented: $isOfflinePresented) {
                ComposerManagerView(
                    platformName: "rmail",
                    platformDisplayName: "R-Mail",
                    isOfflineFirst: true
                )
                .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(item: $selectedPlatform) { platform in
                ComposerManagerView(
                    platformName: platform.name,
                    platformDisplayName: platform.displayName,
                    catId: getContentCategories(platform.catId)
                )
                .toolbar(.hidden, for: .tabBar)
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
            .sheet(isPresented: $isSettingPresented) {
                SettingsView()
            }
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

#Preview("PayloadViews") {
    let content = Contents(
        id: UUID(),
        to: "developers@afkanerd.com",
        subject: "meeting reminder",
        content: "The design has to communicate indentity vs",
        date: 0,
        platformName: "bluesky",
        platformDisplayName: "Bluesky",
        from: "developers@smswithoutborders.com",
        catId: V1ContentCategories.email,
        isOfflineFirst: true
    )
    PayloadViews(
        name: "bluesky",
        contents: content
    )
}

#Preview("HomepageView") {
//    @Previewable @State var isBackupPresented = false
//    @Previewable @State var isBackedUpPresented = false
    HomepageView()
}

#Preview("PlatformsPresentedView") {
    PlatformsPresentedView(
        onClick: { _ in },
        onOfflineClick: {}
    )
}

#Preview("PlatformView") {
    PlatformView(
        name: "bluesky",
        displayName: "Bluesky"
    )
}

