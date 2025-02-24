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
    
    static let CLIENT_PUBLIC_KEY_KEYSTOREALIAS = "com.afkanerd.CLIENT_PUBLIC_KEY_KEYSTOREALIAS"
    static let SERVER_KID = "com.afkanerd.SERVER_KID"
    static let SERVICE_NAME = "com.afkanerd.BRIDGES"

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
        context: NSManagedObjectContext) throws -> ([UInt8], [UInt8]?){
            
            var messageComposer: MessageComposer? = nil
            var clientPublicKey: [UInt8]? = nil
            var sharedSecret: [UInt8]? = nil
            var peerPublishPublicKey: Curve25519.KeyAgreement.PublicKey? = nil

            // Meaning the user has logged in online already
            if(try Vault.getLongLivedToken().isEmpty) {
                if(!MessageComposer.hasStates(context: context)) {
                    try Vault.resetStates(context: context)
                    
                    let (_sharedSecret, _clientPublicKey, _peerPublishPublicKey, serverPublicKeyID) = try Bridges.generateKeyRequirements()
                    peerPublishPublicKey = _peerPublishPublicKey
                    sharedSecret = _sharedSecret
                    clientPublicKey = _clientPublicKey?.rawRepresentation.bytes
                    
                    UserDefaults.standard.set(clientPublicKey, forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS)
                    UserDefaults.standard.set(
                        peerPublishPublicKey?.rawRepresentation.bytes,
                        forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY
                    )
                    UserDefaults.standard.set(serverPublicKeyID, forKey: Bridges.SERVER_KID)
                }
                else {
                    print("\n[+] Bypassing key generation, using stored keys")
                    let serverKeyID: UInt8 = UserDefaults.standard.object(forKey: Bridges.SERVER_KID) as! UInt8
                    var pubKeyB64 = Bridges.getStaticKeys(kid: Int(serverKeyID))?.first?.keypair
                    let pubKey = Data(base64Encoded: pubKeyB64!)
                    peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: pubKey!)
                    clientPublicKey = UserDefaults.standard.object(forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS) as? [UInt8]
                }

                do {
                    messageComposer = try MessageComposer(
                        SK: sharedSecret,
                        AD: peerPublishPublicKey!.rawRepresentation.bytes,
                        peerDhPubKey: peerPublishPublicKey,
                        keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS,
                        context: context)
                } catch {
                    print("Bridges raising exception: \(error)")
                }
            } else {
                let AD: [UInt8] = UserDefaults.standard.object(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as! [UInt8]
                clientPublicKey = UserDefaults.standard.object(
                    forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS) as! [UInt8]

                if(!MessageComposer.hasStates(context: context)) {
                    sharedSecret = try Vault.getPublisherSharedSecret()
                }

                messageComposer = try MessageComposer(
                    SK: sharedSecret,
                    AD: AD,
                    peerDhPubKey: Curve25519.KeyAgreement.PublicKey(rawRepresentation: AD),
                    keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS,
                    context: context
                )
            }
            
            let data = try messageComposer!.bridgeEmailComposer(
                to: to,
                cc: cc,
                bcc: bcc,
                subject: subject,
                body: body
            )
            
            let cipherText = data.withUnsafeBytes { Array($0) }
            return (cipherText, clientPublicKey)
    }
    
    public static func reset() {
        UserDefaults.standard.removeObject(forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS)
        UserDefaults.standard.removeObject(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY )
        UserDefaults.standard.removeObject(forKey: Bridges.SERVER_KID)
    }
    
    private static func generateKeyRequirements() throws -> (
        [UInt8]?,
        Curve25519.KeyAgreement.PublicKey?,
        Curve25519.KeyAgreement.PublicKey?,
        UInt8
    ) {
        let (publishPrivateKey, deviceIdPrivateKey) = try generateNewKeypairs()
//        let clientPublishPubKey = publishPrivateKey.publicKey.rawRepresentation.base64EncodedString()
//        print(clientPublishPubKey)
        
        let serverPublicKeys = Bridges.getStaticKeys()
        let serverPublicKeyPair = try serverPublicKeys!.first //TODO: randomize key acquisition
        let serverPublicKeyID: UInt8 = UInt8(exactly: serverPublicKeyPair!.kid)!
        
        let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: (serverPublicKeyPair?.keypair.base64Decoded())!)
//        let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ("QdoWCeu1i3Xdmjf45Dpr+8kpLDz+l4936s2Tu+QruRg=".base64Decoded()))

        let sharedSecret = try SecurityCurve25519.calculateSharedSecret(
            privateKey: publishPrivateKey!, publicKey: peerPublishPublicKey).withUnsafeBytes {
                return Array($0)
            }
//        print("SK: \(sharedSecret.toBase64())")
        
        return (sharedSecret, publishPrivateKey?.publicKey, peerPublishPublicKey, serverPublicKeyID)
    }

    public static func authRequestAndPayload(
        context: NSManagedObjectContext,
        cipherText: [UInt8],
        clientPublicKey: [UInt8]
    ) throws -> String? {
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
        let serverKeyID: UInt8 = UserDefaults.standard.value(forKey: Bridges.SERVER_KID) as! UInt8

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
    
    public static func payloadOnly(
        context: NSManagedObjectContext,
        cipherText: [UInt8]
    ) throws -> String? {
        let mode: UInt8 = 0x00
        let versionMarker: UInt8 = 0x0A
        let switchValue: UInt8 = 0x01
        var cipherTextLength: Data = Data(count: 2)
        cipherTextLength.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt16(cipherText.count).littleEndian, as: UInt16.self)
        }
        let bridgeLetter: UInt8 = "e".data(using: .utf8)!.first!
        
        var payload = Data()
        payload.append(mode)
        payload.append(versionMarker)
        payload.append(switchValue)
        payload.append(cipherTextLength)
        payload.append(bridgeLetter)
        payload.append(Data(cipherText))

        return payload.base64EncodedString()
    }
    
    public static func getStaticKeys(kid: Int? = nil) -> [StaticKeys]? {
        guard let url = Bundle.main.path(forResource: "static-x25519", ofType: "json") else {
            print("Error reading file...")
            return nil
        }
        print("[+] File url: \(url)")
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: url))

            var result = try JSONDecoder().decode([StaticKeys].self, from: data)
            
            if(kid != nil) {
                for keypair in result {
                    if keypair.kid == kid {
                        result = [keypair]
                        break
                    }
                }
            }
            
            return result
        } catch {
            print("Error decoding json: \(error)")
        }

        return nil
    }
    
    public static func decryptIncomingMessages(context: NSManagedObjectContext, text: String) throws -> (
        fromAccount: String,
        cc: String,
        bcc: String,
        subject: String,
        body: String,
        date: Int32
    ) {
        let splitText: String = String(text.split(separator: "\n")[1])
        let payload: [UInt8] = Data(base64Encoded: splitText)?.withUnsafeBytes{ Array($0) } ?? []
        let cipherTextLen = payload[0..<4]
        let bridgeLetter = payload[4]
        let cipherText = Array(payload[5...])
        
        let ad = UserDefaults.standard.object(forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS) as! [UInt8]
        
        let messageComposer = try MessageComposer(
            SK: nil,
            AD: ad,
            peerDhPubKey: nil,
            keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS,
            context: context
        )
        
        var decryptedText = ""
        do {
            decryptedText = try messageComposer.decryptBridgeMessage(payload: cipherText)!
        } catch {
            print(error)
        }
        
        return formatMessageAfterDecryption(message: decryptedText)
    }
    
    public static func formatMessageAfterDecryption(message: String) ->
    (fromAccount: String, cc: String, bcc: String, subject: String, body: String, date: Int32
    ) {
        
        let splitMessage = message.split(separator: ":", omittingEmptySubsequences: false)
        print(splitMessage)
        let fromAccount = splitMessage[0]
        let cc = splitMessage[1]
        let bcc = splitMessage[2]
        let subject = splitMessage[3]
        let body = splitMessage[4]
        let date = Int32(Date().timeIntervalSince1970)

        return (
            String(fromAccount),
            String(cc),
            String(bcc),
            String(subject),
            String(body),
            date: date
        )
    }
}
