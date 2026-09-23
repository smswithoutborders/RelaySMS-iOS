//
//  Errors.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 28/03/2025.
//

import SwiftUI

struct CustomError: LocalizedError {
    //TODO: Migh extend this with an enum to define custom error types
    let message: String
    
    var errorDescription: String? {
        message
    }
}
