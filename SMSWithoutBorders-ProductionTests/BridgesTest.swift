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
// Or your Core Data queue
        let context = DataController().container.viewContext
        
        let (sharedSecret, _clientPublicKey, peerPublishPublicKey, serverPublicKeyID) = try Bridges.generateKeyRequirements()
        
        let clientPublicKey = _clientPublicKey.rawRepresentation.withUnsafeBytes {
            Array($0)
        }
        print("AD for encrypting: \(_clientPublicKey.rawRepresentation.base64EncodedString())")
        
        var to = "wisdomnji@gmail.com"
        var cc = ""
        var bcc = ""
        var subject = "Test email"
        var body = "Hello world"
        
        try Vault.resetStates(context: context)
        
        var cipherText = try Bridges.compose(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            sk: sharedSecret,
            ad: peerPublishPublicKey.rawRepresentation.bytes,
            peerDhPubKey: peerPublishPublicKey,
            context: context)

        var payload = try Bridges.authRequestAndPayload(
            context: context,
            cipherText: cipherText,
            clientPublicKey: clientPublicKey,
            serverKeyID: serverPublicKeyID
        )
        
        print("Executing first stage... auth + payload")
        let responseCode = try await executePayload(payload: payload!)
        XCTAssertEqual(responseCode, 200)
        print("- First stage complete")

//       cipherText = try Bridges.compose(
//            to: to,
//            cc: cc,
//            bcc: bcc,
//            subject: subject,
//            body: "Hello world 2",
//            sk: nil,
//            ad: peerPublishPublicKey.rawRepresentation.bytes,
//            peerDhPubKey: nil,
//            context: context)
//
//        print("Executing second stage... payload")
//        payload = try Bridges.payloadOnly(context: context, cipherText: cipherText)
//        let responseCode1 = try await executePayload(payload: payload!)
//        XCTAssertEqual(responseCode1, 200)
    
    }
    
    func testBridgeDecryption() async throws {
        let context = DataController().container.viewContext
        let ad = Data(base64Encoded: "1SxA+mrZGF0DaKOBabbQPPytY7j28JdMND9gzTZhOjk=")?.withUnsafeBytes { Array($0) } ?? []
//        let ad: [UInt8] = UserDefaults.standard.object(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as! [UInt8]
        print("AD for decrypting: \(ad)")

        let rawText = "RelaySMS Reply Please paste this entire message in your RelaySMS app\nvAAAAGUoAAAAAAAAAAAAAACxHc73tAyz3QpIajfPiFRWqHzkyhSrPOc7n9JV7h/xfGH9taDkUXr+/YXpePjnOLyqYyTEW/q/isXnlIgYRExt5a8Hjiow4sOrgLVHqSm6+i6/jK9Sb2JWcjpK0O7UFrnmrpobyQbAWQz0D/2EvUZVo0qFQIPEh7jFAgahA1fbqIwyXNRLppjMfs2mPtrfk/TotYX/NpkIeqVm72CUCJw6+MtYMX5RDLkkIcQU3CsZzg=="
        let sampleText: String = String(rawText.split(separator: "\n")[1])
        print("Sending in sampleText: \(sampleText)")
        let cipherText: [UInt8] = Data(base64Encoded: sampleText)?.withUnsafeBytes{ Array($0) } ?? []
        
        XCTAssertTrue(cipherText.count > 0)
        
        let text = try Bridges.decryptIncomingMessages(
            context: context,
            payload: cipherText,
            ad: ad
        )
        print(text)
    }
    
    func executePayload(payload: String) async throws -> Int? {
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
