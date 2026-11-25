//
//  OnlineFirstPublisherViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 29/09/2026.
//

import CoreData
import Foundation

enum SendOnlineStates {
    case loading
    case idle
    case failure(data: String)
    case success(data: String)
}

@Observable
class OnlineFirstPublisherViewModel {
    enum OnlineFirstPublisherViewModelError: Error {
        case failedToEncodeToBase64
    }
    private(set) var sendOnlineState: SendOnlineStates = .idle

    private class GatewayClientRequests: Codable {
        var address: String
        var text: String
        var tag: String
        init(
            address: String,
            text: String,
            tag: String,
        ) {
            self.address = address
            self.text = text
            self.tag = tag
        }
    }
    
    func sendJsonData(_ data: String) async throws {
        sendOnlineState = .loading
        guard let url = URL(string: StaticVariables.Publisher.mimicGatewayClientUrl) else {
            sendOnlineState = .idle
            return
        }
        
//        guard let text = data.data(using: .utf8)?.base64EncodedString() else {
//            throw OnlineFirstPublisherViewModelError.failedToEncodeToBase64
//        }
        
        let payload = GatewayClientRequests(
            address: "address",
            text: data,
            tag: "13c5279b252d2583a048d9ae15a18fc6ac2fc283088168368334e22a23fb229e"
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let body = String(data: data, encoding: .utf8) ?? ""

            if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                sendOnlineState = .success(data: body)
            } else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                sendOnlineState = .failure(data: "\(status): \(body)")
            }
        } catch {
            print("Failed to send JSON: \(error.localizedDescription)")
            sendOnlineState = .failure(data: error.localizedDescription)
        }
    }
}

