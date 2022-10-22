//
//  EncryptedContentHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 10/22/22.
//

import Foundation
import SwiftUI
import CoreData

struct EncryptedContentHandler {
    
    static func clearStoredEncryptedContents(encryptedContents: FetchedResults<EncryptedContentsEntity>, datastore: NSManagedObjectContext) {
        for encryptedContent in encryptedContents {
            datastore.delete(encryptedContent)
        }
        print("Datastore reset complete")
    }
    
    static func store(datastore: NSManagedObjectContext, encryptedContentBase64: String, gatewayClientMSISDN: String, platformName: String) {
        let encryptedContentEntity = EncryptedContentsEntity(context: datastore)
        encryptedContentEntity.encrypted_content = encryptedContentBase64
        encryptedContentEntity.platform_name = platformName
        encryptedContentEntity.gateway_client_msisdn = gatewayClientMSISDN
        
        do {
            try datastore.save()
        }
        catch {
            print("Failed to store encrypted content: \(error)")
        }
        print("Successfully stored encrypted content: \(encryptedContentBase64)")
    }
}
