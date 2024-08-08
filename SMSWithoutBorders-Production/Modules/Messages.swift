//
//  Messages.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import Foundation

class Messages {
    var data: [UInt8]
    var fromAccount: String
    var platformName: String
    var date: Int
    
    init(data: [UInt8], fromAccount: String, platformName: String, date: Int) {
        self.data = data
        self.fromAccount = fromAccount
        self.platformName = platformName
        self.date = date
    }
    
    
    
}
