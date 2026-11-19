//
//  Payloads.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 26/09/2026.
//

import SwiftData
import Foundation

@Model
class Payloads : Encodable, Decodable{
    @Attribute(.unique) var id: UUID
    var content: Data
    var platformName: String
    var platformDisplayName: String
    var isOfflineFirst: Bool
    var date: Int64
    var catId: Int
    var account: String

    init(
        id: UUID = UUID(), 
        plaformName: String,
        platformDisplayName: String,
        content: Data,
        catId: Int,
        account: String,
        isOfflineFirst: Bool = false,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
    ) {
        self.id = id
        self.platformName = plaformName
        self.platformDisplayName = platformDisplayName
        self.isOfflineFirst = isOfflineFirst
        self.content = content
        self.catId = catId
        self.date = date
        self.account = account
    }
    
    static func getAll(context: ModelContext) throws -> [Payloads]{
        var randomDescriptor = FetchDescriptor<Payloads>()

        return try context.fetch(randomDescriptor)
    }
    
    static func insertAll(context: ModelContext, payloads: [Payloads]) throws {
        for payload in payloads {
            context.insert(payload)
        }
        
        try context.save()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case platformName = "platform_name"
        case platformDisplayName = "platform_display_name"
        case isOfflineFirst = "is_offline_first"
        case date
        case account
        case catId = "cat_id"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.content = try container.decode(Data.self, forKey: .content)
        self.platformName = try container.decode(String.self, forKey: .platformName)
        self.isOfflineFirst = try container.decode(Bool.self, forKey: .isOfflineFirst)
        self.date = try container.decode(Int64.self, forKey: .date)
        self.catId = try container.decode(Int.self, forKey: .catId)
        self.account = try container.decode(String.self, forKey: .account)
        self.platformDisplayName = try container.decode(String.self, forKey: .platformDisplayName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(platformName, forKey: .platformName)
        try container.encode(date, forKey: .date)
        try container.encode(catId, forKey: .catId)
        try container.encode(account, forKey: .account)
        try container.encode(platformDisplayName, forKey: .platformDisplayName)
    }
}
