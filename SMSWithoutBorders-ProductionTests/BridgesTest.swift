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


class BridgesTest: XCTestCase {
    
    func testReadStaticKeys() async throws {
        let keys = Bridges.getStaticKeys()
        XCTAssertEqual(255, keys!.count)
    }
    
    func testBridges() async throws {
        let context = DataController().container.viewContext
        
        let (sharedSecret, clientPublicKeyObject, peerPublishPublicKey, serverPublicKeyID) = try Bridges.generateKeyRequirements()
        let clientPublicKey = clientPublicKeyObject.rawRepresentation.withUnsafeBytes {
            Array($0)
        }
        
        var to = "wisdomnji@gmail.com"
        var cc = ""
        var bcc = ""
        var subject = "Test email"
        var body = "Hello world"
        
        let cipherText = try Bridges.compose(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            sk: sharedSecret!,
            ad: clientPublicKey,
            peerDhPubKey: peerPublishPublicKey,
            context: context)

        let payload = try Bridges.authRequestAndPayload(
            context: context,
            cipherText: cipherText,
            clientPublicKey: clientPublicKey,
            serverKeyID: serverPublicKeyID
        )
        print(payload)

        guard let url = URL(string: "https://gatewayserver.staging.smswithoutborders.com/v3/publish") else { return }
        
        let _requestBody = ["address": "+237123456789", "text": payload]
        let requestBody = try JSONSerialization.data(withJSONObject: _requestBody)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
//            XCTAssertTrue((200...299).contains(httpResponse.statusCode))
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
        if let json = try JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any] {
            // try to read out a string array
//            if let nickname = json["nickname"] as? [String] {
//                print(nickname)
//            }
            print(json)
        }
    }
    
}
