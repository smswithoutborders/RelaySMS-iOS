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
    publisherPublicKey: Curve25519.KeyAgreement.PrivateKey?,
    deviceIDPublicKey: Curve25519.KeyAgreement.PrivateKey?) {
        do {
            return (try SecurityCurve25519.generateKeyPair(), try SecurityCurve25519.generateKeyPair())
        } catch {
            throw error
        }
}


