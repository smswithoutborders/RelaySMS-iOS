//
//  PublisherHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/14/22.
//

import Foundation

func getEncryptedContent(contentToEncrypt: String) -> (iv: String, encryptedContent: Data) {
    let sharedKey = CSecurity().findInKeyChain()
    print("Shared key: \(sharedKey)")
    
    var encryptedDataHolder: Data = Data()
    
    do {
        let aes = try AES(keyString: sharedKey)
        let aesEncryptedContent = try aes.encrypt(contentToEncrypt)
        encryptedDataHolder = aesEncryptedContent.encryptedData
        
        return (aesEncryptedContent.ivValue, encryptedDataHolder)
    }
    catch {
        print("getting encrypted content error: \(error)")
    }
    
    return ("", encryptedDataHolder)
}

func formatForPublishing(formattedContent: String) -> String {
    let encryptedContentAssets = getEncryptedContent(contentToEncrypt: formattedContent)
    
    let iv = encryptedContentAssets.iv
    let encryptedContent = encryptedContentAssets.encryptedContent
    
    let encryptedContentStr = encryptedContent.base64EncodedString()
    
    let encryptedContentFormattedAssets = iv + encryptedContentStr
    
    return Data(encryptedContentFormattedAssets.utf8).base64EncodedString()
}

