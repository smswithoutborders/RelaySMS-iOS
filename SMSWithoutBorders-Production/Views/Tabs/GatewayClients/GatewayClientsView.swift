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
    
    @State var onSetAsDefaultClicked: () -> Void
    
    @State private var showSetAsDefault = false

    var body: some View {
        VStack {
            Text(msisdn)
                .onTapGesture {
                    showSetAsDefault.toggle()
                }
            
            if showSetAsDefault {
                Button(String(localized: "Set as default")) {
                    onSetAsDefaultClicked()
                }
                .padding()
            }
        }
        .padding()
    }
}

struct DefaultGatewayClientView: View {
    let msisdn: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(String(localized: "Routing address"))
                .font(.title)
            
            Text(msisdn)
                .font(.headline)
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
            VStack {
                DefaultGatewayClientView(
                    msisdn: viewModel.defaultGatewayClient?.msisdn ?? ""
                )
                
                List {
                    ForEach(gatewayClients) { gc in
                        if gc.msisdn != viewModel.defaultGatewayClient?.msisdn {
                            GatewayClient(
                                msisdn: gc.msisdn,
                                onSetAsDefaultClicked: {
                                    viewModel.setAsDefault(
                                        gatewayClient: gc,
                                        into: modelContext.container
                                    )
                                }
                            )
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
        onSetAsDefaultClicked: {}
    )
}

#Preview {
    DefaultGatewayClientView(msisdn: "+123456789")
}
