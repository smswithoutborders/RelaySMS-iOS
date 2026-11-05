//
//  BackedUpView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftUI

struct BackedUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage("backupFilenamePrefix") private var backupFilename: String?
    @AppStorage("lastBackupDate") private var lastBackupDate: Date?
    
    @State private var lastBackup: String = ""

    @State private var viewRecoveryKeySelected: Bool = false
    @State private var deleteBackupSelected: Bool = false
    @State private var showDeleteAlert: Bool = false

    @State private var viewModel = BackupRestoreViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                    } header: {
                        Text(String(localized: "Backups are end-to-end encrypted and stored on your device."))
                            .font(.callout)
                    }
                    
                    Section {
                        Button(action: {
                            Task {
                                await viewModel.backup(
                                    nil,
                                    into: modelContext.container
                                )
                            }
                        }) {
                            HStack {
                                Label(String(localized: "Back Up Now"), systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            }
                        }
                    } footer: {
                        if viewModel.backingUp {
                            Text(String(localized: "backing up..."))
                        } else {
                            Text(String(localized: "click to update backup"))
                        }
                    }
                    
                    Section {
                        HStack {
                            Label(String(localized: "Last Backup"), systemImage: "")
                            Spacer()
                            if lastBackupDate != nil {
                                Text(formattedDateString(from: lastBackupDate ?? Date()))
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        
                        HStack {
                            Label(String(localized: "View Recovery Key"), systemImage: "")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            
                        }
                        .onTapGesture {
                            viewRecoveryKeySelected = true
                        }
                    }
                    
                    Section {
                        Button(action: {
                        }) {
                            Text(String(localized: "Delete Backup"))
                                .foregroundStyle(.red)
                        }
                    } footer: {
                        Text(String(localized: "To restore a backup, install a new copy of RelaySMS. Open the app, tap \"Restore backup\"."))
                    }
                }
                .alert(String(localized: "Are you sure?"), isPresented: $showDeleteAlert) {
                    Button(String(localized: "Delete"), role: .destructive) {
                        if backupFilename != nil {
                            viewModel.deleteBackup(named: backupFilename!)
                            backupFilename = nil
                            lastBackupDate = nil
                            dismiss()
                        }
                    }
                    Button(String(localized: "Cancel"), role: .cancel) { }
                } message: {
                    Text(String(localized: "This action cannot be undone, but you can create new backups later."))
                }

            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(String(localized: "On-Device Backups"))
            .navigationDestination(isPresented: $viewRecoveryKeySelected) {
                RecoveryKeyView(
                    copyToClipboardCallback: {
                        UIPasteboard.general.string = viewModel.viewRecoveryKey()
                    },
                    saveToPasswordManagerCallback: {},
                    saveManuallyCallback: nil,
                )
            }
        }
    }
    
    func formattedDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        
        // 1. Get the localizable ordinal day (e.g., "5th", "1er", etc.)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        let ordinalDay = numberFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        
        // 2. Get the weekday name and year
        let formatter = DateFormatter()
        formatter.locale = Locale.current // Respects device language/region
        
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: date)
        
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: date)
        
        // 3. Combine them cleanly
        return "\(weekday), \(ordinalDay) \(year)"
    }
}

#Preview("BackedUpView") {
    BackedUpView()
}
