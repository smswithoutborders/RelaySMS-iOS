//
//  GatewayClients.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import Foundation
import CoreData


class GatewayClients: Codable {
    public static var GATEWAY_CLIENT_URL = "https://smswithoutborders.com/v3/clients"
    public static var DEFAULT_GATEWAY_CLIENT_MSISDN = "COM.AFKANERD.RELAY.DEFAULT_GATEWAY_CLIENT_MSISDN"

    var country: String
    var last_published_date: Int
    var msisdn: String
    var `operator`: String
    var operator_code: String
    var protocols: [String]
    var reliability: String
    
    init(country: String,
         last_published_date: Int,
         msisdn: String,
         operator _operator: String,
         operator_code: String,
         protocols: [String],
         reliability: String) {
        self.country = country
        self.msisdn = msisdn
        self.operator = _operator
        self.operator_code = operator_code
        self.protocols = protocols
        self.reliability = reliability
        self.last_published_date = last_published_date
    }
    
    private static func fetch() async throws -> [GatewayClients]{
        let (data, _) = try await URLSession.shared.data(from: URL(string: GATEWAY_CLIENT_URL)!)
        return try! JSONDecoder().decode([GatewayClients].self, from: data)
    }
    
    public static func refresh(context: NSManagedObjectContext) async throws {
        do {
            let gatewayClients = try await fetch()
            
            for defaultGatewayClient in gatewayClients {
                let gatewayClient = GatewayClientsEntity(context: context)

                gatewayClient.country = defaultGatewayClient.country
                gatewayClient.lastPublishedDate = Int32(defaultGatewayClient.last_published_date)
                gatewayClient.msisdn = defaultGatewayClient.msisdn
                gatewayClient.operatorName = defaultGatewayClient.operator
                gatewayClient.operatorCode = defaultGatewayClient.operator_code
                gatewayClient.protocols = defaultGatewayClient.protocols.joined(separator: ",")
                gatewayClient.reliability = defaultGatewayClient.reliability
            }
            
            do {
                try context.save()
                print("Done refreshing Gateway clients...")
            }
            catch {
                print("Error saving Gateway client!: \(error)")
            }
        } catch {
            print("Error refreshing gateway clients: \(error)")
        }
    }

    public static func addDefaultGatewayClients(context: NSManagedObjectContext, defaultAvailable: Bool = false) -> GatewayClients? {
        let defaultGatewayClients = [
            GatewayClients(
                country: "Nigeria",
                last_published_date: 0,
                msisdn: "+2348131498393",
                operator:"MTN Nigeria",
                operator_code:"62130",
                protocols:["https", "smtp", "ftp"],
                reliability:""),
            
            GatewayClients(
                country: "Cameroon",
                last_published_date: 0,
                msisdn: "+237679466332",
                operator:"MTN Cameroon",
                operator_code:"62401",
                protocols:["https", "smtp", "ftp"],
                reliability:""),
            
            GatewayClients(
                country: "Cameroon",
                last_published_date: 0,
                msisdn: "+237690826242",
                operator:"Orange Cameroon",
                operator_code:"62402",
                protocols:["https", "smtp", "ftp"],
                reliability:""),
        ]
        
        var returningGatewayClient: GatewayClients?
        for defaultGatewayClient in defaultGatewayClients {
            let gatewayClient = GatewayClientsEntity(context: context)

            gatewayClient.country = defaultGatewayClient.country
            gatewayClient.lastPublishedDate = Int32(defaultGatewayClient.last_published_date)
            gatewayClient.msisdn = defaultGatewayClient.msisdn
            gatewayClient.operatorName = defaultGatewayClient.operator
            gatewayClient.operatorCode = defaultGatewayClient.operator_code
            gatewayClient.protocols = defaultGatewayClient.protocols.joined(separator: ",")
            gatewayClient.reliability = defaultGatewayClient.reliability
            
            if OperatorHandlers.isMatchingOperatorCode(operatorCode: gatewayClient.operatorCode!) {
                returningGatewayClient = defaultGatewayClient
            }
        }
        
        do {
            try context.save()
        }
        catch {
            print("Error saving Gateway client!: \(error)")
        }
        
        return returningGatewayClient ?? defaultGatewayClients[0]
    }

}
