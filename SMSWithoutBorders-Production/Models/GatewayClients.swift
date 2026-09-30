//
//  GatewayClients.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import CoreData
import Foundation

class GatewayClients: Codable {
    public static let GATEWAY_CLIENT_URL = "https://gatewayserver.smswithoutborders.com/v3/clients"
    public static let DEFAULT_GATEWAY_CLIENT_MSISDN = "COM.AFKANERD.RELAY.DEFAULT_GATEWAY_CLIENT_MSISDN"
    
    var country: String
    var last_published_date: Int
    var msisdn: String
    var `operator`: String
    var operator_code: String
    var protocols: [String]
    var reliability: String
    
    init(
        country: String,
        last_published_date: Int,
        msisdn: String,
        operator _operator: String,
        operator_code: String,
        protocols: [String],
        reliability: String
    ) {
        self.country = country
        self.msisdn = msisdn
        self.operator = _operator
        self.operator_code = operator_code
        self.protocols = protocols
        self.reliability = reliability
        self.last_published_date = last_published_date
    }
    
    private static func fetch() async throws -> [GatewayClients] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: GATEWAY_CLIENT_URL)!)
        return try! JSONDecoder().decode([GatewayClients].self, from: data)
    }
    
    static func configureDefaults() {
        let currentDefault = UserDefaults.standard.object(forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String ?? ""
        
        if currentDefault.isEmpty {
            let defaultGatewayClients = GatewayClients.getDefaultGatewayClients()
            print("configuring default: \(defaultGatewayClients.first?.msisdn)")
            UserDefaults.standard.set(defaultGatewayClients[0].msisdn, forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        } else {
            print("Current default: \(currentDefault)")
        }
    }
    
    static func clear(context: NSManagedObjectContext, shouldSave: Bool = true) throws {
        print("Clearing GatewayClients...")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GatewayClientsEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)  // Use batch delete for efficiency
        
        deleteRequest.resultType = .resultTypeCount  // Or .resultTypeObjectIDs if you need object IDs
        
        do {
            try context.execute(deleteRequest)
            //            try context.save()
        } catch {
            print("Error clearing GatewayClients: \(error)")
            context.rollback()
            throw error  // Re-throw the error after rollback
        }
    }
    
    public static func getDefaultGatewayClients() -> [GatewayClients] {
        return [
            GatewayClients(
                country: "Nigeria",
                last_published_date: 0,
                msisdn: "+2348131498393",
                operator: "MTN Nigeria",
                operator_code: "62130",
                protocols: ["https", "smtp", "ftp"],
                reliability: ""),
            
            GatewayClients(
                country: "Cameroon",
                last_published_date: 0,
                msisdn: "+237679466332",
                operator: "MTN Cameroon",
                operator_code: "62401",
                protocols: ["https", "smtp", "ftp"],
                reliability: ""),
            
            GatewayClients(
                country: "Cameroon",
                last_published_date: 0,
                msisdn: "+237690826242",
                operator: "Orange Cameroon",
                operator_code: "62402",
                protocols: ["https", "smtp", "ftp"],
                reliability: ""),
        ]
    }
    
}
