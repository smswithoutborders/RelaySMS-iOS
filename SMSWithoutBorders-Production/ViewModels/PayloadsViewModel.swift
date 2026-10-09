//
//  PaylaodsViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 09/10/2026.
//

import SwiftData

@Observable
class PayloadsViewModel {
    
    func insert(payload: Payloads, into container: ModelContainer) throws {
        let context = ModelContext(container)
        do {
            context.insert(payload)
            try context.save()
        } catch {
            throw error
        }
    }
}
