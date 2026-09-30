//
//  GatewayClientsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 30/09/2026.
//

import SwiftUI
import SwiftData

struct GatewayClient: View {
    let msisdn: String
    var body: some View {
        VStack {
            Text(msisdn)
        }
        .padding()
    }
}

struct GatewayClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var gatewayClients: [GatewayClients]
    
    @State private var viewModel = GatewayClientsViewModel()

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
                    ForEach(gatewayClients) { gc in
                        GatewayClient(msisdn: gc.msisdn)
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
    GatewayClient(msisdn: "+237123456789")
}
