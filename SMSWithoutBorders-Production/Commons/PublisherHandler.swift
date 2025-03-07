//
//  PublisherHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/14/22.
//

import Foundation
import MessageUI

func getEncryptedContent(contentToEncrypt: String) -> (iv: String, encryptedContent: Data) {
    let sharedKey = ""
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

func getDecryptedContent(contentToDecrypt: Data, iv: String) -> String {
    let sharedKey = ""
    print("Shared key: \(sharedKey)")
    
    var decryptedString: String = ""
    do {
        let aes = try AES(keyString: sharedKey)
        decryptedString = try aes.decrypt(contentToDecrypt, ivValue: iv)
    }
    catch {
        print("getting encrypted content error: \(error)")
    }
    
    return decryptedString
    
}

func formatForPublishing(formattedContent: String) -> String {
    let encryptedContentAssets = getEncryptedContent(contentToEncrypt: formattedContent)
    
    let iv = encryptedContentAssets.iv
    let encryptedContent = encryptedContentAssets.encryptedContent
    
    let encryptedContentStr = encryptedContent.base64EncodedString()
    
    let encryptedContentFormattedAssets = iv + encryptedContentStr
    
    return Data(encryptedContentFormattedAssets.utf8).base64EncodedString()
}


public func sendSMS(message: String, receipient: String, messageComposeDelegate: MFMessageComposeViewControllerDelegate) {
    let messageVC = MFMessageComposeViewController()
    messageVC.messageComposeDelegate = messageComposeDelegate
    messageVC.recipients = [receipient]
    messageVC.body = message
    
    let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
    
    if MFMessageComposeViewController.canSendText() {
        vc?.present(messageVC, animated: true)
    }
    else {
        print("User hasn't setup Messages.app")
    }
}


