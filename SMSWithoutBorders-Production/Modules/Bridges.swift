//
//  Bridges.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 06/02/2025.
//

import Foundation

struct Bridges {
    
    // TODO: download public key files
    // TODO: read the file and reference the kid - could be static or random for now
    
    public static func authRequestAndPayload(cipherText: [UInt8], clientPublicKey: [UInt8]) -> String {
        var versionMarker: UInt8 = 0x0A
        var switchValue: UInt8 = 0x00
        var clientPublicKeyLength: UInt8 = 0x00
        var cipherTextLength: Data = Data(count: 2)
        cipherTextLength.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt16(cipherText.count).littleEndian, as: UInt16.self)
        }
        var bridgeLetter: UInt8 = "e".utf8.first!
        var serverKeyIdentifier: UInt8 = 0x00 // TODO: should have a method of taking this at random
        
        var payload = Data()
        payload.append(versionMarker)
        payload.append(switchValue)
        payload.append(clientPublicKeyLength)
        payload.append(cipherTextLength)
        payload.append(bridgeLetter)
        payload.append(serverKeyIdentifier)
        payload.append(Data(clientPublicKey))
        payload.append(Data(cipherText))

        return payload.base64EncodedString()
    }
}
