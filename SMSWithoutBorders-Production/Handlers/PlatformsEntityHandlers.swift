//
//  PlatformsEntityHandlers.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 15/01/2025.
//

import Foundation
import CoreData

struct DownloadContent {
}

// MARK: - Platforms Model
struct Platform: Identifiable {
    let name: String
    let protocolType: Publisher.ProtocolTypes
    let serviceType: Publisher.ServiceTypes
    let shortcode: String
    let supportUrlScheme: Bool
    let imageData: Data?

    var id: String { name }

    init(
        name: String, protocolType: Publisher.ProtocolTypes, serviceType: Publisher.ServiceTypes,
        shortcode: String, supportUrlScheme: Bool, imageData: Data? = nil
    ) {
        self.name = name
        self.protocolType = protocolType
        self.serviceType = serviceType
        self.shortcode = shortcode
        self.supportUrlScheme = supportUrlScheme
        self.imageData = imageData
    }

    func copyWith(
        name: String? = nil,
        protocolType: Publisher.ProtocolTypes? = nil,
        serviceType: Publisher.ServiceTypes? = nil,
        shortcode: String? = nil,
        supportUrlScheme: Bool? = nil,
        imageData: Data? = nil
    ) -> Platform {
        return Platform(
            name: name ?? self.name,
            protocolType: protocolType ?? self.protocolType,
            serviceType: serviceType ?? self.serviceType,
            shortcode: shortcode ?? self.shortcode,
            supportUrlScheme: supportUrlScheme ?? self.supportUrlScheme,
            imageData: imageData ?? self.imageData
        )
    }

    static func fromEntity(_ entity: PlatformsEntity) throws -> Platform {
        guard let entityName = entity.name, !entityName.isEmpty else {
            throw CustomError(
                message: "Invalid Entity: Platform name is nil or empty")
        }

        return Platform(
            name: entityName,
            protocolType: Publisher.ProtocolTypes(rawValue: entity.protocol_type ?? "oauth2") ?? Publisher.ProtocolTypes.OAUTH2,
            serviceType: Publisher.ServiceTypes(rawValue: entity.service_type ?? "text") ?? Publisher.ServiceTypes.TEXT,
            shortcode: entity.shortcode ?? "",
            supportUrlScheme: entity.support_url_scheme,
            imageData: entity.image
        )
    }
    
    static var sample: Platform = Platform(
        name: "gmail",
        protocolType:  Publisher.ProtocolTypes.OAUTH2,
        serviceType:  Publisher.ServiceTypes.EMAIL,
        shortcode:  "g",
        supportUrlScheme: true
    )

}


extension PlatformsEntity {
    func toStruct() -> Platform? {
        guard let entityName = self.name, !entityName.isEmpty else {
            print("Invalid Entity: Platform name is nil or empty")
            return nil
//            throw CustomError(
//                message: "Invalid Entity: Platform name is nil or empty")
        }

        return Platform(
            name: entityName,
            protocolType: Publisher.ProtocolTypes(rawValue: self.protocol_type ?? "oauth2") ?? Publisher.ProtocolTypes.OAUTH2,
            serviceType: Publisher.ServiceTypes(rawValue: self.service_type ?? "text") ?? Publisher.ServiceTypes.TEXT,
            shortcode: self.shortcode ?? "",
            supportUrlScheme: self.support_url_scheme,
            imageData: self.image
        )
    }
}
