//
//  GatewayClientsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import SwiftUI

struct GatewayClientsView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                key: "msisdn",
                ascending: true)
        ],
        animation: .default
    ) var gatewayClients: FetchedResults<GatewayClientsEntity>

    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    @State private var clientToEdit: GatewayClientsEntity? = nil
    @State private var clientToSetAsDefault: GatewayClientsEntity? = nil
    @State private var clientToDelete: GatewayClientsEntity? = nil


    // State for Alerts/Sheets
    @State private var showAddEditClientView = false
    @State private var showDeleteConfirm = false
    @State private var showDefaultClientChangeConfirm = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showResultAlert = false
    @State private var listVersion = UUID()


    // Computed property for the currently selected default client entity
    private var selectedDefaultGatewayClient: GatewayClientsEntity? {
        gatewayClients.first { $0.msisdn == defaultGatewayClientMsisdn }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    // Display Selected Client Header
                    SelectedClientHeader(client: selectedDefaultGatewayClient)

                    NavigationLink(
                        "Add Gateway Client",
                        destination: AddEditGatewayClientView(
                            gatewayClient: clientToEdit != nil ? GatewayClients.fromEntity(entity: clientToEdit!) : nil,
                            defaultMsisdnStorage: $defaultGatewayClientMsisdn,
                            onDismissed: {
                                listVersion = UUID()
                                showAddEditClientView = false
                                clientToEdit = nil
                            }
                        ).onDisappear{
                            listVersion = UUID()
                            showAddEditClientView = false
                            clientToEdit = nil
                        },
                        isActive: $showAddEditClientView

                    ).buttonStyle(.relayButton(variant: .secondary)).padding([.leading, .trailing, .bottom], 16)
                    
                    Text("All Gateway Clients")
                        .font(RelayTypography.titleSmall)
                        .padding([.leading], 16)
                        .padding(.bottom, 8)

                    Text("Long press for more options")
                        .font(RelayTypography.bodySmall)
                        .foregroundStyle(RelayColors.colorScheme.onSurface.opacity(0.5))
                        .padding([.leading], 16)

                    GatewayClientList(
                        gatewayClients: gatewayClients,  // Pass the fetched results
                        defaultGatewayClientMsisdn: defaultGatewayClientMsisdn,  // Pass the default ID
                        onSetDefault: { client in  // Closure implementations
                            self.showDefaultClientChangeConfirm = true
                            self.clientToSetAsDefault = client

                        },
                        onRequestEdit: { client in  // Closure implementations
                            self.clientToEdit = client
                            self.showAddEditClientView = true
                        },
                        onRequestDelete: { client in  // Closure implementations
                            self.clientToDelete = client
                            self.showDeleteConfirm = true
                        },
                        onDeleteSwipe: { indexSet in  // Closure implementations
                            self.requestDelete(at: indexSet)
                        }
                    ).id(listVersion)

                }.navigationTitle("Countries")
                    .confirmationDialog("Delete Client?", isPresented: $showDeleteConfirm, presenting: clientToDelete) {
                        client in
                        Button("Delete \(client.msisdn ?? "Client")", role: .destructive) {
                            performDelete(client: client)
                        }
                        Button("Cancel", role: .cancel) {
                            clientToDelete = nil
                        }
                    } message: {
                        client in
                        Text("Are you sure you want to delete the gateway client \(client.msisdn ?? "")? This cannot be undone.")
                            .alert(alertTitle, isPresented: $showResultAlert) {
                                Button("OK") { showResultAlert = false }
                            } message: {
                                Text(alertMessage)
                            }
                    }
                    .confirmationDialog(
                        "Set as default gateway client?",
                        isPresented: $showDefaultClientChangeConfirm
                    ) {
                        if let clientToMakeDefault = clientToSetAsDefault {
                            Button("Make default") {
                                setDefaultClient(clientToMakeDefault)
                            }
                        }

                    } message: {
                        Text(String(localized: "Choosing a Gateway client in the same Geographical location as you helps improves the reliability of your messages being delivered", comment: "Explains that selecting a Gateway clinet int he same geographical localtiion helps improve the reliability of yout messages"))
                    }
            }
        }
    }
    // Helper functions
    func setDefaultClient(_ client: GatewayClientsEntity) {
        if let msisdn = client.msisdn {
            defaultGatewayClientMsisdn = msisdn
            print("Set default client to: \(msisdn)")
        }
        clientToSetAsDefault = nil
    }

    // Handles swipe to delete request
    func requestDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            clientToDelete = gatewayClients[index]

            if clientToDelete?.isDefaultClient() == true {
                alertTitle = "Deletion Failed"
                alertMessage = "Cannot delete a built-in default gateway client."
                showResultAlert = true
                clientToDelete = nil
            } else {
                showDeleteConfirm = true
            }
        }
    }


    func performDelete(client: GatewayClientsEntity) {
        // Prevent deleting the currently selected default

        if client.msisdn == defaultGatewayClientMsisdn {
            alertTitle = "Deletion Failed"
            alertMessage = "Cannot delet the currently selected default gateway client"
            showResultAlert = true
            clientToDelete = nil
            return
        }

        // Prevent deleting default clients

        if client.isDefaultClient() {
            alertTitle = "Deletion Failed"
            alertMessage = "Cannot delete a default gateway client."
            showResultAlert = true
            clientToDelete = nil
            return
        }

        do {
            let clientValueType = GatewayClients.fromEntity(entity: client)

            try GatewayClients.deleteGatewayClient(context: context, client: clientValueType)

            alertTitle = "Deleted"
            alertMessage = "Successfully deleted client \(client.msisdn ?? "")."
            showResultAlert = true
        } catch {
            print("Error deleting client: \(error)")
            // Failure feedback
            alertTitle = "Error"
            alertMessage = "Failed to delete client \(client.msisdn ?? ""). \(error.localizedDescription)"
            showResultAlert = true
        }
        clientToDelete = nil
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
