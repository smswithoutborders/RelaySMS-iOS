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
    
    func clearStoredEncryptedContents() {
        
    }
    
    static func store(datastore: NSManagedObjectContext, encryptedContentBase64: String, gatewayClientMSISDN: String, platformName: String) {
        let encryptedContentEntity = EncryptedContentsEntity(context: datastore)
        encryptedContentEntity.platform_name = platformName
        encryptedContentEntity.gateway_client_msisdn = gatewayClientMSISDN
        
        print("Storing encrypted content...")

        do {
            try datastore.save()
        }
        catch {
            print("Failed to store encrypted content: \(error)")
        }
        
    }
}
