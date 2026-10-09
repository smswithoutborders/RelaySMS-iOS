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
    var date: Int64
    var catId: Int

    init(
        id: UUID = UUID(), 
        plaformName: String,
        content: Data,
        catId: Int,
        isOfflineFirst: Bool = false,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
    ) {
        self.id = id
        self.platformName = plaformName
        self.isOfflineFirst = isOfflineFirst
        self.content = content
        self.catId = catId
        self.date = date
    }
}
