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
        
        let url = "https://gatewayserver.staging.smswithoutborders.com"
        
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
        let response = try! JSONDecoder().decode([GatewayClients].self, from: data)
    }
    
}
