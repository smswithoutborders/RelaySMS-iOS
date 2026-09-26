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
    var content: V1ContentsContainer
    var platformName: String
    var isOfflineFirst: Bool
    
    init(
        id: UUID,
        plaformName: String,
        isOfflineFirst: Bool = false
    ) {
        self.id = id
        self.platformName = plaformName
        self.isOfflineFirst = isOfflineFirst
    }
}
