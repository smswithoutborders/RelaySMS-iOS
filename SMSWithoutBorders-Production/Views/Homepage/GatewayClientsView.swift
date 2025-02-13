//
//  GatewayClientsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import SwiftUI

struct GatewayClientView: View {
    @State var selectedGatewayClient: GatewayClientsEntity
    @State var disabled: Bool = false

    var body: some View {
        VStack {
            Group {
                Text(selectedGatewayClient.msisdn!)
                    .font(.headline)
                    .padding(.bottom, 5)
                    .foregroundColor(disabled ? .secondary : .primary )
                
                HStack {
                    Text(selectedGatewayClient.operatorName! + " -")
                    Text(selectedGatewayClient.operatorCode!)
                }
                .foregroundColor(.secondary)
                .font(.subheadline)
                
                Text(selectedGatewayClient.country!)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct GatewayClientsView: View {
    
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) var gatewayClients: FetchedResults<GatewayClientsEntity>
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""
    
    @State var selectedGatewayClient: String = ""

    @State var changeDefaultGatewayClient: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                if !defaultGatewayClientMsisdn.isEmpty {
                    ForEach(gatewayClients) { gatewayClient in
                        if gatewayClient.msisdn == defaultGatewayClientMsisdn {
                            VStack {
                                Text("Selected Gateway Client")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.caption2)
                                    .padding(.bottom, 3)
                                    .foregroundColor(.secondary)
                                GatewayClientView(selectedGatewayClient: gatewayClient, disabled: true)
                                    .padding(.top, 3)
                            }
                            .padding()
                        }
                    }
                }

                List(gatewayClients, id: \.self) { gatewayClient in
                    Button(action: {
                        selectedGatewayClient = gatewayClient.msisdn!
                        changeDefaultGatewayClient = true
                    }) {
                        GatewayClientView(selectedGatewayClient: gatewayClient)
                            .padding()
                    }
                }
                .confirmationDialog("Set as default gateway client?",
                                     isPresented: $changeDefaultGatewayClient) {
                    Button("Make default") {
                        defaultGatewayClientMsisdn = selectedGatewayClient
                    }
                } message: {
                    Text(String(localized: "Choosing a Gateway client in the same Geographical location as you helps improves the reliability of your messages being delivered", comment: "Describes helpful tip about choosing a default gateway client")
                        
                    )
                }
            }
            .navigationTitle("Gateway Clients")
        }
        .task {
            if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                print("Is searching for default....")
                do {
                    GatewayClients.addDefaultGatewayClients(
                        context: context,
                        defaultAvailable: !defaultGatewayClientMsisdn.isEmpty)
                    try await GatewayClients.refresh(context: context)
                } catch {
                    print("Error refreshing gateways: \(error)")
                }
            }
        }
    }
}

struct GatewayClientsView_Previoew: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])

        return GatewayClientsView()
            .environment(\.managedObjectContext, container.viewContext)
    }
}
