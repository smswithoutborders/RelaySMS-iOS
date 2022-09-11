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
    // TODO: store in KeyChain

    var error: Unmanaged<CFError>?

    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
        throw error!.takeRetainedValue() as Error
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey), let publicKeyExportable = SecKeyCopyExternalRepresentation(publicKey, &error) else {
        throw error!.takeRetainedValue() as Error
    }

    let finalData = publicKeyExportable as Data
    
    let exportImportManager = CryptoExportImportManager()
    
    let exportableDERKey = exportImportManager.exportRSAPublicKeyToDER(finalData, keyType: kSecAttrKeyTypeRSA as String, keySize: 2048)
    
    // return finalData.base64EncodedString()
    
    return exportableDERKey.base64EncodedString()
}


func decryptWithRSAKeyPair(privateKey: SecKey, encryptedData: String) -> String {
    var error: Unmanaged<CFError>?
    
    let cfDataStr = Data(base64Encoded: encryptedData, options: .ignoreUnknownCharacters)
    let canDecrypt: Bool = SecKeyIsAlgorithmSupported(privateKey, .decrypt, .rsaEncryptionOAEPSHA1)
    
    guard let decryptedData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionOAEPSHA1, cfDataStr as! CFData, &error) else {
        return ""
    }
    
    let decryptedDataStr = String(data: decryptedData as Data, encoding: .utf8)!
    
    return decryptedDataStr
}

func encryptWithRSAKeyPair(publicKeyStr: String, data: String) -> String {
    let exportImportManager = CryptoExportImportManager()
    
    let publicKey = Data(base64Encoded: publicKeyStr, options: .ignoreUnknownCharacters)!
    
    var error: Unmanaged<CFError>?
    guard let publicKeyFinal = SecKeyCreateWithData(publicKey as NSData, [
        kSecAttrKeyType: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits: 2048,
        kSecAttrKeyClass: kSecAttrKeyClassPublic,
    ] as NSDictionary, &error) else {
        return ""
    }
    
    let cfData: Data = data.data(using: String.Encoding.utf8)!
    guard let encryptedData = SecKeyCreateEncryptedData(publicKeyFinal, .rsaEncryptionOAEPSHA1, cfData as CFData, &error) else {
        // TODO: change this to throw instead
        return ""
    }
    
    let encryptedDataFinal: Data = encryptedData as Data
    
    let encryptedDataStr = encryptedDataFinal.base64EncodedString()
    
    return encryptedDataStr
}
