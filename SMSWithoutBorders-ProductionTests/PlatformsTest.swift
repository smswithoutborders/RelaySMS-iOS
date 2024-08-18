//
//  PlatformsTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 18/07/2024.
//

import XCTest
import CoreData


@testable import SMSWithoutBorders

//struct PlatformsTest {
//    
//    @Test 
//    func deleteAllPersistentTest() async throws {
//        let context = DataController().container.viewContext
//        
//        try DataController.resetDatabase(context: context)
//    }
//}

class PlatformsTest: XCTestCase {
    
    func testDeleteAll() throws {
        let context = DataController().container.viewContext
        try DataController.resetDatabase(context: context)
    }
    
}
