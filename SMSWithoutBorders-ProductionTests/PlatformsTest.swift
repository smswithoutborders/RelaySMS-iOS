//
//  PlatformsTest.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 18/07/2024.
//

import Testing
import CoreData

struct PlatformsTest {
    
    @Test 
    func deleteAllPersistentTest() async throws {
        let context = DataController().container.viewContext
        
        // Fetch all items
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlatformsEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            throw error
        }
        
        // Fetch all items
        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "StoredPlatformsEntity")
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        do {
            try context.execute(deleteRequest1)
            try context.save()
        } catch {
            throw error
        }
    }
}
