//
//  DataController.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import Foundation
import CoreData


class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Datastore")
    
    init() {
        container.loadPersistentStores(completionHandler: { description, error in
            self.container.viewContext.mergePolicy = NSOverwriteMergePolicy
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        })
    }
    
    public static func resetDatabase(context: NSManagedObjectContext) throws {
        do {
            try context.persistentStoreCoordinator!.managedObjectModel.entities.forEach { (entity) in
                print("Entity reseting: \(entity.name)")
                if let name = entity.name {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                    let request = NSBatchDeleteRequest(fetchRequest: fetch)
                    try context.execute(request)
                }
            }

            try context.save()
        } catch {
            throw error
        }
    }
}
