//
//  SupportedPlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 30/09/2026.
//

import SwiftUI
import SwiftData

struct SupportedPlatform: View {
    let displayName: String
    var body: some View {
        VStack {
            Text(displayName)
        }
        .padding()
    }
}

struct PlatformSelectedView: View {
    let displayName: String
    var onClick: () -> Void
    var body: some View {
        VStack {
            Text("\(displayName) selected")
            Button(action: {
                onClick()
            }) {
                Text("Store")
            }
        }
    }
}

struct SupportedPlatformsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supportedPlatforms: [SupportedPlatforms]
    
    @State private var viewModel = SupportedPlatformsViewModel()
    @State private var platformSelected = false
    @State private var selectedPlatform: SupportedPlatforms? = nil
    
    @StateObject private var oauthManager = OAuthManager()

    var body: some View {
        VStack {
            if case .loading = viewModel.fetchState {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }
            
            List {
                ForEach(supportedPlatforms) { sp in
                    SupportedPlatform( displayName: sp.displayName )
                    .onTapGesture {
                        selectedPlatform = sp
                    }
                }
            }
        }
        .sheet(item: $selectedPlatform) { platform in
            if oauthManager.isAuthenticated {
                Image("checkmark.circle.fill")
            }
            else if viewModel.isStoring {
                ProgressView("Getting things ready..")
                    .progressViewStyle(.circular)
                    .tint(.blue)
                    .controlSize(.large)
            } else {
                PlatformSelectedView(
                    displayName: platform.displayName,
                    onClick: {
                        Task {
                            await oauthRequested()
                            platformSelected = false
                        }
                    }
                )
            }
            
        }
        .task {
            await viewModel.fetch(into: modelContext.container)
        }
    }
    
    private func oauthRequested() async{
        do {
            guard let responseUrl = try await viewModel.requestOAuthUrl(platform: selectedPlatform!) else {
                return
            }
            oauthManager.startOAuthFlow(
                url: responseUrl,
                platformName: selectedPlatform!.name
            )
        } catch {
            print(error)
        }
    }
}

#Preview {
    SupportedPlatform(displayName: "RMail")
}

#Preview {
    PlatformSelectedView(displayName: "RMail", onClick: {})
}
