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

class OperatorHandlers {
    
    public static func findGatewayClientsWithOperatorId(operatorCode: String, context: NSManagedObjectContext) -> GatewayClients? {
        let fetchRequest: NSFetchRequest<GatewayClientsEntity> = GatewayClientsEntity.fetchRequest()
        do {
            let result = try context.fetch(fetchRequest)
            for gatewayClientEntity in result {
                if gatewayClientEntity.operatorCode == operatorCode {
                    return GatewayClients(
                        country: gatewayClientEntity.country!,
                        last_published_date: Int(gatewayClientEntity.lastPublishedDate),
                        msisdn: gatewayClientEntity.msisdn!,
                        operator: gatewayClientEntity.operatorCode!,
                        operator_code: gatewayClientEntity.operatorCode!,
                        protocols: gatewayClientEntity.protocols!.split(separator: ",").map { String($0)},
                        reliability: gatewayClientEntity.reliability!)
                }
            }
        } catch {
            print("Error fetching StatesEntity: \(error)")
        }
        return nil
    }
    
    public static func isMatchingOperatorCode(operatorCode: String) -> Bool {
        let cellularProviders: [String: CTCarrier] = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders ?? [:]

        for cellularProvider in cellularProviders {
            // TODO: Actually check to find if matching default Gateway is present
            let carrierName: String = cellularProvider.value.carrierName!;
            let mobileCountryCode: String = cellularProvider.value.mobileCountryCode!;
            let mobileNetworkCode: String = cellularProvider.value.mobileNetworkCode!;
            // print("Carrier name: \(carrierName), Country code: \(mobileCountryCode), Network code: \(mobileNetworkCode)")
            let oc = mobileCountryCode + mobileNetworkCode
            
            print("\(cellularProvider.key) checking: \(carrierName) oc=\(oc) -> operatorCode=\(operatorCode) : \(cellularProvider.value.isoCountryCode)")
            if oc == operatorCode {
                return true
            }
        }
        return false
    }
    
}
