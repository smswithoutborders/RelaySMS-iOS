//
//  PlatformsEntityHandlers.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 15/01/2025.
//

import Foundation
import CoreData

func downloadAndSaveIcons(url: URL,
                          platform: Publisher.PlatformsData,
                          viewContext: NSManagedObjectContext) {
    print("Storing Platform Icon: \(platform.name)")
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else { return }
        
        let platformsEntity = PlatformsEntity(context: viewContext)
        platformsEntity.image = data
        platformsEntity.name = platform.name
        platformsEntity.protocol_type = platform.protocol_type
        platformsEntity.service_type = platform.service_type
        platformsEntity.shortcode = platform.shortcode
        platformsEntity.support_url_scheme = platform.support_url_scheme
        
        if(viewContext.hasChanges) {
            do {
                try viewContext.save()
            } catch {
                print("Failed save download image: \(error) \(error.localizedDescription)")
            }
        }
    }
    task.resume()
}

