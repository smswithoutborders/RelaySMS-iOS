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
        var responseCode = try await BridgesTest.executePayload(phoneNumber: "+237123456789", payload: payload!)
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
        responseCode = try await BridgesTest.executePayload(phoneNumber: "+237123456789", payload: payload!)
        XCTAssertEqual(responseCode, 200)
        print("- Second stage complete")
        
        (cipherText, clientPublicKey) = try Bridges.compose(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: "Hello world 2",
            context: context)

        print("Executing second stage... payload")
        payload = try Bridges.payloadOnly(context: context, cipherText: cipherText)
        var responseCode1 = try await BridgesTest.executePayload(phoneNumber: "+237123456789", payload: payload!)
        XCTAssertEqual(responseCode1, 200)

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

        let rawText = "RelaySMS Reply Please paste this entire message in your RelaySMS app\nH1YAAA4QAOwAZSgAAAAAAAAAAgAAALLkLsdCp/23hlzxN4+8GgToup5MQEtKkHnLn3xuY8wjfg54zxCmeoK0LceFK8g27VZIOqKITqZDDysJ0i+1H9daQ/Aa3aL7rrekQJ3Bphxzm3Vx2F+XFaMgsZSKCdPs5UlV0/X/Gc4HH6dn/xYdzrcWNdaG+0YzqP6Yzy5kgLJIy7HBKhsWtwSUqvVqCAuMiJQhaC553+e93/sz6walbjnyGae2iHluD2sNWzWXc4SUhomwdE7/q1Xh+CeTzHCYmZCDTM0S8BTWMtgromtaXvTVDn9WXfGvQ/IpQcXmMsKY\n2025-02-26 22:07:17 (UTC+01:00)"
        let text = try Bridges.decryptIncomingMessages(
            context: context,
            text: rawText
        )
        print(text)
    }
    
    func testBridgeDecryptionFormatting() throws {
        var text = "Dev SMSWithoutBorders - dev at relaysms.me <dev_at_relaysms_me_sduzxjiklr@simplelogin.co>:::Re Test email:Hello world back at you"
        
        var splitText = text.split(separator: ":", omittingEmptySubsequences: false)
        
//        let format = Bridges.formatMessageAfterDecryption(
//            lenAliasAddress: <#Int#>,
//            lenSender: <#Int#>,
//            lenCC: <#Int#>,
//            lenBCC: <#Int#>,
//            lenSubject: <#Int#>,
//            lenBody: <#Int#>,
//            message: <#[UInt8]#>,
//            timestamp: <#String#>
//        )
//        XCTAssertEqual(format.fromAccount, "Dev SMSWithoutBorders - dev at relaysms.me <dev_at_relaysms_me_sduzxjiklr@simplelogin.co>")
//        XCTAssertEqual(format.cc, "")
//        XCTAssertEqual(format.bcc, "")
//        XCTAssertEqual(format.subject, "Re Test email")
//        XCTAssertEqual(format.body, "Hello world back at you")
    }
    
    static func executePayload(phoneNumber: String, payload: String) async throws -> Int? {
        guard let url = URL(string: "https://gatewayserver.staging.smswithoutborders.com/v3/publish") else { return 0 }
        
        print(payload)
        let _requestBody = ["address": phoneNumber, "text": payload]
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
