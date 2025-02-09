//
//  SecurityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 30/01/2025.
//

import Foundation
import CryptoKit
import SwobDoubleRatchet

func generateNewKeypairs() throws -> (
    publisherPublicKey: Curve25519.KeyAgreement.PrivateKey,
    deviceIDPublicKey: Curve25519.KeyAgreement.PrivateKey) {
    
        // TODO: this stops platforms from working with bridges
        CSecurity.deleteKeyFromKeychain(keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS)
        CSecurity.deleteKeyFromKeychain(keystoreAlias: Vault.DEVICE_PUBLIC_KEY_KEYSTOREALIAS)

        var clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey?
        var clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey?
        
        do {
            clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: Vault.DEVICE_PUBLIC_KEY_KEYSTOREALIAS).privateKey
            
            clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS).privateKey
        } catch {
            throw error
        }
        return (clientPublishPrivateKey!, clientDeviceIDPrivateKey!)
}


