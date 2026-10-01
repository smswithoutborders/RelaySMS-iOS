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
            if oauthManager.isAuthenticated {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                    Button(action: {
                        selectedPlatform = nil
                    }) {
                        Text("Close")
                    }
                }
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
        .onOpenURL { url in
            dismiss()
            handleIncomingUrl(url)
        }
        .task {
            await viewModel.fetch(into: modelContext.container)
        }
    }
    
    private func handleIncomingUrl(_ url: URL) {
        print("incoming url: \(url)")
    }


    private func oauthRequested() async{
        do {
            guard let (response, requestId) = try await viewModel.requestOAuthUrl(platform: selectedPlatform!) else {
                return
            }
            let oAuthRequest = OAuthManager.OAuthRequest(
                platformName: selectedPlatform!.name,
                codeVerifier: response.codeVerifier,
                requestIdentifier: requestId
            )
            oauthManager.oAuthRequest = oAuthRequest
            
            try oauthManager.startOAuthFlow(
                url: response.authorizationURL,
                platformName: selectedPlatform!.name
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
    PlatformSelectedView(displayName: "RMail", onClick: {})
}
