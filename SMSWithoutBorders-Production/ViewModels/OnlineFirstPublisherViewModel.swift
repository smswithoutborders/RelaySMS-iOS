//
//  OnlineFirstPublisherViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 29/09/2026.
//

import CoreData

@Observable
class OnlineFirstPublisherViewModel {
    public func processIncomingUrls(
        context: NSManagedObjectContext,
        url: URL, codeVerifier: String,
        storeOnDevice: Bool,
    ) throws {
        let stateB64Values = url.valueOf("state")
        // Decode the Base64 string to Data
        guard let decodedData = Data(base64Encoded: stateB64Values!) else {
            fatalError("Failed to decode Base64 string")
        }

        // Convert Data to String
        guard let decodedString = String(data: decodedData, encoding: .utf8)
        else {
            fatalError("Failed to convert Data to String")
        }

        print("[Publisher] decoded string: \(decodedString)")
        let values = decodedString.split(separator: ",")
        let state = values[0]
        let supportsUrlScheme = values[1] == "true"

        let code = url.valueOf("code")
        if code == nil {
            return
        }
        print("[Publisher] state: \(state)\ncode: \(code)\ncodeVerifier: \(codeVerifier)\nstoreOnDevice: \(storeOnDevice)")

        do {} catch {
            throw error
        }
    }
}

