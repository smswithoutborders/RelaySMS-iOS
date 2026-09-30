//
//  StoredPlatformEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 13/06/2025.
//

import SwiftData
import Foundation

@Model
class SupportedPlatforms {
    #if DEBUG
    static let supportedUrl = "https://publisher.relaysms.afkanerd.de/v1/platforms"
    #else
    static let supportedUrl = "https://relaysms.smswithoutborders.afkanerd.com/v1/platforms"
    #endif
    
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
}
