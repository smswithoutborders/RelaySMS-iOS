//
//  TransportImpl.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 22/09/2026.
//

import Foundation

enum PublishingError: Error {
    case failedToPublish(error: any Error)
}

func publishWithoutAttachment(
    catId: V1ContentCategories,
    tokenId: UInt32,
    body: [UInt8],
    to: [UInt8]?,
    subject: [UInt8],
    encrypt: ([UInt8]) -> (cipherText: [UInt8], keyId: [UInt8]),
    transmissionCallback: (String) -> (),
) throws -> V1ContentsContainer {
    let contentContainer = V1ContentsContainer(
        catId: catId,
        body: Data(body),
        to: to != nil ? Data(to!) : nil,
        subject: Data(subject),
        attachment: nil
    )
    
    do {
        let content = try contentContainer.serialize()
        let (ciphertext, keyId) = encrypt([UInt8](content))
        
        let payloads = try V1Payloads(
            contents: Data(ciphertext),
            kId: keyId[0],
            lenAtt: 0,
            tId: tokenId,
            sessId: nil
        )
        let serialized = try payloads.serializeWithoutAttachment()
        
        let payload = serialized.base64EncodedString()
        transmissionCallback(payload)
    } catch {
        throw PublishingError.failedToPublish(error: error)
    }
    
    return contentContainer
}

func publishWithAttachment(
    catId: V1ContentCategories,
    tokenId: UInt32,
    sessionId: UInt8,
    body: [UInt8],
    to: [UInt8]?,
    subject: [UInt8],
    attachment: [UInt8],
    encrypt: ([UInt8]) -> (cipherText: [UInt8], keyId: [UInt8]),
    transmissionCallback: ([String?]) -> (),
) throws -> V1ContentsContainer{
    let contentContainer = V1ContentsContainer(
        catId: catId,
        body: Data(body),
        to: to != nil ? Data(to!) : nil,
        subject: Data(subject),
        attachment: Data(attachment)
    )
    
    do {
        let content = try contentContainer.serialize()
        let (ciphertext, keyId) = encrypt([UInt8](content))
        
        let payloads = try V1Payloads(
            contents: Data(ciphertext),
            kId: keyId[0],
            lenAtt: UInt16(attachment.count),
            tId: tokenId,
            sessId: sessionId
        )
        let split = try payloads.split(transport: Transports.sms)
        let splitPayloads = split.map { val in
            String(data: val, encoding: .utf8)
        }
        
        transmissionCallback(splitPayloads)
    } catch {
        throw PublishingError.failedToPublish(error: error)
    }
    
    return contentContainer

}

