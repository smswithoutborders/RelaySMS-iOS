//
//  MockDataGenerator.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 03/08/2024.
//

import Foundation
import CoreData

func createInMemoryPersistentContainer() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "Datastore")
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { description, error in
        if let error = error {
            fatalError("Failed to load in-memory store: \(error)")
        }
    }
    
    return container
}

func populateMockData(container: NSPersistentContainer) {
    let context = container.viewContext
    
    let platformEntityGmail = PlatformsEntity(context: context)
    platformEntityGmail.image = nil
    platformEntityGmail.name = "gmail"
    platformEntityGmail.protocol_type = "oauth"
    platformEntityGmail.service_type = "email"
    platformEntityGmail.shortcode = "g"
    
    let platformEntityTwitter = PlatformsEntity(context: context)
    platformEntityTwitter.image = nil
    platformEntityTwitter.name = "twitter"
    platformEntityTwitter.protocol_type = "oauth"
    platformEntityTwitter.service_type = "text"
    platformEntityTwitter.shortcode = "x"
    
    let platformEntityGmail1 = PlatformsEntity(context: context)
    platformEntityGmail1.image = nil
    platformEntityGmail1.name = "telegram"
    platformEntityGmail1.protocol_type = "pnba"
    platformEntityGmail1.service_type = "messaging"
    platformEntityGmail1.shortcode = "T"
    
    let platformEntityTwitter1 = PlatformsEntity(context: context)
    platformEntityTwitter1.image = nil
    platformEntityTwitter1.name = "slack"
    platformEntityTwitter1.protocol_type = "oauth"
    platformEntityTwitter1.service_type = "messaging"
    platformEntityTwitter1.shortcode = "s"

    for i in 0..<3 {
        let name = "gmail"
        let account = "account_\(i)@gmail.com"
        let storedPlatformsEntity = StoredPlatformsEntity(context: context)
        storedPlatformsEntity.name = name
        storedPlatformsEntity.account = account
        storedPlatformsEntity.id = Vault.deriveUniqueKey(platformName: name, 
                                                         accountIdentifier: account)
    }
    for i in 0..<3 {
        let name = "twitter"
        let account = "@twitter_account_\(i)"
        let storedPlatformsEntity = StoredPlatformsEntity(context: context)
        storedPlatformsEntity.name = name
        storedPlatformsEntity.account = account
        storedPlatformsEntity.id = Vault.deriveUniqueKey(platformName: name,
                                                         accountIdentifier: account)
    }
    for i in 0..<3 {
        let name = "telegram"
        let account = "+23712345\(i)"
        let storedPlatformsEntity = StoredPlatformsEntity(context: context)
        storedPlatformsEntity.name = name
        storedPlatformsEntity.account = account
        storedPlatformsEntity.id = Vault.deriveUniqueKey(platformName: name,
                                                         accountIdentifier: account)
    }

    do {
        try context.save()
    } catch {
        fatalError("Failed to save mock data: \(error)")
    }
}
