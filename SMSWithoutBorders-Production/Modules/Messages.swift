//
//  Messages.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import Foundation

class Messages {
    var subject: String
    var toAccount: String
    var fromAccount: String
    var platformName: String
    var date: Int
    var data: String

    init(subject: String, data: String, fromAccount: String, toAccount: String, platformName: String, date: Int) {
        self.subject = subject
        self.data = data
        self.toAccount = toAccount
        self.fromAccount = fromAccount
        self.platformName = platformName
        self.date = date
    }
}
