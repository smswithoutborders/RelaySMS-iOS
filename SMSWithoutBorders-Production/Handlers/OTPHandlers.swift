//
//  OTPHandlers.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 30/01/2025.
//

import Foundation
import CryptoKit
import SwobDoubleRatchet
import Fernet

nonisolated func processOTP(peerDeviceIdPubKey: [UInt8],
                        publishPubKey: [UInt8],
                        llt: String,
                        clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey,
                                    clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey,
                                    phoneNumber: String) throws -> String {

    let peerDeviceIdPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerDeviceIdPubKey)
    let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publishPubKey)

    let deviceIdSharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientDeviceIDPrivateKey, publicKey: peerDeviceIdPublicKey).withUnsafeBytes {
            return Array($0)
        }
        
    let fernetToken = try Fernet(key: Data(deviceIdSharedKey))
    let decodedOutput = try fernetToken.decode(Data(base64Encoded: llt)!)
    
    let llt = String(data: decodedOutput.data, encoding: .utf8)
    print("llt: \(String(describing: llt))")

    let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientPublishPrivateKey, publicKey: peerPublishPublicKey).withUnsafeBytes {
            return Array($0)
        }
    
    CSecurity.deletePasswordFromKeychain(keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
    CSecurity.deletePasswordFromKeychain(keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)

    let deviceID = try Vault.getDeviceID(derivedKey: deviceIdSharedKey,
                                         phoneNumber: phoneNumber,
                                         publicKey: clientDeviceIDPrivateKey.publicKey.rawRepresentation.bytes)
    
    print("Peer publish pubkey raw: \(publishPubKey.toBase64())")
    UserDefaults.standard.set(deviceID, forKey: Vault.VAULT_DEVICE_ID)
    UserDefaults.standard.set(publishPubKey, forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY)
    
    let AD: [UInt8] = UserDefaults.standard.object(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as! [UInt8]
    print("Peer publish pubkey retrieved: \(AD.toBase64())")

    try CSecurity.storeInKeyChain(data: llt!.data(using: .utf8)!,
                                  keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
    try CSecurity.storeInKeyChain(data: Data(publishingSharedKey),
                                  keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
    
    return llt!
}

