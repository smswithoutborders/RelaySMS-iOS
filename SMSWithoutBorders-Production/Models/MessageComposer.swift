//
//  MessageComposer.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/08/2024.
//

import Foundation
import SwobDoubleRatchet
import CryptoKit

class MessageComposer {
    
    var SK: [UInt8]
    var keystoreAlias: String
    var AD: [UInt8]
    var aliceState = States()
    var deviceID: [UInt8]?

    init(SK: [UInt8], AD: [UInt8], peerDhPubKey: Curve25519.KeyAgreement.PublicKey, keystoreAlias: String, deviceID: [UInt8]? = nil) throws {
        self.SK = SK
        self.keystoreAlias = keystoreAlias
        self.AD = AD
        self.deviceID = deviceID
        
        try Ratchet.aliceInit(
            state: self.aliceState,
            SK: self.SK,
            bobDhPubKey: peerDhPubKey,
            keystoreAlias: self.keystoreAlias)
    }
    
    public func emailComposer(platform_letter: UInt8,
                              from: String, to: String, cc: String, bcc: String, subject: String, body: String) throws -> String {
        let content = "\(from):\(to):\(cc):\(bcc):\(subject):\(body)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: aliceState, data: content, AD: self.AD)
        
        return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
    }
    
    public func textComposer(platform_letter: UInt8,
                             sender: String, text: String) throws -> String {
        let content = "\(sender):\(text)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: aliceState, data: content, AD: self.AD)
        
        return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
    }
    
    public func messageComposer(platform_letter: UInt8,
                                sender: String, receiver: String, message: String) throws -> String {
        let content = "\(sender):\(receiver):\(message)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: aliceState, data: content, AD: self.AD)
        
        return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
    }
    
    private func formatTransmission(header: HEADERS,
                                    cipherText: [UInt8],
                                    platform_letter: UInt8) -> String {
        
        let sHeader = header.serialize()
        
        // Convert PN to Data
        var bytesHeaderLen = Data(count: 4)
        bytesHeaderLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(sHeader.count).littleEndian, as: UInt32.self)
        }
        
        var encryptedContentPayload = Data()
        encryptedContentPayload.append(bytesHeaderLen)
        encryptedContentPayload.append(sHeader)
        encryptedContentPayload.append(Data(cipherText))
        
        var payloadLen = Data(count: 4)
        payloadLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(encryptedContentPayload.count).littleEndian, as: UInt32.self)
        }
        
        var data = Data()
        data.append(payloadLen)
        data.append(platform_letter)
        data.append(encryptedContentPayload)
        if deviceID != nil {
            data.append(Data(deviceID!))
        }

        return data.base64EncodedString()
    }
}
