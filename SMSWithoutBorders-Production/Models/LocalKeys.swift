//
//  LocalKeys.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 25/09/2026.
//

import SwiftData
import Foundation

@Model
class LocalKeys {
    @Attribute(.unique) var id: UUID
    var keyId: Int
    var tokenId: UUID
    
    init(
        keyId: Int,
        tokenId: UUID
    ) {
        self.id = UUID()
        self.keyId = keyId
        self.tokenId = tokenId
    }
}
