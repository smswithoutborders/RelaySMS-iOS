//
//  GatewayClientsViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 30/09/2026.
//

import Observation
import SwiftData
import Foundation


enum GatewayClientsState {
    case loading
    case idle
    case failure(data: String)
}

@Observable
class GatewayClientsViewModel {
    private(set) var fetchState: GatewayClientsState = .idle
    
    private(set) var defaultGatewayClient: GatewayClients?
    
    func fetch(into container: ModelContainer) async {
        let hdv = GatewayClients.getHardCodedValues()
        let context = ModelContext(container)
        do {
            defaultGatewayClient = try GatewayClients.getDefault(context: context)
            if defaultGatewayClient == nil {
                try GatewayClients.insertAll(into: context, gatewayClients: hdv)
                defaultGatewayClient = try GatewayClients.getDefault(context: context)
            }
        } catch {
            print(error)
        }
        
        fetchState = .loading
        guard let url = URL(string: StaticVariables.GatewayClients.supportedUrl) else {
            print("Invalid URL")
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                fetchState = .failure(data: "https request failed")
                return
            }

            var gatewayClients = try JSONDecoder().decode([GatewayClients.GatewayClientsData].self, from: data)
            print("Successfully fetched \(gatewayClients.count) gateway clients.")
            
            gatewayClients = gatewayClients.filter{ gc in hdv.first { d in d.msisdn == gc.msisdn} == nil }
            
            try GatewayClients.save(gatewayClients, into: container)
            fetchState = .idle
        } catch {
            print("Failed to fetch data: \(error.localizedDescription)")
            fetchState = .failure(data: error.localizedDescription)
        }
    }
    
    
    func setAsDefault(gatewayClient: GatewayClients, into container: ModelContainer) {
        do {
            defaultGatewayClient = try gatewayClient.setDefault(into: container)
        } catch {
            print(error)
            print("Failed to set Gateway client: \(gatewayClient)")
        }
    }
}
