//
//  TokensViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 15/10/2026.
//

import Observation
import SwiftData
import Foundation

@Observable
class TokensViewModel {
    
    func getCount(tokenId: UUID, into container: ModelContainer) -> Int {
        var keysFound = 0
        for i in 0...255 {
            let tag = Keystore.getLocalKeysAccountTag(
                keyId: UInt8(i),
                tokenId: tokenId
            )
            let keystore = Keystore(accountTag: tag)
            do {
                if try keystore.isAvailable() {
                    keysFound += 1
                }
            } catch {
                print(error)
            }
        }
        
        return keysFound
    }
}
