//
//  PlatformsHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import Foundation
import CoreData
import SwiftUI

class PlatformHandler {
    
    static func resetPlatforms(platforms: FetchedResults<PlatformsEntity>, datastore: NSManagedObjectContext) {
        for platform in platforms {
            datastore.delete(platform)
        }
        print("Datastore reset complete")
    }

    static func storePlatforms(platformsData: Array<Dictionary<String, Any>>, datastore: NSManagedObjectContext) {
        for platformData in platformsData {
            let platform = PlatformsEntity(context: datastore)
            platform.platform_name = platformData["name"] as? String
            platform.type = platformData["type"] as? String
            platform.platform_letter = platformData["letter"] as? String
            
            print("Storing platform: \(String(describing: platform.platform_name))")
                
            do {
                try datastore.save()
            }
            catch {
                print("Failed to store platform: \(error)")
            }
        }
    }

}
