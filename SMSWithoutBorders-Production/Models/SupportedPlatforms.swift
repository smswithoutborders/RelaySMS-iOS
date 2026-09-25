//
//  StoredPlatformEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 13/06/2025.
//

struct SupportedPlatforms {
    let name: String
    let displayName: String
    let supportsOfflineFirst: Bool
    let catId: Int
    let protoId: Int
    let iconSvg: String
    let iconPng: String
    let authProvider: String? = nil
}
