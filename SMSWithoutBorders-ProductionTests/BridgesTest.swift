//
//  BridgesTest.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 11/11/2024.
//

import XCTest
import CoreData
import SwobDoubleRatchet


@testable import SMSWithoutBorders
import CryptoKit


public class BridgesTest: XCTestCase {
    
    func testReadStaticKeys() async throws {
        let keys = Bridges.getStaticKeys()
        XCTAssertEqual(255, keys!.count)
    }
    
    func testBridges() async throws {
        let context = DataController().container.viewContext
        
        try Vault.resetKeystore(context: context)
        Bridges.reset()

        var to = "wisdomnji@gmail.com"
        var cc = ""
        var bcc = ""
        var subject = "Test email"
        var body = "Hello world"
        
        var (cipherText, clientPublicKey) = try Bridges.compose(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            context: context
        )

        var payload = try Bridges.authRequestAndPayload(
            context: context,
            cipherText: cipherText,
            clientPublicKey: clientPublicKey!
        )
        
        print("Executing first stage... auth + payload")
        var responseCode = try await BridgesTest.executePayload(payload: payload!)
        XCTAssertEqual(responseCode, 200)
        print("- First stage complete")
        
        (cipherText, clientPublicKey) = try Bridges.compose(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            context: context
        )

        payload = try Bridges.authRequestAndPayload(
            context: context,
            cipherText: cipherText,
            clientPublicKey: clientPublicKey!
        )
        
        print("Executing second stage... auth + payload")
        responseCode = try await BridgesTest.executePayload(payload: payload!)
        XCTAssertEqual(responseCode, 200)
        print("- Second stage complete")
        
    }
    
//    func testBridgesPlatforms() async throws {
//        (cipherText, clientPublicKey) = try Bridges.compose(
//            to: to,
//            cc: cc,
//            bcc: bcc,
//            subject: subject,
//            body: "Hello world 2",
//            context: context)
//
//        print("Executing second stage... payload")
//        payload = try Bridges.payloadOnly(context: context, cipherText: cipherText)
//        let responseCode1 = try await executePayload(payload: payload!)
//        XCTAssertEqual(responseCode1, 200)
//    }
    
    func testBridgeDecryption() async throws {
        let context = DataController().container.viewContext

        let rawText = "RelaySMS Reply Please paste this entire message in your RelaySMS app\nzAAAAGUoAAAAAAAAAAAAAAD4eFJY+zgNQ4eFRb8Rg+EkEVhU3FUTEz9h+Ggq1NnxXmz9M3V0nXKAZo2qT5h4R1NuUr4PsK3BWy0cVhWYMJOV3JG4iriNe+BE7T0v80ub6inhxlCC2HPo3b1tNPR3+ms/KOIkYuFIHzzwAhcGIEmZEktSj4NCCIlE/ryuGip9OedJvvDROpx+az1XfrGRUuxi0r5mlLxsxY3EF/eJ+XlWKaUnnqG3Lt5iwQPa60jf/6Q3k5ykyas1AAEbvmndbY4="
        let sampleText: String = String(rawText.split(separator: "\n")[1])
        print("Sending in sampleText: \(sampleText)")
        let cipherText: [UInt8] = Data(base64Encoded: sampleText)?.withUnsafeBytes{ Array($0) } ?? []
        
        XCTAssertTrue(cipherText.count > 0)
        
        let text = try Bridges.decryptIncomingMessages(
            context: context,
            payload: cipherText
        )
        print(text)
    }
    
    static func executePayload(payload: String) async throws -> Int? {
        guard let url = URL(string: "https://gatewayserver.staging.smswithoutborders.com/v3/publish") else { return 0 }
        
        print(payload)
        let _requestBody = ["address": "+237123456789", "text": payload]
        let requestBody = try JSONSerialization.data(withJSONObject: _requestBody)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_data, response) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any] {
            print(json)
        }
        let httpResponse = response as? HTTPURLResponse
        return httpResponse?.statusCode
    }
    
}
