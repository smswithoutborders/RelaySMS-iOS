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
    static let supportedUrl = "https://publisher.relaysms.afkanerd.de/v1/platforms"
    @Attribute(.unique) var name: String
    var displayName: String
    var supportsOfflineFirst: String
    var catId: Int
    var protoId: Int
    var iconSvg: String
    var iconPng: String
    var authProvider: String

    public class SupportPlatformsData: Decodable {
        let name: String
        let displayName: String
        let supportsOfflineFirst: String
        let catId: Int
        let protoId: Int
        let iconSvg: String
        let iconPng: String
        let authProvider: String
    }
    
    init(
        name: String,
        displayName: String,
        supportsOfflineFirst: String,
        catId: Int,
        protoId: Int,
        iconSvg: String,
        iconPng: String,
        authProvider: String
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
    
    
    static func save(data: [SupportPlatformsData]) throws {
        let container = try ModelContainer(for: SupportedPlatforms.self)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        data.forEach { data in
            let sp = SupportedPlatforms(
                name: data.name,
                displayName: data.displayName,
                supportsOfflineFirst: data.supportsOfflineFirst,
                catId: data.catId,
                protoId: data.protoId,
                iconSvg: data.iconSvg,
                iconPng: data.iconPng,
                authProvider: data.authProvider
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
