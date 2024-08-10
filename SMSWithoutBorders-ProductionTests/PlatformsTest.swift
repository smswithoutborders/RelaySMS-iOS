//
//  PlatformsTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 18/07/2024.
//

import Testing
import CoreData


@testable import SMSWithoutBorders

struct PlatformsTest {
    
    @Test 
    func deleteAllPersistentTest() async throws {
        let context = DataController().container.viewContext
        
        try DataController.resetDatabase(context: context)
    }
}
