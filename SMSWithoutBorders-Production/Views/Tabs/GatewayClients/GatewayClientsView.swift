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
    let country: String

    @State var onSetAsDefaultClicked: () -> Void
    
    @State private var showSetAsDefault = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showSetAsDefault.toggle()
            }) {
                VStack(alignment: .leading) {
                    Text(msisdn)
                    Text(country)
                        .font(.caption)

                }
            }
            .buttonStyle(.plain)
            
            if showSetAsDefault {
                Button(String(localized: "Set as default")) {
                    onSetAsDefaultClicked()
                }
                .buttonStyle(.bordered)
                .padding(.top, 10)
            }
        }
        .padding()
    }
}

struct DefaultGatewayClientView: View {
    let msisdn: String
    let country: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(msisdn)
                .font(.headline)
            
            Text(country)
                .font(.caption)
        }
        .padding()
    }
}

struct GatewayClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var gatewayClients: [GatewayClients]
    
    @State private var viewModel = GatewayClientsViewModel()
    
    @State private var toggleShowDefault: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Form {
                    Section(String(localized: "Routing address")) {
                        DefaultGatewayClientView(
                            msisdn: viewModel.defaultGatewayClient?.msisdn ?? "",
                            country: viewModel.defaultGatewayClient?.country ?? ""
                        )
                    }
                    Section(String(localized: "Available routing numbers")) {
                        List {
                            ForEach(gatewayClients) { gc in
                                if gc.msisdn != viewModel.defaultGatewayClient?.msisdn {
                                    GatewayClient(
                                        msisdn: gc.msisdn,
                                        country: gc.country,
                                        onSetAsDefaultClicked: {
                                            viewModel.setAsDefault(
                                                gatewayClient: gc,
                                                into: modelContext.container
                                            )
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
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
    GatewayClient(
        msisdn: "+237123456789",
        country: "Cameroon",
        onSetAsDefaultClicked: {}
    )
}

#Preview {
    DefaultGatewayClientView(
        msisdn: "+123456789",
        country: "Cameroon"
    )
}
