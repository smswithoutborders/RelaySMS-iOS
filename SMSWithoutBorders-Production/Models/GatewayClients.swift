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
class GatewayClients : Encodable, Decodable{
    enum GatewayClientErrors: Error {
        case noDefaultGatewayClientSet
    }

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
    
    enum CodingKeys: String, CodingKey {
        case country
        case msisdn
        case serviceProvider = "service_provider"
        case isDefault = "is_default"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(country, forKey: .country)
        try container.encode(msisdn, forKey: .msisdn)
        try container.encode(serviceProvider, forKey: .serviceProvider)
        try container.encode(isDefault, forKey: .isDefault)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.country = try container.decode(String.self, forKey: .country)
        self.msisdn = try container.decode(String.self, forKey: .msisdn)
        self.serviceProvider = try container.decode(String.self, forKey: .serviceProvider)
        self.isDefault = try container.decode(Bool.self, forKey: .isDefault)
    }

    static func save(_ data: [GatewayClientsData], into container: ModelContainer) throws {
        let context = ModelContext(container)
        
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
    
    static func insertAll(into context: ModelContext, gatewayClients: [GatewayClients]) throws {
        gatewayClients.forEach { item in
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
    
    static func getDefault(context: ModelContext) throws -> GatewayClients? {
        let predicate = #Predicate<GatewayClients> { gc in
            gc.isDefault == true
        }
        var descriptor = FetchDescriptor<GatewayClients>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw error
        }
    }
    
    func setDefault(into container: ModelContainer) throws -> GatewayClients{
        let context = ModelContext(container)

        if let defaultGc = try GatewayClients.getDefault(context: context), defaultGc !== self {
            defaultGc.isDefault = false
        }
        
        self.isDefault = true
        
        if self.modelContext == nil {
            context.insert(self)
        }
        
        try context.save()
        
        return self
    }
    
    static func getAll(context: ModelContext) throws -> [GatewayClients]{
        let randomDescriptor = FetchDescriptor<GatewayClients>()
        return try context.fetch(randomDescriptor)
    }
}
