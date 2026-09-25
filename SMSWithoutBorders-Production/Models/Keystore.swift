//
//  Keystore.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 25/09/2026.
//

import Foundation
import CryptoKit
import SwiftData

class Keystore {
    var accountTag: String
    
    init(accountTag: String) {
        self.accountTag = accountTag
    }
    
    func savePrivateKeyToKeychain(keyData: Data) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeEC, // Curve25519 maps to Elliptic Curve
            kSecAttrApplicationTag: accountTag.data(using: .utf8)!,
            kSecValueData: keyData,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Restricts data syncing/sharing if desired
        ]
        
        // First, delete any old instance of this specific key to avoid duplication conflicts
        SecItemDelete(query as CFDictionary)
        
        // Save the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadPrivateKeyFromKeychain() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: accountTag.data(using: .utf8)!,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        // Reconstruct the Curve25519 object from the retrieved raw bytes
        return data
    }
}
