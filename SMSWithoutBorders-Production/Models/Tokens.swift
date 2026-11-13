//
//  Tokens.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 02/10/2026.
//

import SwiftData
import Foundation

@Model
class Tokens : Encodable, Decodable {
    @Attribute(.unique) var id: UUID
    var catId: Int
    var account: String
    var platformName: String
    var date: Int64
    
    init(
        catId: Int,
        account: String,
        platformName: String,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = UUID()
        self.catId = catId
        self.account = account
        self.platformName = platformName
        self.date = date
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case catId = "cat_id"
        case account
        case platformName = "platform_name"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.catId = try container.decode(Int.self, forKey: .catId)
        self.account = try container.decode(String.self, forKey: .account)
        self.platformName = try container.decode(String.self, forKey: .platformName)
        self.date = Int64(Date().timeIntervalSince1970 * 1000)
    }
    

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(catId, forKey: .catId)
        try container.encode(account, forKey: .account)
        try container.encode(platformName, forKey: .platformName)
    }
    
    static func getAll(context: ModelContext) throws -> [Tokens]{
        let randomDescriptor = FetchDescriptor<Tokens>()
        return try context.fetch(randomDescriptor)
    }
    

    static func insertAll(context: ModelContext, tokens: [Tokens]) throws {
        for token in tokens {
            context.insert(token)
        }
        
        try context.save()
    }
}
