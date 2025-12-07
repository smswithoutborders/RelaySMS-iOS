//
//  DataController.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import Foundation
import CoreData


class DataController: ObservableObject {
    let container: NSPersistentContainer

    init(forTesting: Bool = false) {
        
        container = NSPersistentContainer(name: "Datastore")
        
        if forTesting {
            // Configuration for unit tests
            
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
            print("DataController: Initialized for TESTING (in-memory store at /dev/null).")
        } else {
            print("DataController: Initialized for NORMAL APP (default persistent store). Using default configuration")
        }
        container.loadPersistentStores(completionHandler: { storeDescription, error in
                if let error = error {
                    print("Core Data failed to load store at \(storeDescription.url?.absoluteString ?? "N/A"): \(error.localizedDescription)")
                } else {
                    print("DataController: Persistent store loaded successfully at \(storeDescription.url?.absoluteString ?? "N/A")")
                    self.container.viewContext.automaticallyMergesChangesFromParent = true
                    self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                }
            })
    }

    public static func resetDatabase(context: NSManagedObjectContext) throws {
        // This deletes everything except the default Gateway Clients
        print("Resetting Database")
        do {
            try context.persistentStoreCoordinator!.managedObjectModel.entities.forEach { (entity) in
                if let name = entity.name {
                    if entity.name != "GatewayClientsEntity" {
                        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                        let request = NSBatchDeleteRequest(fetchRequest: fetch)
                        try context.execute(request)
                    }
                }
            }

            try context.save()
        } catch {
            throw error
        }
    }
}
