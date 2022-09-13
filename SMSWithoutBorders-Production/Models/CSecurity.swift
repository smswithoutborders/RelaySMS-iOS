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
                
                return self.updateInKeyChain(sharedKey: sharedKey)
            }
            return false
        }
        
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
}
