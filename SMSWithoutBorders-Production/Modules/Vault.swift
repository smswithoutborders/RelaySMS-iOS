//
//  Vault.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 24/06/2024.
//

import Foundation
import GRPC
import Logging
import CoreData


class Vault {
    
    public static var VAULT_LONG_LIVED_TOKEN = "COM.AFKANERD.RELAYSMS.VAULT_LONG_LIVED_TOKEN"
    
    class LocalStoredTokens : Identifiable {
        var name: String
        var account: String
        
        init(name: String, account: String) {
            self.name = name
            self.account = account
        }
    }

    enum Exceptions: Error {
        case requestNotOK(status: GRPCStatus)
        case unauthenticatedLLT(status: GRPCStatus)
    }
    
    var channel: ClientConnection?
    var callOptions: CallOptions?
    var vaultEntityStub: Vault_V1_EntityNIOClient?

    init() {
        channel = GRPCHandler.getChannelVault()
        let logger = Logger(label: "gRPC", factory: StreamLogHandler.standardOutput(label:))
        callOptions = CallOptions.init(logger: logger)
        vaultEntityStub = Vault_V1_EntityNIOClient.init(channel: channel!,
                                                            defaultCallOptions: callOptions!)
    }
    
    func createEntity(phoneNumber: String,
                       countryCode: String, 
                       password: String, 
                       clientPublishPubKey: String,
                       clientDeviceIdPubKey: String,
                       ownershipResponse: String? = nil) throws -> Vault_V1_CreateEntityResponse {
        let entityCreationRequest: Vault_V1_CreateEntityRequest = .with {
            $0.countryCode = countryCode
            $0.phoneNumber = phoneNumber
            $0.password = password
            $0.clientPublishPubKey = clientPublishPubKey
            $0.clientDeviceIDPubKey = clientDeviceIdPubKey
            if(ownershipResponse != nil && !ownershipResponse!.isEmpty) {
                $0.ownershipProofResponse = ownershipResponse!
            }
        }
        
        let call = vaultEntityStub!.createEntity(entityCreationRequest)
        let response: Vault_V1_CreateEntityResponse

        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("status code - raw value: \(status.code.rawValue)")
            print("status code - description: \(status.code.description)")
            print("status code - isOk: \(status.isOk)")
            
            if(!status.isOk) {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    func authenticateEntity(phoneNumber: String,
                            password: String,
                            clientPublishPubKey: String,
                             clientDeviceIDPubKey: String,
                             ownershipResponse: String? = nil)
    throws -> Vault_V1_AuthenticateEntityResponse {
        let authenticateEntityRequest: Vault_V1_AuthenticateEntityRequest = .with {
            $0.phoneNumber = phoneNumber
            $0.password = password
            $0.clientPublishPubKey = clientPublishPubKey
            $0.clientDeviceIDPubKey = clientDeviceIDPubKey
            if(ownershipResponse != nil) {
                $0.ownershipProofResponse = ownershipResponse!
            }
        }
        
        let call = vaultEntityStub!.authenticateEntity(authenticateEntityRequest)
        let response: Vault_V1_AuthenticateEntityResponse
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("status code - raw value: \(status.code.rawValue)")
            print("status code - description: \(status.code.description)")
            print("status code - isOk: \(status.isOk)")
            
            if(!status.isOk) {
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    
    func listStoredEntityToken(longLiveToken: String) throws -> Vault_V1_ListEntityStoredTokensResponse {
        let listEntityRequest: Vault_V1_ListEntityStoredTokensRequest = .with {
            $0.longLivedToken = longLiveToken
        }
        
        let call = vaultEntityStub!.listEntityStoredTokens(listEntityRequest)
        let response: Vault_V1_ListEntityStoredTokensResponse
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("status code - raw value: \(status.code.rawValue)")
            print("status code - description: \(status.code.description)")
            print("status code - isOk: \(status.isOk)")
            
            if(!status.isOk) {
                if status.code.rawValue == 16 {
                    throw Exceptions.unauthenticatedLLT(status: status)
                }
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    public static func getLongLivedToken() throws -> String {
        let llt = try CSecurity.findInKeyChain(keystoreAlias:
                                                Vault.VAULT_LONG_LIVED_TOKEN)
        return String(data: llt, encoding: .utf8)!
    }
    
    public static func resetKeystore() {
        CSecurity.deletePasswordFromKeychain(keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
        CSecurity.deletePasswordFromKeychain(keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
        print("[important] keystore reset done...")
    }
    
    public static func parseErrorMessage(message: String?) -> (String?, String)? {
        guard let message = message else {
                return nil
            }
            
            // Regular expression to capture the JSON-like field and error message
            let jsonRegex = try! NSRegularExpression(pattern: "\\{\\s*'([^']+)'\\s*:\\s*'([^']+)'\\s*\\}")
            
            // Regular expression to capture the phone number existence message
            let phoneRegex = try! NSRegularExpression(pattern: "Entity with phone number `([^`]+)` already exists.")
            
            if let match = jsonRegex.firstMatch(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count)) {
                let fieldRange = Range(match.range(at: 1), in: message)!
                let errorRange = Range(match.range(at: 2), in: message)!
                
                let field = String(message[fieldRange])
                let errorMessage = String(message[errorRange])
                
                return (field, errorMessage)
            } else if let match = phoneRegex.firstMatch(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count)) {
                let phoneNumberRange = Range(match.range(at: 1), in: message)!
                
                let phoneNumber = String(message[phoneNumberRange])
                let errorMessage = "Entity with phone number \(phoneNumber) already exists."
                
                return (nil, errorMessage)
            }
            
            return nil
    }
    
    func refreshStoredTokens(llt: String, context: NSManagedObjectContext) {
        print("Refreshing stored platforms...")
        let vault = Vault()
        do {
            let storedTokens = try vault.listStoredEntityToken(longLiveToken: llt)
            for storedToken in storedTokens.storedTokens {
                let storedPlatformEntity = StoredPlatformsEntity(context: context)
                storedPlatformEntity.name = storedToken.platform
                storedPlatformEntity.account = storedToken.accountIdentifier
                do {
                    try context.save()
                } catch {
                    print("Failed to stored platform: \(error)")
                }
            }
        } catch Exceptions.unauthenticatedLLT(let status){
            print("Should delete invalid llt: \(status.message)")
            Vault.resetKeystore()
        } catch {
            print("Error fetching stored tokens: \(error)")
        }
    }
}
