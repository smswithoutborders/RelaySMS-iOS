//
//  GatewayClients.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import CoreData
import Foundation
import SwiftData

@Model
class GatewayClients {
    enum GatewayClientErrors: Error {
        case noDefaultGatewayClientSet
    }
    
//    #if DEBUG
//    static let supportedUrl = "https://publisher.relaysms.afkanerd.de/v1/gateway-clients"
//    #else
//    static let supportedUrl = "https://relaysms.smswithoutborders.afkanerd.com/v1/gateway-clients"
//    #endif
    static let supportedUrl = "https://relaysms.smswithoutborders.afkanerd.com/v1/gateway-clients"

    @Attribute(.unique) var msisdn: String
    var country: String
    var serviceProvider: String
    var isDefault: Bool = false

    public class GatewayClientsData: Codable {
        var msisdn: String
        var country: String
        var `operator`: String
        var protocols: [String]
    }
    
    init(
        country: String,
        msisdn: String,
        serviceProvider: String,
        isDefault: Bool = false
    ) {
        self.country = country
        self.msisdn = msisdn
        self.serviceProvider = serviceProvider
        self.isDefault = isDefault
    }
    
    static func save(_ data: [GatewayClientsData], into container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        data.forEach { item in
            let sp = GatewayClients(
                country: item.country,
                msisdn: item.msisdn,
                serviceProvider: item.operator
            )
            context.insert(sp)
        }
        do {
            try context.save()
        } catch {
            throw error
        }
    }
    
    static func save(_ data: [GatewayClients], into container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        data.forEach { item in
            context.insert(item)
        }
        do {
            try context.save()
        } catch {
            throw error
        }
    }

    static func getHardCodedValues() -> [GatewayClients] {
        return [
            GatewayClients(
                country: "USA",
                msisdn: "+15024439537",
                serviceProvider: "Twilio",
                isDefault: true
            ),
            
            GatewayClients(
                country: "Nigeria",
                msisdn: "+2348131498393",
                serviceProvider: "MTN Nigeria",
            ),
            
            GatewayClients(
                country: "Cameroon",
                msisdn: "+237679466332",
                serviceProvider: "MTN Cameroon",
            ),
            
            GatewayClients(
                country: "Cameroon",
                msisdn: "+237690826242",
                serviceProvider: "Orange Cameroon",
            ),
        ]
    }
    
    static func getDefault(into container: ModelContainer) throws -> GatewayClients? {
        let predicate = #Predicate<GatewayClients> { gc in
            gc.isDefault == true
        }
        var descriptor = FetchDescriptor<GatewayClients>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            let context = ModelContext(container)
            return try context.fetch(descriptor).first
        } catch {
            throw error
        }
    }
    
    func setDefault(into container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        guard let defaultGc = try GatewayClients.getDefault(into: container) else {
            throw GatewayClientErrors.noDefaultGatewayClientSet
        }
        
        defaultGc.isDefault = false
        self.isDefault = true
        
        context.insert(defaultGc)
        context.insert(self)
        
        do {
            try context.save()
        } catch {
            throw error
        }
    }
}
