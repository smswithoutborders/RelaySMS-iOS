//
//  PublisherTest1.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 04/07/2024.
//

import XCTest
import os
import CoreData

@testable import SMSWithoutBorders

class PublisherTest : XCTestCase {

    func testGetUrl() async throws {
        let publisher = Publisher()
        let response = try publisher.getOAuthURL(platform: "gmail")
        print(response.authorizationURL)
        print(response.clientID)
        print(response.redirectURL)
    }
    
//    func testGetPlatforms() async throws {
//        let expectation = XCTestExpectation(description: "JSON loading")
//        Publisher.getPlatforms() { result in
//            switch result {
//            case .success(let data):
//                print("Success: \(data)")
//            case .failure(let error):
//                XCTFail("Failed to load JSON data: \(error)")
//            }
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 10.0) // Adjust the timeout as needed
//    }
    
    private func makeInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Datastore")
        let description = NSPersistentStoreDescription()
      //  description.type = NSInMemoryStoreType /// This doesnt support batch operations causing the test to fail. Rather user a work around
        description.url = URL(fileURLWithPath: "/dev/null")
        description.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            
            if let error = error {
               // fatalError("Failed to load in-memoery store: \(error)")
                fatalError("Failed to load SQLite store for tests pointed to /dev/null: \(error)")
            } else {
                print("SQLite container for testing loaded successfully (URL: \(description.url?.absoluteString ?? "nil")).")
            }
        }
        return container.viewContext
    }
    
    
    func testTokensInPayloadShouldPublish() async throws {
        // This test  assumes the user is already created and has already added the Gmail and Twitter platform to their account
        
        // Arrange
        let context: NSManagedObjectContext = makeInMemoryManagedObjectContext()
        let vault: Vault = Vault()
        
        // Authenticate : Sign in, verify account and get LLT
        var authenticationResponse = try  vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!")
       
        if authenticationResponse.requiresOwnershipProof {
            print("Requires owenserhip proof (OTP): \(authenticationResponse.requiresOwnershipProof)")
            authenticationResponse = try vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!", ownershipResponse: "123456")
            print("Authentication Response after OTP : \(authenticationResponse)")
        }

        
        XCTAssertNotNil(authenticationResponse.longLivedToken, "Long lived token should not be null")
        XCTAssertFalse(authenticationResponse.longLivedToken == "", "Long lived token should not be empty")
        let encryptedLlt = authenticationResponse.longLivedToken
        print("encryptedLlt: \(encryptedLlt)")
        // call Vault.deriveStoredLTT before using but is already called when calling authenticated entity, so the llt is already decrypted and stored.
        
        let decryptedLlt = try Vault.getLongLivedToken()
        print("decryptedLlt: \(decryptedLlt)")
       
        // Get Platform tokens from vault
        let response = try vault.listStoredEntityToken(longLiveToken: decryptedLlt, migrateToDevice: true)
        response.storedTokens.forEach { token in
            XCTAssertNotNil(token)
            // XCTAssertTrue(token.isStoredOnDevice, "is stored on device should be true")
           // XCTAssertFalse(token.isStoredOnDevice, "is stored on device should be false")
            print("Available Platforms tokens: \(token)")
        }
        
        // Extract Tokens
        let twitterPlatformToken = response.storedTokens.first { token in token.platform == "twitter"}
        let gmailPlatformToken = response.storedTokens.first { token in token.platform == "gmail"}
       
        // XCTAssertNotNil(twitterPlatformToken, "twitter platform token should not be null")
       // XCTAssertNotNil(gmailPlatformToken, "Gmail platform token should not be null")
        
        var tAccessToken: String = ""
        var tRefreshToken: String = ""
        var gAccessToken: String = ""
        var gRefreshToken: String = ""
        
        if let twitterAccountTokens = twitterPlatformToken?.accountTokens {
            tAccessToken = twitterAccountTokens["access_token"]!
            tRefreshToken = twitterAccountTokens["refresh_token"]!
           // XCTAssertFalse(tAccessToken == "", "Access token should not be empty")
          //  XCTAssertFalse(tRefreshToken == "", "Refresh token should not be empty")
        }
        
        if let gmailAccountTokens = gmailPlatformToken?.accountTokens {
            gAccessToken = gmailAccountTokens["access_token"]!
            gRefreshToken = gmailAccountTokens["refresh_token"]!
           // XCTAssertFalse(gAccessToken == "", "Access token should not be empty")
           // XCTAssertFalse(gRefreshToken == "", "Refresh token should not be empty")
        }
    
        
        // Publish
        // 1. Compose twitter message
        let publishMessageComposer = try Publisher.publish(context: context)

        let sender: String = "nuilewis"
        let message: String = "Hello World"
        let twitterPlatfomLetter = "t".utf8.first!
        let twitterComposerResponse = try publishMessageComposer.textComposer(
            platform_letter: twitterPlatfomLetter,
            sender: sender,
            text: message,
            accessToken: tAccessToken,
            refreshToken: tRefreshToken
        )
        
        // 1b. Compose gmail message
        let from: String = "lewisnuikweh@gmail.com"
        let to: String = "lnuikweh@gmail.com"
        let cc: String = ""
        let bcc: String = ""
        let subject: String = "Test email from RelaySMS"
        let body: String = "Hello World"
        let gmailPlatformLetter = "g".utf8.first!
        let gmailComposerResponse = try publishMessageComposer.emailComposer(
            platform_letter: gmailPlatformLetter,
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            accessToken: gAccessToken,
            refreshToken: gRefreshToken
        )
        

        // 2. Trigger publish
        let twitterData: [String: String] = [
            "text": twitterComposerResponse,
            "MSISDN": "+237000011111",
            "date": "2025-04-22",
            "date_sent": "2025-04-22",
        ]
        
        let gmailData: [String: String] = [
            "text": gmailComposerResponse,
            "MSISDN": "+237000011111",
            "date": "2025-04-22",
            "date_sent": "2025-04-22",
        ]
        
        if !tAccessToken.isEmpty && !tRefreshToken.isEmpty {
            // Send twitter request
            try await sendPublishRequest(data: twitterData)
        } else {
            print("Twitter platform tokens unavailable, skipping test")
        }
        
        if !gAccessToken.isEmpty && !gRefreshToken.isEmpty {
            // Send gmail request
            try await sendPublishRequest(data: gmailData)
        } else {
            print("Gmail platform tokens unavailable, skipping test")
        }
        
        if gAccessToken.isEmpty && gRefreshToken.isEmpty && tAccessToken.isEmpty && tRefreshToken.isEmpty {
            XCTFail("No tokens available for testing, please add a platform to the test account before testing")
        }
        
 
    }
    
    
    func testTokensInPayloadShouldPublishV1() async throws {
        // This test  assumes the user is already created and has already added the Gmail and Twitter platform to their account
        
        // Arrange
        let context: NSManagedObjectContext = makeInMemoryManagedObjectContext()
        let vault: Vault = Vault()


        
        // Authenticate : Sign in, verify account and get LLT
        var authenticationResponse = try  vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!")
       
        if authenticationResponse.requiresOwnershipProof {
            print("Requires owenserhip proof (OTP): \(authenticationResponse.requiresOwnershipProof)")
            authenticationResponse = try vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!", ownershipResponse: "123456")
            print("Authentication Response after OTP : \(authenticationResponse)")
        }

        
        XCTAssertNotNil(authenticationResponse.longLivedToken, "Long lived token should not be null")
        XCTAssertFalse(authenticationResponse.longLivedToken == "", "Long lived token should not be empty")
        let encryptedLlt = authenticationResponse.longLivedToken
        print("encryptedLlt: \(encryptedLlt)")
        // call Vault.deriveStoredLTT before using but is already called when calling authenticated entity, so the llt is already decrypted and stored.
        
        let decryptedLlt = try Vault.getLongLivedToken()
        print("decryptedLlt: \(decryptedLlt)")
       
        // Get Platform tokens from vault
        let response = try vault.listStoredEntityToken(longLiveToken: decryptedLlt, migrateToDevice: true)
        response.storedTokens.forEach { token in
            XCTAssertNotNil(token)
            // XCTAssertTrue(token.isStoredOnDevice, "is stored on device should be true")
           // XCTAssertFalse(token.isStoredOnDevice, "is stored on device should be false")
            print("Available Platforms tokens: \(token)")
        }
        
        // Extract Tokens
        let twitterPlatformToken = response.storedTokens.first { token in token.platform == "twitter"}
        let gmailPlatformToken = response.storedTokens.first { token in token.platform == "gmail"}
       
        // XCTAssertNotNil(twitterPlatformToken, "twitter platform token should not be null")
       // XCTAssertNotNil(gmailPlatformToken, "Gmail platform token should not be null")
        
        var tAccessToken: String = ""
        var tRefreshToken: String = ""
        var gAccessToken: String = ""
        var gRefreshToken: String = ""
        
        if let twitterAccountTokens = twitterPlatformToken?.accountTokens {
            tAccessToken = twitterAccountTokens["access_token"]!
            tRefreshToken = twitterAccountTokens["refresh_token"]!
           // XCTAssertFalse(tAccessToken == "", "Access token should not be empty")
          //  XCTAssertFalse(tRefreshToken == "", "Refresh token should not be empty")
        }
        
        if let gmailAccountTokens = gmailPlatformToken?.accountTokens {
            gAccessToken = gmailAccountTokens["access_token"]!
            gRefreshToken = gmailAccountTokens["refresh_token"]!
           // XCTAssertFalse(gAccessToken == "", "Access token should not be empty")
           // XCTAssertFalse(gRefreshToken == "", "Refresh token should not be empty")
        }
    
        
        // Publish
        // 1. Compose twitter message
        let publishMessageComposer = try Publisher.publish(context: context)

        let sender: String = "nuilewis"
        let message: String = "Hello World V1"
        let twitterPlatfomLetter = "t".utf8.first!
        let twitterComposerResponse = try publishMessageComposer.textComposerV1(
            platform_letter: twitterPlatfomLetter,
            sender: sender,
            text: message,
            accessToken: tAccessToken,
            refreshToken: tRefreshToken
        )
        
        // 1b. Compose gmail message
        let from: String = "lewisnuikweh@gmail.com"
        let to: String = "lnuikweh@gmail.com"
        let cc: String = ""
        let bcc: String = ""
        let subject: String = "Test email from RelaySMS"
        let body: String = "Hello World V1"
        let gmailPlatformLetter = "g".utf8.first!
        let gmailComposerResponse = try publishMessageComposer.emailComposerV1(
            platform_letter: gmailPlatformLetter,
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            accessToken: gAccessToken,
            refreshToken: gRefreshToken
        )
        

        // 2. Trigger publish
        let twitterData: [String: String] = [
            "text": twitterComposerResponse,
            "MSISDN": "+237000011111",
            "date": "2025-04-22",
            "date_sent": "2025-04-22",
        ]
        
        let gmailData: [String: String] = [
            "text": gmailComposerResponse,
            "MSISDN": "+237000011111",
            "date": "2025-04-22",
            "date_sent": "2025-04-22",
        ]
        
        if !tAccessToken.isEmpty && !tRefreshToken.isEmpty {
            // Send twitter request
            try await sendPublishRequest(data: twitterData)
        } else {
            print("Twitter platform tokens unavailable, skipping test")
        }
        
        if !gAccessToken.isEmpty && !gRefreshToken.isEmpty {
            // Send gmail request
            try await sendPublishRequest(data: gmailData)
        } else {
            print("Gmail platform tokens unavailable, skipping test")
        }
        
        if gAccessToken.isEmpty && gRefreshToken.isEmpty && tAccessToken.isEmpty && tRefreshToken.isEmpty {
            XCTFail("No tokens available for testing, please add a platform to the test account before testing")
        }
        
 
    }
    
    func sendPublishRequest(data: [String: String]) async throws {
        print("Sending publishing request with data: \(data)")
        let url: URL = URL(string:"https://gatewayserver.staging.smswithoutborders.com/v3/publish")!
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataSerialized = try JSONSerialization.data(withJSONObject: data, options: [])
        request.httpBody = dataSerialized
        
        print("Serialized http body data: \(String(data: dataSerialized, encoding: .utf8) ?? "Error serializing data")")
        
        print("Sending Publishing request to \(request) ...")
        
        let (_data, apiResponse) = try await URLSession.shared.data(for: request)

        if let json = try JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any] {
            print("Response message json: \(json)")
        }
        let httpResponse = apiResponse as? HTTPURLResponse
        print("Response status code: \(String(describing: httpResponse?.statusCode))")
        XCTAssertTrue(httpResponse?.statusCode == 200, "Should publish successfully")
    }

}
