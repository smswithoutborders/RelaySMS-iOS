//
//  StoredTokensEntityManagerTest.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 24/04/2025.
//


import CoreData
import XCTest
@testable import SMSWithoutBorders

final class StoredTokensEntityManagerTest: XCTestCase {
    
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
    
    var context: NSManagedObjectContext!
    var storedTokensEntityManager: StoredTokensEntityManager!
    // SAMPLE DATA
    
    let sampleToken1: StoredToken = StoredToken(
        id: "platform_1",
        accessToken: "access_token_1",
        refreshToken: "refresh_token_2",
        idToken: "id_token_1")
    
    let sampleToken2: StoredToken = StoredToken(
        id: "platform_2",
        accessToken: "access_token_2",
        refreshToken: "refresh_token_2",
        idToken: "id_token_2")
    let sampleToken3: StoredToken = StoredToken(
        id: "platform_3",
        accessToken: "access_token_3",
        refreshToken: "refresh_token_3",
        idToken: "id_token_3")
    
    var allTokens: [StoredToken] = []
    
    
    override func setUpWithError() throws {
        context = makeInMemoryManagedObjectContext()
        storedTokensEntityManager = StoredTokensEntityManager(context: context)
        allTokens = [sampleToken1, sampleToken2, sampleToken3 ]
    }
    
    override func tearDownWithError() throws {
        context.reset()
    }
    
    
    func testSavingTokenShouldSave(){
        XCTAssertNoThrow(storedTokensEntityManager.putStoredToken(token: sampleToken1))
    }
    
    func testGettingAllTokensShouldGet(){

        // Arrange: Put all tokens in coredata
        for token in allTokens {
            XCTAssertNoThrow(  storedTokensEntityManager.putStoredToken(token: token))
        }
        
        // Act: get tokens
        let retrievedTokens = storedTokensEntityManager.getAllStoredTokens()
        
        // Assert
        XCTAssertTrue(retrievedTokens.count == allTokens.count, "Retrieved token count should equal added token count: \(retrievedTokens.count)")
    }
    
    func testRetrieveTokenByPlatfromIdShouldGet(){
        // Arrange: store token 1
        XCTAssertNoThrow(storedTokensEntityManager.putStoredToken(token: sampleToken1))
        
        // Act: Retrive token
        let  retrievedToken1 = storedTokensEntityManager.getStoredToken(forPlatform: sampleToken1.id)
        
        // Assert: Validate all data
        XCTAssertTrue(retrievedToken1?.id == sampleToken1.id, "Id should be equal")
        XCTAssertTrue(retrievedToken1?.accessToken == sampleToken1.accessToken, "Access Token should be equal")
        XCTAssertTrue(retrievedToken1?.refreshToken == sampleToken1.refreshToken, "Refresh Token should be equal")
        XCTAssertTrue(retrievedToken1?.idToken == sampleToken1.idToken, "Id Token should be equal")
    }
    
    
    func testUpdatingExistingTokenShouldUpdate(){
        // Arrange: store sample token 1
        XCTAssertNoThrow(storedTokensEntityManager.putStoredToken(token: sampleToken1))
    
        // Update sampleToken1
        var updatedToken1 = sampleToken1.copyWith(
            accessToken: "updated_access_token_1",
            refreshToken: "updated_refresh_token_1",
            idToken: "updated_id_token_1")
        
        // Act: Store updated sample token 1
        XCTAssertNoThrow(storedTokensEntityManager.putStoredToken(token: updatedToken1))
        let retrievedToken1: StoredToken? = storedTokensEntityManager.getStoredToken(forPlatform: sampleToken1.id)

        
        // Assert: Validate all data
        XCTAssertTrue(retrievedToken1?.id == updatedToken1.id, "Assert retrieved id should be equal to updated id")
        XCTAssertTrue(retrievedToken1?.accessToken == updatedToken1.accessToken, "Assert retrieved access token should be equal to updated access token")
        XCTAssertTrue(retrievedToken1?.refreshToken == updatedToken1.refreshToken, "Assert retrieved refresh token should be equal to updated refresh token")
        XCTAssertTrue(retrievedToken1?.idToken == updatedToken1.idToken, "Assert retrieved id token should be equal to updated id token")
    }
    
    // DELETE
    func testDeleteTokenShouldDelete(){
        // Arrange: Put all tokens in coredata
        for token in allTokens {
            XCTAssertNoThrow(  storedTokensEntityManager.putStoredToken(token: token))
        }
        
        // Act: Delete token 1
        XCTAssertNoThrow(storedTokensEntityManager.deleteStoredToken(token: sampleToken1))
        
        // Assert:
        let retrievedTokens: [StoredToken] = storedTokensEntityManager.getAllStoredTokens()
        XCTAssertTrue(retrievedTokens.count == (allTokens.count-1), "Assert only 1 tokens was deleted")
        for token in retrievedTokens {
            XCTAssertFalse(token.id == sampleToken1.id, "Assert that sample token 1 no longer exists")
        }
    }
    
    
    func testDeleteTokenByPlatformIdShouldDelete(){
        // Arrange: Put all tokens in coredata
        for token in allTokens {
            XCTAssertNoThrow(  storedTokensEntityManager.putStoredToken(token: token))
        }
        
        // Act: Delete token 1
        XCTAssertNoThrow(storedTokensEntityManager.deleteStoredTokenById(forPlatform: sampleToken1.id))
        
        // Assert:
        let retrievedTokens: [StoredToken] = storedTokensEntityManager.getAllStoredTokens()
        
        print("retrieved tokens after deleting count: \(retrievedTokens.count)")
        XCTAssertTrue(retrievedTokens.count == (allTokens.count-1), "Assert only 1 tokens was deleted")
        for token in retrievedTokens {
            XCTAssertFalse(token.id == sampleToken1.id, "Assert that sample token 1 no longer exists")
        }
    }
    
    func testDeleteAllTokensShouldDelete(){
        // Arrange: Put all tokens in coredata
        for token in allTokens {
            XCTAssertNoThrow(storedTokensEntityManager.putStoredToken(token: token))
        }
        
        // Act: Delete token 1
        XCTAssertNoThrow(storedTokensEntityManager.deleteAllStoredTokens())
        
        // Assert:
        let retrievedTokens: [StoredToken] = storedTokensEntityManager.getAllStoredTokens()
        XCTAssertTrue(retrievedTokens.count == 0, "Assert all tokens were deleted")
    }
}
