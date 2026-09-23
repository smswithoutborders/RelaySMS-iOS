//
//  GatewayClientCard.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import CoreData
import SwiftUI

struct GatewayClientCard: View {
    var clientEntity: GatewayClientsEntity
    //    var disabled: Bool
    var canEdit: Bool = false
    var isSelected: Bool


    var body: some View {
        VStack {
            Group {
                HStack {
                    Text(clientEntity.msisdn ?? "N/A")
                        .font(.headline)
                        .padding(.bottom, 5)
                    Spacer()
                    if !canEdit {
                        Image(systemName: "lock.fill").foregroundColor(RelayColors.colorScheme.onSurface.opacity(0.5))
                    }
                }

                HStack {
                    Text(clientEntity.operatorName ?? "N/A")
                    Text(clientEntity.operatorCode ?? "N/A")
                }
                .foregroundColor(.secondary)
                .font(.subheadline)

                Text(clientEntity.country ?? "N/A")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            

        }.padding()
            .background(isSelected ? RelayColors.colorScheme.primaryContainer : RelayColors.colorScheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? RelayColors.colorScheme.primary : RelayColors.colorScheme.onSurface.opacity(0.1), lineWidth: 1)
            )
    }
}
