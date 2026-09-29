//
//  Untitled.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 28/09/2026.
//

import Observation
import Foundation
import CoreData

enum FetchState {
    case loading
    case idle
    case failure(data: String)
}

@Observable
class SupportPlatformsViewModel {
    private(set) var fetchState: FetchState = .idle
    
    func fetch() async {
        guard let url = URL(string: SupportedPlatforms.supportedUrl) else {
            print("Invalid URL")
            return
        }
        
        do {
            // 3. Perform the network request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 4. Validate the HTTP response status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                fetchState = .failure(data: "https request failed")
                return
            }
            
            // 5. Decode the JSON data into your model
            let supportedPlatforms = try JSONDecoder().decode([SupportedPlatforms.SupportPlatformsData].self, from: data)
            print("Successfully fetched \(supportedPlatforms.count) platforms.")
            
            try SupportedPlatforms.save(data: supportedPlatforms)
            fetchState = .idle
        } catch {
            print("Failed to fetch data: \(error.localizedDescription)")
            fetchState = .failure(data: error.localizedDescription)
        }
    }
    
    
    static func downloadAndSaveIcons(
        url: URL,
        context: NSManagedObjectContext,
        completion: @escaping (Error?) -> Void
    ) {
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            guard let data = data, error == nil else {
                completion(
                    error ?? NSError(domain: "DownloadError", code: -1, userInfo: nil))
                return

            }

            // Perfome Core Data operations on the main queue since we're using the view context
//            DispatchQueue.main.async {
//                // 1. Fetch existing entity
//                let fetchRequest = PlatformsEntity.fetchRequest()
//                fetchRequest.predicate = NSPredicate(
//                    format: "name == %@", platform.name)
//
//                do {
//                    let existingPlatforms = try context.fetch(fetchRequest)
//                    if let existingPlatform = existingPlatforms.first {
//                        // 2. Update existing entity
//                        print("[Publisher] Updating existing Platform: \(platform.name)")
//                        existingPlatform.image = data
//                        existingPlatform.protocol_type = platform.protocol_type
//                        existingPlatform.service_type = platform.service_type
//                        existingPlatform.shortcode = platform.shortcode
//                        existingPlatform.support_url_scheme = platform.support_url_scheme
//                    } else {
//                        // 3. Create new entity
//                        print("[Publisher] Creating new Platform: \(platform.name)")
//                        let platformsEntity = PlatformsEntity(context: context)
//                        platformsEntity.image = data
//                        platformsEntity.name = platform.name
//                        platformsEntity.protocol_type = platform.protocol_type
//                        platformsEntity.service_type = platform.service_type
//                        platformsEntity.shortcode = platform.shortcode
//                        platformsEntity.support_url_scheme = platform.support_url_scheme
//                    }
//
//                    // 4. Save changes after each platform
//                    if context.hasChanges {
//                        try context.save()
//                        print("[Publisher] Successfully saved platform: \(platform.name)")
//                    }
//
//                    completion(nil)
//
//                } catch {
//                    print("[Publisher] Error saving Platform \(platform.name): \(error)")
//                    completion(error)
//                }
//
//            }

        }
        task.resume()
    }

}
