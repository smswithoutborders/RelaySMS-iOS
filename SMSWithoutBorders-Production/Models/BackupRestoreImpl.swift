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
    }
    static func backup(
        into context: ModelContext,
        recoveryKey: Data?
    ) throws -> (Data, Data) {
        let allData = try Keystore.getAllKeychainItems()
        
        var compiledData: [String:String] = [:]
        for (tag, localKeypair) in allData {
            compiledData[tag] = localKeypair.base64EncodedString()
        }
        
        let encoder = JSONEncoder()
        let jsonEncoded = try encoder.encode(allData)
        
        let backupData = try BackupRestore.v1BackupEncrypt(
            data: jsonEncoded,
            recoveryKey: recoveryKey
        )
        let serialized = try backupData.serialize()
        
        guard let rk = backupData.getRecoveryKey() else {
            throw BackupRestoreImplError.failedToGetBackupRecoveryKey
        }
        
        return (serialized, rk)
    }
}
