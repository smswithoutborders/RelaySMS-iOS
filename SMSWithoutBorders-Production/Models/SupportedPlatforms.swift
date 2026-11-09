//
//  StoredPlatformEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 13/06/2025.
//

import SwiftData
import Foundation

@Model
class SupportedPlatforms : Encodable, Decodable{
    
    @Attribute(.unique) var name: String
    var displayName: String
    var supportsOfflineFirst: Bool
    var catId: Int
    var protoId: Int
    var iconSvg: String
    var iconPng: String
    var authProvider: String?

    public class SupportPlatformsData: Decodable {
        let name: String
        let display_name: String
        let proto_id: Int
        let cat_id: Int
        let auth_provider: String?
        let supports_offline_first: Bool
        let icon_svg: String
        let icon_png: String
    }
    
    init(
        name: String,
        displayName: String,
        supportsOfflineFirst: Bool,
        catId: Int,
        protoId: Int,
        iconSvg: String,
        iconPng: String,
        authProvider: String?
    ) {
        self.name = name
        self.displayName = displayName
        self.supportsOfflineFirst = supportsOfflineFirst
        self.catId = catId
        self.protoId = protoId
        self.iconSvg = iconSvg
        self.iconPng = iconPng
        self.authProvider = authProvider
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case supportsOfflineFirst = "supports_offline_first"
        case catId = "cat_id"
        case protoId = "proto_id"
        case iconSvg = "icon_svg"
        case iconPng = "icon_png"
        case authProvider = "auth_provider"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(supportsOfflineFirst, forKey: .supportsOfflineFirst)
        try container.encode(catId, forKey: .catId)
        try container.encode(protoId, forKey: .protoId)
        try container.encode(iconSvg, forKey: .iconSvg)
        try container.encode(iconPng, forKey: .iconPng)
        try container.encode(authProvider, forKey: .authProvider)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.supportsOfflineFirst = try container.decode(Bool.self, forKey: .supportsOfflineFirst)
        self.catId = try container.decode(Int.self, forKey: .catId)
        self.protoId = try container.decode(Int.self, forKey: .protoId)
        self.iconSvg = try container.decode(String.self, forKey: .iconSvg)
        self.iconPng = try container.decode(String.self, forKey: .iconPng)
    }

    
    static func save(data: [SupportPlatformsData], into container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        data.forEach { item in
            let sp = SupportedPlatforms(
                name: item.name,
                displayName: item.display_name,
                supportsOfflineFirst: item.supports_offline_first,
                catId: item.cat_id,
                protoId: item.proto_id,
                iconSvg: item.icon_svg,
                iconPng: item.icon_png,
                authProvider: item.auth_provider
            )
            context.insert(sp)
        }
        do {
            try context.save()
        } catch {
            throw error
        }
    }
    
    static func getAll(context: ModelContext) throws -> [SupportedPlatforms]{
        var randomDescriptor = FetchDescriptor<SupportedPlatforms>()

        return try context.fetch(randomDescriptor)
    }
    
    static func insertAll(context: ModelContext, supportedPlatforms: [SupportedPlatforms]) throws {
        for supportedPlatform in supportedPlatforms {
            context.insert(supportedPlatform)
        }
        
        try context.save()
    }
}
