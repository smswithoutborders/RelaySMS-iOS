//
//  BackedUpView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftUI

struct BackedUpView: View {
    @State private var lastBackup: String = ""
    @State private var viewRecoveryKeySelected: Bool = false
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
                        HStack {
                            Label(String(localized: "Back Up Now"), systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                    }
                    
                    Section {
                        HStack {
                            Label(String(localized: "Last Backup"), systemImage: "")
                            Spacer()
                            Text(lastBackup)
                                .foregroundColor(.secondary)
                        }
                        
                        
                        Picker(
                            selection: $viewRecoveryKeySelected,
                            label: Label(
                                String(localized: "View Recovery Key"),
                                systemImage: ""
                            )) {
                        }
                        .pickerStyle(.navigationLink)
                    }
                    
                    Section {
                        HStack {
                            Label(String(localized: "Turn Off & Delete Backup"), systemImage: "")
                                .foregroundStyle(.red)
                        }
                    } footer: {
                        Text(String(localized: "To restore a backup, install a new copy of RelaySMS. Open the app, tap \"Restore backup\"."))
                    }

                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(String(localized: "On-Device Backups"))
        }
    }
}

#Preview {
    BackedUpView()
}
