//
//  TokensViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 15/10/2026.
//

import Observation
import SwiftData
import Foundation


enum TokensStates {
    case loading
    case idle
    case failure(data: String)
}

@Observable
class TokensViewModel {
    private(set) var tokenStates: TokensStates = .idle
    
    enum TokensViewModelError: Error {
        case failedToRefreshKey
    }
    
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
    
    func refreshKeys(account: Tokens, into container: ModelContainer) async throws {
        tokenStates = .loading
        
        let publisherImpl = PublisherImpl(container: container)
        
        do {
            try await publisherImpl.refreshKeys(account: account)
        } catch {
            print(error)
            tokenStates = .failure(data: error.localizedDescription)
            throw TokensViewModelError.failedToRefreshKey
        }
        tokenStates = .idle
    }
}
