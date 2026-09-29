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
    
    init(keyId: Int) {
        self.id = UUID()
        self.keyId = keyId
    }
}
