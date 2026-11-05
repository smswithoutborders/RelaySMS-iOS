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
    private(set) var statusMessage: String = ""
    var recoveryKey: String = ""
    
    private var filename: String = String(localized: "RelaySMS-Backup-")

    func backup(
        urls: [URL],
        into container: ModelContainer
    ) async {
        guard let selectedFolderURL = urls.first else { return }
        
        guard selectedFolderURL.startAccessingSecurityScopedResource() else {
            statusMessage = String(localized: "Permission denied to access this directory.")
            return
        }
        
        defer {
            selectedFolderURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            var dateFormatter: DateFormatter {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
            
            filename += dateFormatter.string(from: Date.now)
            let fileURL = selectedFolderURL.appending(path: filename)
            
            let context = ModelContext(container)
            let (data, rk) = try BackupRestoreImpl.backup(into: context)
            
            // Write the data atomatically
            try data.write(to: fileURL, options: .atomic)
            
            recoveryKey = String(decoding: rk, as: UTF8.self)
        } catch {
            statusMessage = String(localized: "Failed to write: \(error.localizedDescription)")
        }
    }
}
