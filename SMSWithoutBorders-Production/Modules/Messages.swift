//
//  Messages.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import Foundation
import CoreData

class Messages {
    var id: UUID
    var subject: String
    var toAccount: String
    var fromAccount: String
    var platformName: String
    var date: Int
    var data: String
    var cc: String
    var bcc: String

    init(
        id: UUID,
        subject: String,
        data: String,
        fromAccount: String,
        toAccount: String,
        platformName: String,
        date: Int,
        cc: String = "",
        bcc: String = ""
    ) {
        self.id = id
        self.subject = subject
        self.data = data
        self.toAccount = toAccount
        self.fromAccount = fromAccount
        self.platformName = platformName
        self.date = date
        self.cc = cc
        self.bcc = bcc
    }
    
    public static func deleteMessage(context: NSManagedObjectContext, message: Messages) {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", message.id.uuidString)
        
        do {
            let items = try context.fetch(fetchRequest)
            if let itemToDelete = items.first {
                context.delete(itemToDelete)

                do {
                    try context.save()
                    print("Item with ID \(message.id) deleted successfully.")
                } catch {
                    print("Error saving context after deletion: \(error)")
                }
            } else {
                print("Item with ID \(message.id) not found.")
            }
        } catch {
            print("Error fetching items: \(error)")
        }
    }
}
