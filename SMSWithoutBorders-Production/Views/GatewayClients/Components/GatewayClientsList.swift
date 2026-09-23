//
//  GatewayClientsList.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 02/04/2025.
//

import SwiftUI

struct GatewayClientList: View {
    var gatewayClients: FetchedResults<GatewayClientsEntity>

    let defaultGatewayClientMsisdn: String

    // Input: Callbacks to the parent view to handle actions
    let onSetDefault: (GatewayClientsEntity) -> Void
    let onRequestEdit: (GatewayClientsEntity) -> Void
    let onRequestDelete: (GatewayClientsEntity) -> Void
    let onDeleteSwipe: (IndexSet) -> Void  // For swipe-to-delete


    var body: some View {
        VStack {
            ForEach(gatewayClients) { client in
                GatewayClientCardListItem(
                    client: client,
                    isSelected: client.msisdn == defaultGatewayClientMsisdn,
                    canEdit: !client.isDefaultClient(),
                    onSetDefault: {
                        onSetDefault(client)  // Pass the client back up
                    },
                    onRequestEdit: {
                        onRequestEdit(client)  // Pass the client back up
                    },
                    onRequestDelete: {
                        onRequestDelete(client)  // Pass the client back up
                    }
                )
            }
            .onDelete(perform: onDeleteSwipe) // Handle swipe delete
            .padding([.horizontal, .bottom], 16)
        }
    }
}
