//
//  BackupRestoreViewModel.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import Observation
import Foundation
import SwiftData

@Observable
class BackupRestoreViewModel {
    private let folderStore = PersistedFileStore(key: "backupFolderBookmark")
    
    private(set) var statusMessage: String = ""
    private(set) var backingUp: Bool = false
    
    var recoveryKey: String = ""
    
    private var filename: String {
        let template = String(localized: "RelaySMS-Backup-")
        var raw = UserDefaults.standard.string(forKey: "backupFilenamePrefix")
        
        if raw != nil {
            // Strip path separators so a user can't write outside the chosen folder
            raw = raw!
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if raw?.isEmpty == true {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                raw = template + formatter.string(from: .now)
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            raw = template + formatter.string(from: .now)
        }
        
        return raw!
    }
    

    let serviceName = "com.afkanerd.smswithoutborders.relaysms"
    let account = "backup"
    
    func backup(_ url: URL?, into container: ModelContainer) async -> (String?, Date?)? {
        backingUp = true
        defer {
            backingUp = false
        }
        do {
            var srk: Data? = nil
            if url != nil {
                try folderStore.persist(url!)
            }
            else {
                srk = Data(viewRecoveryKey().utf8)
            }
            
            let context = ModelContext(container)
            let (data, rk) = try BackupRestoreImpl.backup(into: context, recoveryKey: srk)

            let name = filename
            let _ = try folderStore.withAccess { folder in
                try data.write(to: folder.appending(path: name), options: .atomic)
                return folder
            }

            if url != nil {
                recoveryKey = String(decoding: rk, as: UTF8.self)
                try Keystore.savePassword(recoveryKey, service: serviceName, account: account)
            }
            
            return (name, Date())
        } catch PersistedFileStore.StoreError.noBookmark {
            statusMessage = String(localized: "Choose a backup folder first.")
        } catch {
            statusMessage = String(localized: "Failed to write: \(error.localizedDescription)")
        }
        return (nil, nil)
    }
    
    func viewRecoveryKey() -> String {
        do {
            let rk = try Keystore.retrievePassword(service: serviceName, account: account)
            return rk
        } catch {
            statusMessage = String(localized: "Failed to fetch recovery key: \(error.localizedDescription)")
        }
        return ""
    }
    
    func deleteBackup(named name: String) {
        do {
            try folderStore.withAccess { folder in
                let fileURL = folder.appending(path: name)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
            folderStore.clear()
            try Keystore.deletePassword(service: serviceName, account: account)
        } catch PersistedFileStore.StoreError.noBookmark {
            statusMessage = String(localized: "Choose a backup folder first.")
        } catch {
            statusMessage = String(localized: "Failed to delete: \(error.localizedDescription)")
        }
    }
}
