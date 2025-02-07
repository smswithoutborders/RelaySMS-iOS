//
//  BridgesTest.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 11/11/2024.
//

import XCTest
import CoreData


@testable import SMSWithoutBorders


class BridgesTest: XCTestCase {
    func testBridges() async throws {
        let context = DataController().container.viewContext
        
        guard let url = URL(string: "https://gatewayserver.staging.smswithoutborders.com/v3/publish") else { return }
        
        let _requestBody = ["address": "+123456789", "text": "Hello world"]
        let requestBody = try JSONSerialization.data(withJSONObject: _requestBody)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
//            XCTAssertTrue((200...299).contains(httpResponse.statusCode))
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            // try to read out a string array
//            if let nickname = json["nickname"] as? [String] {
//                print(nickname)
//            }
            print(json)
        }
    }
    
}
