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
}
