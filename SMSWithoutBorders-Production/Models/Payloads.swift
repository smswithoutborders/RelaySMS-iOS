//
//  Payloads.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 26/09/2026.
//

import SwiftData
import Foundation

@Model
class Payloads {
    @Attribute(.unique) var id: UUID
    var content: Data
    var platformName: String
    var isOfflineFirst: Bool
    
    init(
        id: UUID,
        plaformName: String,
        content: Data,
        isOfflineFirst: Bool = false
    ) {
        self.id = id
        self.platformName = plaformName
        self.isOfflineFirst = isOfflineFirst
        self.content = content
    }
}
