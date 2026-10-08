//
//  Cryptography.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 23/09/2026.
//

import CryptoKit

func generateNewKeypair() -> Curve25519.KeyAgreement.PrivateKey? {
    return Curve25519.KeyAgreement.PrivateKey()
}

