//
//  Tokens.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 02/10/2026.
//

import SwiftData
import Foundation

@Model
class Tokens {
    @Attribute(.unique) var id: UUID
    var catId: Int
    var account: String
    var platformName: String
    var date: Int64
    
    init(
        catId: Int,
        account: String,
        platformName: String,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = UUID()
        self.catId = catId
        self.account = account
        self.platformName = platformName
        self.date = date
    }
}
