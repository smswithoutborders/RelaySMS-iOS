//
//  Security.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/7/22.
//

import Foundation
import Security

func generateRSAKeyPair() throws -> String {
    
    let tag = "com.example.keys.mykey".data(using: .utf8)!
    // Dict
    let attributes: [String: Any] =
    [kSecAttrKeyType as String:           kSecAttrKeyTypeRSA,
         kSecAttrKeySizeInBits as String:      2048,
         kSecPrivateKeyAttrs as String:
            [kSecAttrIsPermanent as String:    false,
             kSecAttrApplicationTag as String: tag]
    ]
    // ["bsiz": 2048, "private": ["perm": false, "atag": 22 bytes], "type": 42]


    print(attributes)

    var error: Unmanaged<CFError>?

    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
        throw error!.takeRetainedValue() as Error
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey), let publicKeyExportable = SecKeyCopyExternalRepresentation(publicKey, &error) else {
        throw error!.takeRetainedValue() as Error
    }

    // print(publicKey)

    let finalData = publicKeyExportable as Data
    
    let exportImportManager = CryptoExportImportManager()
    
    let exportableDERKey = exportImportManager.exportRSAPublicKeyToDER(finalData, keyType: kSecAttrKeyTypeRSA as String, keySize: 2048)
    
    // print(exportableDERKey.base64EncodedString())
    
    // return finalData.base64EncodedString()
    
    return exportableDERKey.base64EncodedString()
}
