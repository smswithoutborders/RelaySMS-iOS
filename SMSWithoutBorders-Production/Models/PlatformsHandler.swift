//
//  PlatformsHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import Foundation
import CoreData
import SwiftUI

class PlatformHandler {
    
    static func resetPlatforms(platforms: FetchedResults<PlatformsEntity>, datastore: NSManagedObjectContext) {
        for platform in platforms {
            datastore.delete(platform)
        }
        print("Datastore reset complete")
    }
}


func decodeForViewing(encryptedContent: EncryptedContentsEntity, type: String) -> Array<String> {
    // var formattedEmail = ("", "", "", "", "", "")
    var formattedOutput : Array<String> = []
    
//    if let decodedData = Data(base64Encoded: encryptedContent.encrypted_content!) {
//        let decodedString = String(data: decodedData, encoding: .utf8)!
//        print("Decoded String: \(decodedString)")
//        let endIndex = decodedString.index(decodedString.startIndex, offsetBy: 16)
//        
//        let ivStr: String = String(decodedString[decodedString.startIndex..<endIndex])
//        let encodedEncryptedStr: String = String(decodedString[endIndex..<decodedString.endIndex])
//        print("IV string: \(ivStr)")
//        print("Encoded Encrypted String: \(encodedEncryptedStr)")
//        
//        if let decodedEncryptedData = Data(base64Encoded: encodedEncryptedStr) {
//            print("Decoded Encrypted Data: \(decodedEncryptedData)")
//            
//            let decryptedData: String = getDecryptedContent(contentToDecrypt: decodedEncryptedData, iv: ivStr)
//            print("Decrypted Data: \(decryptedData)")
//            
//            switch type {
//            case "email":
////                let formattedEmail = formatEmailForViewing(decryptedData: decryptedData)
////                print("formatted email: \(formattedEmail)")
////                
////                formattedOutput.append(formattedEmail.platformLetter)
////                formattedOutput.append(formattedEmail.to)
////                formattedOutput.append(formattedEmail.cc)
////                formattedOutput.append(formattedEmail.bcc)
////                formattedOutput.append(formattedEmail.subject)
////                formattedOutput.append(formattedEmail.body)
//                break;
//                
//            case "text":
//                let formattedMessage = formatTextForViewing( decryptedData: decryptedData)
//                
//                formattedOutput.append(formattedMessage.platformLetter)
//                formattedOutput.append(formattedMessage.textBody)
//                break;
//                
//            case "messaging":
//                let formattedMessage = formatMessageForViewing( decryptedData: decryptedData)
//                
//                formattedOutput.append(formattedMessage.platformLetter)
//                formattedOutput.append(formattedMessage.messageContact)
//                formattedOutput.append(formattedMessage.messageBody)
//                break;
//                
//            default:
//                break;
//            }
//        }
//    }
//    
    return formattedOutput
}

