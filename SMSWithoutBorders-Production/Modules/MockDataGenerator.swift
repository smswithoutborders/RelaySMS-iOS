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
    
    for i in 0..<10 {
        let name = "MTN - \(i)"
        let account = "+23712345\(i)"
        let gatewayClientEntity = GatewayClientsEntity(context: context)
        gatewayClientEntity.country = "Cam\(i)roon"
        gatewayClientEntity.msisdn = "+\(i)3712345678\(i)"
        gatewayClientEntity.operatorCode = "6\(i)014"
        gatewayClientEntity.operatorName = "Test Operator"
        gatewayClientEntity.lastPublishedDate = 0
        gatewayClientEntity.reliability = "\(i).\(i)"
    }
    
    for i in 0..<3 {
        let messageEntity = MessageEntity(context: context)
        messageEntity.body = "Hello world - \(i)"
        messageEntity.platformName = "gmail"
        messageEntity.fromAccount = "from\(i)@gmail.com"
        messageEntity.toAccount = "to\(i)@gmail.com"
        messageEntity.subject = "New subject"
        messageEntity.date = Int32(Date().timeIntervalSince1970) - 10
    }
    for i in 0..<3 {
        let messageEntity = MessageEntity(context: context)
        messageEntity.body = "Hello world - \(i)"
        messageEntity.platformName = "twitter"
        messageEntity.fromAccount = "@person\(i)"
        messageEntity.toAccount = ""
        messageEntity.subject = "New subject"
        messageEntity.date = Int32(Date().timeIntervalSince1970) - 20
    }
    for i in 0..<3 {
        let messageEntity = MessageEntity(context: context)
        messageEntity.body = "Hello world - \(i)"
        messageEntity.platformName = "telegram"
        messageEntity.fromAccount = "+\(i)3712345678\(i)"
//        messageEntity.toAccount = "+\(i)3712345678\(i)"
        messageEntity.toAccount = "+137123456781"
        messageEntity.subject = "+\(i)3712345678\(i)"
        messageEntity.date = Int32(Date().timeIntervalSince1970) - 30
    }

    do {
        try context.save()
    } catch {
        fatalError("Failed to save mock data: \(error)")
    }
}
