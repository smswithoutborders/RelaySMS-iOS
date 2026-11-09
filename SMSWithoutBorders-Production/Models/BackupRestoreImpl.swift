//
//  BackupRestoreImpl.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftData
import Foundation

class BackupRestoreImpl {
    enum BackupRestoreImplError: Error {
        case failedToGetBackupRecoveryKey
        case failedToDeserializeData
    }
    
    struct BackupData: Encodable, Decodable {
        let keys: [String: Data]
        var tokens: [Tokens]
        var supportedPlatforms: [SupportedPlatforms]
        var payloads: [Payloads]
        var gatewayClients: [GatewayClients]
    }
    
    static func backup(
        into context: ModelContext,
        recoveryKey: Data?
    ) throws -> (Data, Data) {
        let keys = try Keystore.getAllKeychainItems()
        let tokens = try Tokens.getAll(context: context)
        let supportedPlatforms = try SupportedPlatforms.getAll(context: context)
        let payloads = try Payloads.getAll(context: context)
        let gatewayClients = try GatewayClients.getAll(context: context)
        
        let backupData = BackupData(
            keys: keys,
            tokens: tokens,
            supportedPlatforms: supportedPlatforms,
            payloads: payloads,
            gatewayClients: gatewayClients
        )
        
        let encoder = JSONEncoder()
        let jsonEncoded = try encoder.encode(backupData)
        
        let encryptedData = try BackupRestore.v1BackupEncrypt(
            data: jsonEncoded,
            recoveryKey: recoveryKey
        )
        let serialized = try encryptedData.serialize()
        
        guard let rk = encryptedData.getRecoveryKey() else {
            throw BackupRestoreImplError.failedToGetBackupRecoveryKey
        }
        
        return (serialized, rk)
    }
    
    static func recover(context: ModelContext, data: Data, recoveryKey: Data) throws{
        let backupRestore = try BackupRestore.deserialize(data: data, recoveryKey: recoveryKey)
        let clearText = try backupRestore.v1RestoreDecrypt()
        
        let decoder = JSONDecoder()
        let backupData = try decoder.decode(BackupData.self, from: clearText)
        
        try Keystore.importKeys(backupData.keys)
        try Tokens.insertAll(context: context, tokens: backupData.tokens)
        try SupportedPlatforms.insertAll(context: context, supportedPlatforms: backupData.supportedPlatforms)
        try Payloads.insertAll(context: context, payloads: backupData.payloads)
        try GatewayClients.insertAll(into: context, gatewayClients: backupData.gatewayClients)
    }
}
