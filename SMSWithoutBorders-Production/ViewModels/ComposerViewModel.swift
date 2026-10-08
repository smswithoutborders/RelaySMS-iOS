//
//  ComposerViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 01/10/2026.
//

import Observation
import Foundation
import SwiftData

enum ComposeState : Equatable{
    case loading
    case idle
    case failure(data: String)
}

@Observable
class ComposerViewModel {
    
    private(set) var composeState: ComposeState = .idle

    var payload: String?
    
    func publish(
        catId: V1ContentCategories,
        body: String,
        platformName: String,
        tokenId: UUID,
        to: String?,
        subject: String?,
        into container: ModelContainer
    ) async throws {
        composeState = .loading
        
        let ofp = OnlineFirstPublisher()
        do {
            try ofp.publish(
                catId: catId,
                body: body,
                platformName: platformName,
                tokenId: tokenId,
                to: to,
                subject: subject,
                into: container
            ) { sp in
                payload = sp
            }
            // TODO: save this output
            composeState = .idle
        } catch {
            composeState = .failure(data: error.localizedDescription)
            throw error
        }
    }
}
