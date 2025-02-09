//
//  Bridges.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 06/02/2025.
//

import Foundation
import CryptoKit
import SwobDoubleRatchet
import CoreData

struct Bridges {
    
    public static var BRIDGES_PUBLIC_KEY_KEYSTOREALIAS = "COM.AFKANERD.BRIDGES_PUBLIC_KEY_KEYSTOREALIAS"

    // TODO: download public key files
    // TODO: read the file and reference the kid - could be static or random for now
    
    class StaticKeys: Codable {
        var keypair: String
        var kid: Int // Should be forced into 1 byte
        var status: String
    }
    
    public static func compose(
        to: String,
        cc: String,
        bcc: String,
        subject: String,
        body: String,
        sk: [UInt8],
        ad: [UInt8],
        peerDhPubKey: Curve25519.KeyAgreement.PublicKey,
        context: NSManagedObjectContext) throws -> [UInt8]{
            
            let messageComposer = try MessageComposer(
                SK: sk,
                AD: ad,
                peerDhPubKey: peerDhPubKey,
                keystoreAlias: Bridges.BRIDGES_PUBLIC_KEY_KEYSTOREALIAS,
                context: context)
            
            let data = try messageComposer.bridgeEmailComposer(
                to: to,
                cc: cc,
                bcc: bcc,
                subject: subject,
                body: body
            )
            let cipherText = data.withUnsafeBytes {
                Array($0)
            }
            return cipherText
    }
    
    public static func generateKeyRequirements() throws -> (
        [UInt8]?,
        Curve25519.KeyAgreement.PublicKey,
        Curve25519.KeyAgreement.PublicKey,
        UInt8
    ) {
        let (publishPrivateKey, deviceIdPrivateKey) = try generateNewKeypairs()
        let clientPublishPubKey = publishPrivateKey.publicKey.rawRepresentation.base64EncodedString()
        print(clientPublishPubKey)
        
        let serverPublicKeys = Bridges.getStaticKeys()
        let serverPublicKeyPair = try serverPublicKeys!.first
        let serverPublicKeyID: UInt8 = UInt8(exactly: serverPublicKeyPair!.kid)!
        
        let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: (serverPublicKeyPair?.keypair.base64Decoded())!)
//        let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ("QdoWCeu1i3Xdmjf45Dpr+8kpLDz+l4936s2Tu+QruRg=".base64Decoded()))

        let sharedSecret = try SecurityCurve25519.calculateSharedSecret(
            privateKey: publishPrivateKey, publicKey: peerPublishPublicKey).withUnsafeBytes {
                return Array($0)
            }
        print("SK: \(sharedSecret.toBase64())")
        
        return (sharedSecret, publishPrivateKey.publicKey, peerPublishPublicKey, serverPublicKeyID)
    }

    public static func authRequestAndPayload(
        context: NSManagedObjectContext,
        cipherText: [UInt8],
        clientPublicKey: [UInt8],
        serverKeyID: UInt8) throws -> String? {
            let mode: UInt8 = 0x00
            let versionMarker: UInt8 = 0x0A
            let switchValue: UInt8 = 0x00
            var clientPublicKeyLength: Data = Data(count: 1)
            clientPublicKeyLength.withUnsafeMutableBytes {
                $0.storeBytes(of: UInt8(clientPublicKey.count).littleEndian, as: UInt8.self)
            }
            var cipherTextLength: Data = Data(count: 2)
            cipherTextLength.withUnsafeMutableBytes {
                $0.storeBytes(of: UInt16(cipherText.count).littleEndian, as: UInt16.self)
            }
            let bridgeLetter: UInt8 = "e".data(using: .utf8)!.first!
            
            var payload = Data()
            payload.append(mode)
            payload.append(versionMarker)
            payload.append(switchValue)
            payload.append(clientPublicKeyLength)
            payload.append(cipherTextLength)
            payload.append(bridgeLetter)
            payload.append(serverKeyID)
            payload.append(Data(clientPublicKey))
            payload.append(Data(cipherText))

            return payload.base64EncodedString()
    }
    
    public static func getStaticKeys() -> [StaticKeys]? {
        guard let url = Bundle.main.path(forResource: "static-x25519", ofType: "json") else {
            print("Error reading file...")
            return nil
        }
        print("[+] File url: \(url)")
        
        do {
//            let string = try String(contentsOfFile: url, encoding: String.Encoding.utf8)
//            print(string)
            let data = try Data(contentsOf: URL(fileURLWithPath: url))

            
            let result = try JSONDecoder().decode([StaticKeys].self, from: data)
            print(result)
            
            return result
        } catch {
            print("Error decoding json: \(error)")
        }

        return nil
    }
}
