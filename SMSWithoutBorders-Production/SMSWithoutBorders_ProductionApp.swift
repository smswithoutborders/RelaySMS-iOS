//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData
import SwiftData

@main
struct SMSWithoutBorders_ProductionApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                SupportedPlatformsView()
            }
        }
        .modelContainer(for: SupportedPlatforms.self)
    }

}



