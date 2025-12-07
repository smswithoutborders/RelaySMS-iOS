//
//  Vault.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 24/06/2024.
//

import CoreData
import CryptoKit
import CryptoSwift
import Fernet
import Foundation
import GRPC
import Logging
import SwiftUI
import SwobDoubleRatchet

struct Vault {
    
    public static var VAULT_LONG_LIVED_TOKEN =
    "COM.AFKANERD.RELAYSMS.VAULT_LONG_LIVED_TOKEN"
    public static var VAULT_PHONE_NUMBER =
    "COM.AFKANERD.RELAYSMS.VAULT_PHONE_NUMBER"
    public static var VAULT_DEVICE_ID = "COM.AFKANERD.RELAYSMS.VAULT_DEVICE_ID"
    public static var DEVICE_PUBLIC_KEY_KEYSTOREALIAS =
    "COM.AFKANERD.DEVICE_PUBLIC_KEY_KEYSTOREALIAS"
    
    @AppStorage(SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
    var shouldStorePlatformsOnDevice: Bool = false
    
    enum Exceptions: Error {
        case requestNotOK(status: GRPCStatus)
        case unauthenticatedLLT(status: GRPCStatus)
    }
    
    var channel: ClientConnection?
    var callOptions: CallOptions?
    var vaultEntityStub: Vault_V1_EntityNIOClient?
    
    init() {
        channel = GRPCHandler.getChannelVault()
        let logger = Logger(
            label: "gRPC", factory: StreamLogHandler.standardOutput(label:))
        callOptions = CallOptions.init(logger: logger)
        vaultEntityStub = Vault_V1_EntityNIOClient.init(
            channel: channel!,
            defaultCallOptions: callOptions!
        )
    }
    
    func createEntity(
        context: NSManagedObjectContext,
        phoneNumber: String,
        countryCode: String,
        password: String,
        ownershipResponse: String? = nil
    ) throws -> Vault_V1_CreateEntityResponse {
        
        print("[Vault]: Creating entity...")
        let clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair()
        let clientDeviceIDPubKey = clientDeviceIDPrivateKey.publicKey
            .rawRepresentation.base64EncodedString()
        
        let clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair()
        let clientPublishPubKey = clientPublishPrivateKey.publicKey
            .rawRepresentation.base64EncodedString()
        
        let entityCreationRequest: Vault_V1_CreateEntityRequest = .with {
            $0.countryCode = countryCode
            $0.phoneNumber = phoneNumber
            $0.password = password
            $0.clientPublishPubKey = clientPublishPubKey
            $0.clientDeviceIDPubKey = clientDeviceIDPubKey
            if ownershipResponse != nil && !ownershipResponse!.isEmpty {
                $0.ownershipProofResponse = ownershipResponse!
                
                UserDefaults.standard.set(
                    clientPublishPrivateKey.publicKey.rawRepresentation.bytes,
                    forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS
                )
            }
        }
        
        print("[Vault] Create entity request: \(entityCreationRequest)")
        
        let call = vaultEntityStub!.createEntity(entityCreationRequest)
        var response: Vault_V1_CreateEntityResponse
        
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("[Vault] Create entity response: \(entityCreationRequest)")
            
#if DEBUG
            print("[Vault] status code - raw value: \(status.code.rawValue)")
            print("[Vault] response: \(response)")
            print("[Vault] status code - description: \(status.code.description)")
            print("[Vault] status code - isOk: \(status.isOk)")
#endif
            
            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
            
            if !response.requiresOwnershipProof {
                UserDefaults.standard.set(
                    [UInt8](Data(base64Encoded: response.serverPublishPubKey)!),
                    forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY
                )
                
#if DEBUG
                print(
                    "[Vault] Peer publish: \(response.serverPublishPubKey) : \(response.serverPublishPubKey.count)"
                )
                print(
                    "[Vault] Peer pubkey: \(response.serverDeviceIDPubKey) : \(response.serverDeviceIDPubKey.count)"
                )
#endif
                try Vault.derivceStoreLLT(
                    lltEncoded: response.longLivedToken,
                    phoneNumber: phoneNumber,
                    clientDeviceIDPrivateKey: clientDeviceIDPrivateKey,
                    peerPublicKey: try Curve25519.KeyAgreement.PublicKey(
                        rawRepresentation: [UInt8](
                            Data(base64Encoded: response.serverDeviceIDPubKey)!)
                    )
                )
                
                try Vault.derivceStorePublishSharedSecret(
                    context: context,
                    clientPublishPrivateKey: clientPublishPrivateKey,
                    peerPublishPublicKey: try Curve25519.KeyAgreement.PublicKey(
                        rawRepresentation: [UInt8](
                            Data(base64Encoded: response.serverPublishPubKey)!))
                )
            }
        } catch {
            print("[Vault] Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    func authenticateEntity(
        context: NSManagedObjectContext,
        phoneNumber: String,
        password: String,
        ownershipResponse: String? = nil
    ) throws -> Vault_V1_AuthenticateEntityResponse {
        let clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair()
        let clientDeviceIDPubKey = clientDeviceIDPrivateKey.publicKey
            .rawRepresentation.base64EncodedString()
        
        let clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair()
        let clientPublishPubKey = clientPublishPrivateKey.publicKey
            .rawRepresentation.base64EncodedString()
        
        let authenticateEntityRequest: Vault_V1_AuthenticateEntityRequest =
            .with {
                $0.phoneNumber = phoneNumber
                $0.password = password
                $0.clientPublishPubKey = clientPublishPubKey
                $0.clientDeviceIDPubKey = clientDeviceIDPubKey
                if ownershipResponse != nil {
                    $0.ownershipProofResponse = ownershipResponse!
                    
                    UserDefaults.standard.set(
                        clientPublishPrivateKey.publicKey.rawRepresentation
                            .bytes,
                        forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS
                    )
                }
            }
        
        let call = vaultEntityStub!.authenticateEntity(
            authenticateEntityRequest)
        let response: Vault_V1_AuthenticateEntityResponse
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("[Vault] status code - raw value: \(status.code.rawValue)")
            print("[Vault] status code - description: \(status.code.description)")
            print("[Vault] status code - isOk: \(status.isOk)")
            
            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
            
            if !response.requiresOwnershipProof {
                print("[Vault] Here lies the Ad: \(response.serverPublishPubKey)\n")
                
                UserDefaults.standard.set(
                    [UInt8](Data(base64Encoded: response.serverPublishPubKey)!),
                    forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY
                )
                
                try Vault.derivceStoreLLT(
                    lltEncoded: response.longLivedToken,
                    phoneNumber: phoneNumber,
                    clientDeviceIDPrivateKey: clientDeviceIDPrivateKey,
                    peerPublicKey: try Curve25519.KeyAgreement.PublicKey(
                        rawRepresentation: [UInt8](
                            Data(base64Encoded: response.serverDeviceIDPubKey)!)
                    )
                )
                
                try Vault.derivceStorePublishSharedSecret(
                    context: context,
                    clientPublishPrivateKey: clientPublishPrivateKey,
                    peerPublishPublicKey: try Curve25519.KeyAgreement.PublicKey(
                        rawRepresentation: [UInt8](
                            Data(base64Encoded: response.serverPublishPubKey)!))
                )
            }
        } catch {
            print("[Vault] Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    func listStoredEntityToken(
        longLiveToken: String, migrateToDevice: Bool = false
    ) throws -> Vault_V1_ListEntityStoredTokensResponse {
        
        print("[Vault] Listing entity stored tokens...")
        
        let listEntityRequest: Vault_V1_ListEntityStoredTokensRequest = .with {
            $0.longLivedToken = longLiveToken
            $0.migrateToDevice = migrateToDevice
        }
        
        print("[Vault] List Entity StoredToken Request: \(listEntityRequest)")
        
        let call = vaultEntityStub!.listEntityStoredTokens(listEntityRequest)
        let response: Vault_V1_ListEntityStoredTokensResponse
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("[Vault] List Entity StoredToken Response: \(response)")
            
            print("[Vault] status code - raw value: \(status.code.rawValue)")
            print("[Vault] status code - description: \(status.code.description)")
            print("[Vault] status code - isOk: \(status.isOk)")
            
            if !status.isOk {
                if status.code.rawValue == 16 {
                    throw Exceptions.unauthenticatedLLT(status: status)
                }
                throw Exceptions.requestNotOK(status: status)
            }
        } catch {
            print("[Vault] Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    func recoverPassword(
        context: NSManagedObjectContext,
        phoneNumber: String,
        newPassword: String,
        ownershipResponse: String? = nil
    ) throws -> Vault_V1_ResetPasswordResponse {
        print("[Vault] Recovering password...")
        let clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair()
        let clientDeviceIDPubKey = clientDeviceIDPrivateKey.publicKey
            .rawRepresentation.base64EncodedString()
        
        let clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair()
        let clientPublishPubKey = clientPublishPrivateKey.publicKey
            .rawRepresentation.base64EncodedString()
        
        let recoverPasswordRequest: Vault_V1_ResetPasswordRequest = .with {
            $0.phoneNumber = phoneNumber
            $0.newPassword = newPassword
            $0.clientPublishPubKey = clientPublishPubKey
            $0.clientDeviceIDPubKey = clientDeviceIDPubKey
            if ownershipResponse != nil {
                $0.ownershipProofResponse = ownershipResponse!
                
                UserDefaults.standard.set(
                    clientPublishPrivateKey.publicKey.rawRepresentation.bytes,
                    forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS
                )
            }
        }
        
        print("[Vault] Recovering password request: \(recoverPasswordRequest)")
        
        let call = vaultEntityStub!.resetPassword(recoverPasswordRequest)
        let response: Vault_V1_ResetPasswordResponse
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("[Vault] Recovering password response: \(response)")
            
            print("[Vault] status code - raw value: \(status.code.rawValue)")
            print("[Vault] status code - description: \(status.code.description)")
            print("[Vault] status code - isOk: \(status.isOk)")
            
            if !status.isOk {
                throw Exceptions.requestNotOK(status: status)
            }
            
            if !response.requiresOwnershipProof {
                UserDefaults.standard.set(
                    [UInt8](Data(base64Encoded: response.serverPublishPubKey)!),
                    forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY
                )
                
                try Vault.derivceStoreLLT(
                    lltEncoded: response.longLivedToken,
                    phoneNumber: phoneNumber,
                    clientDeviceIDPrivateKey: clientDeviceIDPrivateKey,
                    peerPublicKey: try Curve25519.KeyAgreement.PublicKey(
                        rawRepresentation: [UInt8](
                            Data(base64Encoded: response.serverDeviceIDPubKey)!)
                    )
                )
                
                try Vault.derivceStorePublishSharedSecret(
                    context: context,
                    clientPublishPrivateKey: clientPublishPrivateKey,
                    peerPublishPublicKey: try Curve25519.KeyAgreement.PublicKey(
                        rawRepresentation: [UInt8](
                            Data(base64Encoded: response.serverPublishPubKey)!))
                )
            }
        } catch {
            print("[Vault] Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    private func deleteEntity(
        context: NSManagedObjectContext, longLiveToken: String
    ) throws -> Vault_V1_DeleteEntityResponse {
        let deleteEntityRequest: Vault_V1_DeleteEntityRequest = .with {
            $0.longLivedToken = longLiveToken
        }
        
        let call = vaultEntityStub!.deleteEntity(deleteEntityRequest)
        let response: Vault_V1_DeleteEntityResponse
        do {
            response = try call.response.wait()
            let status = try call.status.wait()
            
            print("[Vault] status code - raw value: \(status.code.rawValue)")
            print("[Vault] status code - description: \(status.code.description)")
            print("[Vault] status code - isOk: \(status.isOk)")
            
            if !status.isOk {
                if status.code.rawValue == 16 {
                    throw Exceptions.unauthenticatedLLT(status: status)
                }
                print(status)
                throw Exceptions.requestNotOK(status: status)
            }
            
            try Vault.resetKeystore(context: context)
            
        } catch {
            print("[Vault] Some error came back: \(error)")
            throw error
        }
        return response
    }
    
    public static func completeDeleteEntity(
        context: NSManagedObjectContext,
        longLiveToken: String,
        storedTokenEntities: FetchedResults<StoredPlatformsEntity>,
        platforms: FetchedResults<PlatformsEntity>
    ) throws {
        let vault = Vault()
        
        do {
            let publisher = Publisher()
            for storedTokenEntity in storedTokenEntities {
                print("[Vault] [+] Revoking \(storedTokenEntity.name!)")
                try publisher.revokePlatform(
                    llt: longLiveToken,
                    platform: storedTokenEntity.name!,
                    account: storedTokenEntity.account!,
                    protocolType: Publisher.getProtocolTypeForPlatform(
                        storedPlatform: storedTokenEntity,
                        platforms: platforms
                    )
                )
            }
            try vault.deleteEntity(
                context: context, longLiveToken: longLiveToken)
        } catch {
            throw error
        }
    }
    
    public static func getPublisherSharedSecret() throws -> [UInt8]? {
        do {
            let sk = try CSecurity.findInKeyChain(
                keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
            return [UInt8](Data(sk))
        } catch CSecurity.Exceptions.FailedToFetchStoredItem {
            return nil
        } catch {
            throw error
        }
    }
    
    public static func getLongLivedToken() throws -> String {
        do {
            let llt = try CSecurity.findInKeyChain(
                keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
            return String(data: llt, encoding: .utf8)!
        } catch CSecurity.Exceptions.FailedToFetchStoredItem {
            return ""
        } catch {
            throw error
        }
    }
    
    public static func resetKeystore(context: NSManagedObjectContext) throws {
        CSecurity.deletePasswordFromKeychain(
            keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
        CSecurity.deletePasswordFromKeychain(
            keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
        
        try resetStates(context: context)
        
        let onboardingCompleted = UserDefaults.standard.bool(
            forKey: OnboardingView.ONBOARDING_COMPLETED)
        let defaultGatewayClient =
        UserDefaults.standard.string(
            forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        ?? ""
        
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        
        UserDefaults.standard.set(
            onboardingCompleted, forKey: OnboardingView.ONBOARDING_COMPLETED)
        if !defaultGatewayClient.isEmpty {
            UserDefaults.standard.set(
                defaultGatewayClient,
                forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        }
        print("[Vault] [important] keystore reset done...")
    }
    
    public static func resetStates(context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "StatesEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            throw error
        }
    }
    
    static func deriveUniqueKey(platformName: String, accountIdentifier: String)
    -> String
    {
        return SHA256.hash(data: Data((platformName + accountIdentifier).utf8))
            .description
    }
    
    static func saveStoredPlatform(
        context: NSManagedObjectContext,
        id: String,
        name: String,
        account: String,
        isStoredOnDevice: Bool,
        accessToken: String?,
        refreshToken: String?
    ) throws {

        guard !id.isEmpty else {
            print("Error: StoredPlatform ID cannot be empty for upsert operation.")
            return
        }

        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id)

        do {
            let existingEntity = try context.fetch(fetchRequest).first
            let entityToSave: StoredPlatformsEntity

            if let existing = existingEntity {
                print("Updating existing stored platform with ID: \(id)")
                entityToSave = existing
            } else {
                print("Creating new stored platform with ID: \(id)")
                entityToSave = StoredPlatformsEntity(context: context)
                entityToSave.id = id
            }

            entityToSave.name = name
            entityToSave.account = account
            entityToSave.is_stored_on_device = isStoredOnDevice
            if let icomingAccessToken = accessToken, !icomingAccessToken.isEmpty {
                entityToSave.access_token = accessToken
            }
            if let icomingRefreshToken = refreshToken, !icomingRefreshToken.isEmpty {
                entityToSave.refresh_token = refreshToken
            }

            DispatchQueue.main.async {
                do {
                    try context.save()
                    print("Successfully saved stored platform: \(name) (ID: \(id))")
                } catch {
                    print(error)
                }
            }
        

        } catch {
            print("Error saving stored platform (ID: \(id)): \(error)")
            throw error
        }

    }
    
    func refreshStoredTokens(
        llt: String,
        context: NSManagedObjectContext,
        storedTokenEntities: FetchedResults<StoredPlatformsEntity>?
    ) throws -> [Vault_V1_Token] {
        print("[Vault] Refreshing stored platforms...")
        let vault = Vault()
        var missingTokens: [Vault_V1_Token] = []
        do {
            let addedPlatforms = try vault.listStoredEntityToken(
                longLiveToken: llt, migrateToDevice: shouldStorePlatformsOnDevice)
            
            for platform in addedPlatforms.storedTokens {
                let platformId = Vault.deriveUniqueKey(
                    platformName: platform.platform,
                    accountIdentifier: platform.accountIdentifier
                )                
                do {
                    try Vault.saveStoredPlatform(
                         context: context,
                         id: platformId,
                         name: platform.platform,
                         account: platform.accountIdentifier,
                         isStoredOnDevice: platform.isStoredOnDevice,
                         accessToken: platform.accountTokens["access_token"] ?? "",
                         refreshToken: platform.accountTokens["refresh_token"] ?? ""
                   )
                } catch {
                    print("[Vault] Failed to store platform \(platform.accountIdentifier): \(error)")
                }
            }

        } catch Exceptions.unauthenticatedLLT(let status) {
            print("[Vault] Should delete invalid llt: \(String(describing: status.message))")
            try Vault.resetKeystore(context: context)
            try DataController.resetDatabase(context: context)
        } catch {
            print("[Vault] Error fetching stored tokens: \(error)")
            throw error
        }
        return missingTokens
    }
    

    

    static func clear(context: NSManagedObjectContext) throws {
        print("[Vault] Clearing platforms...")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "StoredPlatformsEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        // Important: Set result type to Object IDs
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: objectIDs
                ]
                // Merge changes so the in-memory context is updated
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }

            try context.save()
        } catch {
            print("[Vault] Error clearing PlatformsEntity: \(error)")
            context.rollback()
            throw error
        }
    }

    func validateLLT(llt: String, context: NSManagedObjectContext) throws
        -> Bool
    {
        let vault = Vault()
        do {
            let storedTokens = try vault.listStoredEntityToken( longLiveToken: llt)
        } catch Exceptions.unauthenticatedLLT(let status) {
            print("[Vault] Should delete invalid llt: \(String(describing: status.message))")
            return false
        } catch {
            print("[Vault] Error fetching stored tokens: \(error)")
            throw error
        }
        return true
    }

    private static func deriveDeviceID(
        derivedKey: [UInt8], phoneNumber: String, publicKey: [UInt8]
    ) throws -> [UInt8] {
        print("[Vault] DID key: \(derivedKey.toBase64())")
        print("[Vault] DID phoneNumber: \(phoneNumber)")
        print("[Vault] DID publicKey: \(publicKey.toBase64())")
        let combinedData = phoneNumber.bytes.withUnsafeBytes {
            return Array($0) + publicKey
        }
        let deviceId = try HMAC(key: derivedKey, variant: .sha2(.sha256))
            .authenticate(combinedData)
        print("[Vault] DID id: \(deviceId.toBase64())")
        return deviceId
    }

    private static func derivceStoreLLT(
        lltEncoded: String,
        phoneNumber: String,
        clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey,
        peerPublicKey: Curve25519.KeyAgreement.PublicKey
    ) throws -> String {
        let sharedKey = try SecurityCurve25519.calculateSharedSecret(
            privateKey: clientDeviceIDPrivateKey,
            publicKey: peerPublicKey)

        let deviceIdSharedKey = sharedKey.withUnsafeBytes { return Array($0) }

        let fernetToken = try Fernet(key: Data(deviceIdSharedKey))
        let decodedOutput = try fernetToken.decode(
            Data(base64Encoded: lltEncoded)!)

        let deviceID = try Vault.deriveDeviceID(
            derivedKey: deviceIdSharedKey,
            phoneNumber: phoneNumber,
            publicKey: clientDeviceIDPrivateKey.publicKey.rawRepresentation
                .bytes
        )

        let llt = String(data: decodedOutput.data, encoding: .utf8)!

        UserDefaults.standard.set(deviceID, forKey: Vault.VAULT_DEVICE_ID)

        CSecurity.deletePasswordFromKeychain(
            keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)

        try CSecurity.storeInKeyChain(
            data: llt.data(using: .utf8)!,
            keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN
        )

        return llt
    }

    private static func derivceStorePublishSharedSecret(
        context: NSManagedObjectContext,
        clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey,
        peerPublishPublicKey: Curve25519.KeyAgreement.PublicKey
    ) throws {
        let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
            privateKey: clientPublishPrivateKey,
            publicKey: peerPublishPublicKey
        ).withUnsafeBytes { return Array($0) }

        CSecurity.deletePasswordFromKeychain(
            keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)

        try CSecurity.storeInKeyChain(
            data: Data(publishingSharedKey),
            keystoreAlias: Publisher.PUBLISHER_SHARED_KEY
        )

        try Vault.resetStates(context: context)
    }
    
    
}
