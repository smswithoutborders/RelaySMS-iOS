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

    static func storePlatforms(platformsData: Array<Dictionary<String, Any>>, datastore: NSManagedObjectContext) {
        for platformData in platformsData {
            let platform = PlatformsEntity(context: datastore)
            platform.id = Double.random(in: 2.71828...3.14159)
            platform.platform_name = platformData["name"] as? String
            platform.type = platformData["type"] as? String
            platform.platform_letter = platformData["letter"] as? String
            
            print("Storing platform: \(String(describing: platform.platform_name))")
                
            do {
                try datastore.save()
            }
            catch {
                print("Failed to store platform: \(error)")
            }
        }
    }
    
    @ViewBuilder static func getView(platform: PlatformsEntity, encryptedContent: EncryptedContentsEntity?) -> some View {
        // TODO: defaulting to return emailView - shitty solution
        
        if platform.type == "email" {
            if encryptedContent != nil {
                let formattedOutput = decodeForViewing(encryptedContent: encryptedContent!, type: platform.type!)
                EmailView(platform: platform, composeTo: formattedOutput[1], composeCC: formattedOutput[2], composeBCC: formattedOutput[3], composeSubject: formattedOutput[4], composeBody: formattedOutput[5])
            }
            else {
                EmailView(platform: platform, encryptedContent: encryptedContent)
            }
        }
        else if platform.type == "text" {
            if encryptedContent != nil {
                let formattedOutput = decodeForViewing(encryptedContent: encryptedContent!, type: platform.type!)
                TextView(textBody: formattedOutput[0])
            }
            else {
                TextView()
            }
        }
        else if platform.type == "messaging" {
            if encryptedContent != nil {
                let formattedOutput = decodeForViewing(encryptedContent: encryptedContent!, type: platform.type!)
                MessageView(textBody: formattedOutput[1], contactInformation: formattedOutput[0])
            }
            else {
                MessageView()
            }
        }
        EmptyView()
    }

}

func formatEmailForPublishing(
    platformLetter: String,
    to: String, cc: String, bcc: String, subject: String, body: String) -> String {
        
        let formattedString: String = platformLetter + ":" + to + ":" + cc + ":" + bcc + ":" + subject + ":" + body
        
        return formattedString
}

func formatEmailForViewing(decryptedData: String) -> (platformLetter: String, to: String, cc: String, bcc: String, subject: String, body: String) {
    let splitString = decryptedData.components(separatedBy: ":")
    
    let platformLetter: String = splitString[0]
    let to: String = splitString[1]
    let cc: String = splitString[2]
    let bcc: String = splitString[3]
    let subject: String = splitString[4]
    let body: String = splitString[5]
    
    return (platformLetter, to, cc, bcc, subject, body)
}

func decodeForViewing(encryptedContent: EncryptedContentsEntity, type: String) -> Array<String> {
    // var formattedEmail = ("", "", "", "", "", "")
    var formattedOutput : Array<String> = []
    
    if let decodedData = Data(base64Encoded: encryptedContent.encrypted_content!) {
        let decodedString = String(data: decodedData, encoding: .utf8)!
        print("Decoded String: \(decodedString)")
        let endIndex = decodedString.index(decodedString.startIndex, offsetBy: 16)
        
        let ivStr: String = String(decodedString[decodedString.startIndex..<endIndex])
        let encodedEncryptedStr: String = String(decodedString[endIndex..<decodedString.endIndex])
        print("IV string: \(ivStr)")
        print("Encoded Encrypted String: \(encodedEncryptedStr)")
        
        if let decodedEncryptedData = Data(base64Encoded: encodedEncryptedStr) {
            print("Decoded Encrypted Data: \(decodedEncryptedData)")
            
            let decryptedData: String = getDecryptedContent(contentToDecrypt: decodedEncryptedData, iv: ivStr)
            print("Decrypted Data: \(decryptedData)")
            
            switch type {
            case "email":
                let formattedEmail =  formatEmailForViewing( decryptedData: decryptedData)
                print("formatted email: \(formattedEmail)")
                
                formattedOutput.append(formattedEmail.platformLetter)
                formattedOutput.append(formattedEmail.to)
                formattedOutput.append(formattedEmail.cc)
                formattedOutput.append(formattedEmail.bcc)
                formattedOutput.append(formattedEmail.subject)
                formattedOutput.append(formattedEmail.body)
                break;
                
            default:
                break;
            }
        }
    }
    return formattedOutput
}

