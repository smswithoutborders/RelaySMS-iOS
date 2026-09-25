//
//  StaticKeys.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import Foundation

class StaticKeys: Codable {
    var keypair: String
    var kid: Int // Should be forced into 1 byte
    var status: String
    
    public static func getStaticKey(kid: Int) -> StaticKeys? {
        #if DEBUG
        let STATIC_KEYS_FILENAME = "static-x25519-staging"
        #else
        let STATIC_KEYS_FILENAME = "static-x25519"
        #endif

        guard let url = Bundle.main.path(forResource: STATIC_KEYS_FILENAME, ofType: "json") else {
            print("Error reading file...")
            return nil
        }
        print("[+] File url: \(url)")
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: url))

            var result = try JSONDecoder().decode([StaticKeys].self, from: data)
            return result.first{ val in val.kid == kid }
        } catch {
            print("Error decoding json: \(error)")
        }

        return nil
    }
    
    public func getKey() -> Data? {
        guard let decoded = Data(base64Encoded: keypair) else {
            return nil
        }
        return decoded
    }
}
