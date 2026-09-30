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

struct SupportedPlatformsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supportedPlatforms: [SupportedPlatforms]
    
    @State private var viewModel = SupportedPlatformsViewModel()
    
    var body: some View {
        VStack {
            switch viewModel.fetchState {
            case .loading:
                ProgressView("Fetching platforms...")
            case .failure(let reason):
                Text("Error: \(reason)")
                    .foregroundColor(.red)
            case .idle:
                List {
                    ForEach(supportedPlatforms) { sp in
                        SupportedPlatform(displayName: sp.displayName)
                    }
                }
            }
        }
        .task {
            await viewModel.fetch(into: modelContext.container)
        }
    }
}

#Preview {
    SupportedPlatform(displayName: "RMail")
}
