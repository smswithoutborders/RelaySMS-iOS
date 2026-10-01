//
//  StaticKeys.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import Foundation

class StaticKeys: Codable {
    var public_key: String
    var key_id: Int // Should be forced into 1 byte
    
    enum StaticKeysError: Error {
        case failedToGetStaticKeys
    }
    
    public static func getStaticKey(kid: Int) throws -> StaticKeys? {
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

            let result = try JSONDecoder().decode([StaticKeys].self, from: data)
            return result.first{ $0.key_id == kid }
        } catch {
            throw error
        }
    }
    
    public func getKey() throws -> Data? {
        var base64 = self.public_key
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + (4 - remainder), withPad: "=", startingAt: 0)
        }
        guard let decoded = Data(base64Encoded: base64) else {
            throw StaticKeysError.failedToGetStaticKeys
        }
        return decoded
    }
}
