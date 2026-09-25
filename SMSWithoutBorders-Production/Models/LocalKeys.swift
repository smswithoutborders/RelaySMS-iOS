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
    var keyId: UInt8
    
    init(keyId: UInt8) {
        self.id = UUID()
        self.keyId = keyId
    }
}
