//
//  GatewayClientsHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import Foundation
import CoreData
import SwiftUI
import CoreTelephony

class GatewayClientHandler {
    
    var gatewayClientsEntities: FetchedResults<GatewayClientsEntity>
    
    init(gatewayClientsEntities: FetchedResults<GatewayClientsEntity>) {
        self.gatewayClientsEntities = gatewayClientsEntities
    }
    
    func getDefaultGatewayClients() -> [GatewayClient] {
        let gatewayClient0 = GatewayClient(MSISDN:"+237679466332", operatorId:"62401", country:"Cameroon", operatorName: "MTN Cameroon")
        let gatewayClient1 = GatewayClient(MSISDN:"+237672451860", operatorId:"62401", country:"Cameroon", operatorName: "MTN Cameroon")
        let gatewayClient2 = GatewayClient(MSISDN:"+237690826242", operatorId:"62402", country:"Cameroon", operatorName: "Orange Cameroon")
        
        return [gatewayClient0, gatewayClient1, gatewayClient2]
    }
    
    static func containsDefaultProperties(gatewayClient: GatewayClient) -> Bool {
        let cellularProviders: [String: CTCarrier] = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders!
        
        for cellularProvider in cellularProviders {
            let mobileCountryCode: String = cellularProvider.value.mobileCountryCode!;
            let mobileNetworkCode: String = cellularProvider.value.mobileNetworkCode!;
            let operatorId = mobileCountryCode + mobileNetworkCode
            
            if gatewayClient.operatorId == operatorId {
                return true
            }
        }
        return false
    }
    
    func findGatewayClientsWithOperatorId(operatorId: String) -> [GatewayClientsEntity] {
        var matchingGateways: [GatewayClientsEntity] = []
        for gatewayClientEntity in self.gatewayClientsEntities {
            if gatewayClientEntity.operator_id == operatorId {
                matchingGateways.append(gatewayClientEntity)
            }
        }
        
        return matchingGateways
    }
    
    static func getOperatorProperties() -> Bool {
        let cellularProviders: [String: CTCarrier] = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders!
        
        for cellularProvider in cellularProviders {
            // TODO: Actually check to find if matching default Gateway is present
            let carrierName: String = cellularProvider.value.carrierName!;
            let mobileCountryCode: String = cellularProvider.value.mobileCountryCode!;
            let mobileNetworkCode: String = cellularProvider.value.mobileNetworkCode!;
            // print("Carrier name: \(carrierName), Country code: \(mobileCountryCode), Network code: \(mobileNetworkCode)")
            let operatorCode = mobileCountryCode + mobileNetworkCode
        }
        return false
    }
    
    
    func toggleDefaultGatewayClient(defaultGatewayClientEntity: GatewayClientsEntity, datastore: NSManagedObjectContext) {
        for gatewayClientEntity in self.gatewayClientsEntities {
            gatewayClientEntity.is_default = false
            do {
                try gatewayClientEntity.managedObjectContext?.save()
            }
            catch {
                print("Failed to save changes for entity")
            }
        }
        
        do {
            defaultGatewayClientEntity.is_default = true
            try defaultGatewayClientEntity.managedObjectContext?.save()
        }
        catch {
            print("Failed to store intended default gateway client")
        }
    }

    func addGatewayClients(datastore: NSManagedObjectContext) {
        let defaultGatewayClients: [GatewayClient] = getDefaultGatewayClients()
        
        // TODO: add more Gateway clients
        
        var defaultSet: Bool = false
        let defaultOperatorId: String = "62402"
        
        for defaultGatewayClient in defaultGatewayClients {
            let gatewayClient = GatewayClientsEntity(context: datastore)
            
            gatewayClient.msisdn = defaultGatewayClient.MSISDN
            gatewayClient.country = defaultGatewayClient.country
            gatewayClient.operator_id = defaultGatewayClient.operatorId
            gatewayClient.operator_name = defaultGatewayClient.operatorName
            
            if !defaultSet && GatewayClientHandler.containsDefaultProperties(gatewayClient: defaultGatewayClient) {
                gatewayClient.is_default = true
                defaultSet = true
            }
            
            do {
                try datastore.save()
                print("Added Gateway client: " + defaultGatewayClient.MSISDN)
            }
            catch {
                print("Error saving Gateway client!")
            }
        }
        
        if !defaultSet {
            let gatewayClientsEntities: [GatewayClientsEntity] = findGatewayClientsWithOperatorId(operatorId: defaultOperatorId)
            
            for gatewayClientEntity in gatewayClientsEntities {
                // selecting just the first item
                toggleDefaultGatewayClient(defaultGatewayClientEntity: gatewayClientEntity, datastore: datastore)
                break
            }
        }
    }
    
    func getDefaultGatewayClientMSISDN() -> String {
        // GatewayClientHandler.getOperatorProperties()
        for gatewayClientEntity in self.gatewayClientsEntities {
            print(gatewayClientEntity.msisdn)
            print(gatewayClientEntity.is_default)
            if gatewayClientEntity.is_default {
                return gatewayClientEntity.msisdn!
            }
        }
        
        return ""
    }
}
