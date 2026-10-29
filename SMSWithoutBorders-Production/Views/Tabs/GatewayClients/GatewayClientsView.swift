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
        NavigationStack {
            VStack {
                List {
                    ForEach(gatewayClients) { gc in
                        GatewayClient(msisdn: gc.msisdn)
                    }
                }
                if case .loading = viewModel.fetchState {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                }
                else if case .failure(let reason) = viewModel.fetchState {
                    Text("Error: \(reason)")
                        .foregroundColor(.red)
                }
            }
            .task {
                await viewModel.fetch(into: modelContext.container)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Routing Countries"))
//                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    GatewayClient(msisdn: "+237123456789")
}
