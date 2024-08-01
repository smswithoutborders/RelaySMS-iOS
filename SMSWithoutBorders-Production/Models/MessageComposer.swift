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

    init(SK: [UInt8], AD: [UInt8], peerDhPubKey: Curve25519.KeyAgreement.PublicKey, keystoreAlias: String) throws {
        self.SK = SK
        self.keystoreAlias = keystoreAlias
        self.AD = AD
        
        try Ratchet.aliceInit(
            state: self.aliceState,
            SK: self.SK,
            bobDhPubKey: peerDhPubKey,
            keystoreAlias: self.keystoreAlias)
    }
    
    public func emailComposer(from: String, to: String, cc: String, bcc: String, subject: String, body: String) throws -> String {
        let content = "\(from):\(to):\(cc):\(bcc):\(subject):\(body)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: aliceState, data: content, AD: self.AD)
        
        return formatTransmission(header: header, cipherText: cipherText)
    }
    
    public func textComposer(sender: String, text: String) throws -> String {
        let content = "\(sender):\(text)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: aliceState, data: content, AD: self.AD)
        
        return formatTransmission(header: header, cipherText: cipherText)
    }
    
    public func messageComposer(sender: String, receiver: String, message: String) throws -> String {
        let content = "\(sender):\(receiver):\(message)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: aliceState, data: content, AD: self.AD)
        
        return formatTransmission(header: header, cipherText: cipherText)
    }
    
    private func formatTransmission(header: HEADERS, cipherText: [UInt8] ) -> String {
        let sHeader = header.serialize()
        
        // Convert PN to Data
        var bytesHeaderLen = Data(count: 4)
        bytesHeaderLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(sHeader.count).littleEndian, as: UInt32.self)
        }
        
        var data = Data()
        data.append(bytesHeaderLen)
        data.append(header.serialize())
        data.append(Data(cipherText))
        
        return data.base64EncodedString()
    }
}
