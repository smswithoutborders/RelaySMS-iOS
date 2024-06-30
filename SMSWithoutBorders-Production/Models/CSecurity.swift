//
//  Security.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/13/22.
//

import Foundation


class CSecurity {
    private let sharedKeyTagLable = "com.afkanerd.smswithoutborders.sharedkey"
    
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
    
    func storeInKeyChain(sharedKey: String ) -> Bool {
        var query = self.query
        query[kSecValueData as String] = sharedKey.data(using: .utf8)
        query[kSecAttrAccount as String] = sharedKeyTagLable
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            print("failed to store shared key, what's up with that men, code better")
            
            if status == errSecDuplicateItem {
                print("Seems the data is duplicated! - holy hell")
                // TODO: modify key if this is the case
                self.deleteInKeyChain()
                
                print("Attempting second storage...")
                return storeInKeyChain(sharedKey: sharedKey)
            }
            return false
        }
        return true
    }
    
    public static func deleteFromKeyChain(keystoreAlias: String) -> Bool {
        var attributes: [String: Any] = [kSecClass as String: kSecClassKey]
        attributes[kSecAttrApplicationLabel as String] = keystoreAlias
        
        let status = SecItemDelete(attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            print("Cannot update, shared key not even stored in the first place")
            return false
        }
        
        print("successfully deleted keychain")
        return true
    }
    
    func deleteInKeyChain() -> Bool {
        var attributes = self.query
        attributes[kSecAttrAccount as String] = sharedKeyTagLable
        
        let status = SecItemDelete(attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            print("Cannot update, shared key not even stored in the first place")
            return false
        }
        
        print("successfully deleted keychain")
        return true
    }
    
    func updateInKeyChain(sharedKey: String ) -> Bool {
        var attributes = self.query
        attributes[kSecValueData as String] = sharedKey.data(using: .utf8)
        attributes[kSecAttrAccount as String] = sharedKeyTagLable
        
        let status = SecItemUpdate(self.query as CFDictionary, attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            print("Cannot update, shared key not even stored in the first place")
            return false
        }
        
        guard status != errSecSuccess else {
            print("Some shit went down while updating key, check out this code: \(status)")
            return false
        }
        
        print("successfully updated keychain")
        return true
    }
    
    func findInKeyChain() -> String {
        var query = self.query
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecAttrAccount as String] = sharedKeyTagLable
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            print("Failed to fetch stored key")
            
            return ""
        }
        
        guard let sharedKey = item as? Data else {
            print(item)
            print("Some error occured while fetching shared key")
            return ""
        }
        return String(data: sharedKey, encoding: .utf8)!
    }
}
