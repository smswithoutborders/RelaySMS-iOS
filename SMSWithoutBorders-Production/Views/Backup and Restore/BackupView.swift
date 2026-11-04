//
//  BackupView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftUI

struct BackupInfoView: View {
    var onBackupClickedCallback: () -> Void
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Image(systemName: "iphone.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.primary)
                    .padding()
                
                Text(String(localized: "On-Device Backup"))
                    .font(.title)
                    .padding()
                
                Text(String(localized: "Back up your messages and stored accounts to a folder on your device. Your backup is end-to-end encrypted and can be restored by installing a new copy of RelaySMS and choosing \"Restore Backup\"."))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
            }
            .padding()
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(String(localized: "End-to-end encrypted"))
                }
                HStack {
                    Image(systemName: "checkmark.square")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(String(localized: "Saved on your device"))
                }
                HStack {
                    Image(systemName: "trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(String(localized: "Turn off backups anytime"))
                }
            }
            .padding()
            
            Spacer()
            
            VStack {
                Button(action: onBackupClickedCallback ) {
                    Text(String(localized: "Continue"))
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 10)
            }
            .padding()
        }
        .padding()
    }
}

struct ChooseBackupFolderView: View {
    var onFolderClickedCallback: () -> Void
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "folder")
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.bold)
                    .frame(width: 25, height: 25)
                    .padding()
                
                Text(String(localized: "Choose a Folder"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(String(localized: "Choose a folder in your device's storage wher your backup will be stored."))
                    .padding()

            }
            .padding()
            
            VStack {
                Button(action: onFolderClickedCallback) {
                    Text("Choose Folder")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 10)

                Button(action: {}) {
                    Text("Cancel")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 10)
            }
        }
        .padding()
    }
}

struct RecoveryKeyInfoView: View {
    var onViewKeyClicked: () -> Void
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "key.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.primary)
                    .padding()
                
                Text(String(localized: "Recovery Key"))
                    .font(.title)
                    .padding()
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(systemName: "number.sign")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(String(localized: "Your recovery key is a 64-character code that you will need to restore your backup."))
                }
                .padding()
                
                HStack(alignment: .top) {
                    Image(systemName: "lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(String(localized: "Store your recovery key somewhere safe like a password manager, and don't share it with anyone."))
                }
                .padding()
                
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(String(localized: "If you lose it, you won't be able to recover your messages."))
                }
                .padding()
            }
            .padding()
            
            Spacer()
            
            VStack {
                Button(action: onViewKeyClicked ) {
                    Text(String(localized: "View Recovery Key"))
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 10)
            }
            .padding()
        }
        .padding()
    }
}

struct RecoveryKeyView: View {
    var copyToClipboardCallback: () -> Void
    var saveToPasswordManagerCallback: () -> Void
    var saveManuallyCallback: () -> Void
    
    #if DEBUG
    @State private var recoveryKey: String = "1234567890123456789012345678901234567890123456789012345678901234"
    #else
    @State private var recoveryKey: String = ""
    #endif

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Image(systemName: "lock.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.primary)
                    .padding()
                
                Text(String(localized: "Save Your Recovery Key"))
                    .font(.title)
                    .padding()
                
                Text(String(localized: "This key is required to recover your account and data. Store this key somewhere safe. If you lose it, you won't be able to recover your account."))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
            }
            .padding()
            

            VStack {
                GroupBox {
                    VStack {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(Array(chunkByFours(recoveryKey).enumerated()), id: \.offset) { index, chunk in
                                    VStack(spacing: 2) {
                                        Text(chunk)
                                            .font(.system(.body, design: .monospaced))
                                            .padding(6)
                                            .frame(maxWidth: .infinity)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 155)
                    }
                }
                
                Button(action: copyToClipboardCallback) {
                    Text(String(localized: "Copy to clipboard"))
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.bordered)
                .padding()
            }
            Spacer()
            
            VStack {
                Button(action: saveToPasswordManagerCallback ) {
                    Text(String(localized: "Save to Password Manager"))
                        .fontWeight(.bold)
                        .padding(.all, 10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: saveToPasswordManagerCallback ) {
                    Text(String(localized: "Continue"))
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }
    
    func chunkByFours(_ input: String) -> [String] {
        var groups: [String] = []
        var currentIndex = input.startIndex
        let chunkSize = 4
        
        while currentIndex < input.endIndex {
            let nextIndex = input.index(currentIndex, offsetBy: chunkSize, limitedBy: input.endIndex) ?? input.endIndex
            let chunk = String(input[currentIndex..<nextIndex])
            groups.append(chunk)
            currentIndex = nextIndex
        }
        
        return groups
    }
}

struct BackupView: View {
    var body: some View {
        
    }
}

#Preview("BackupInfoView") {
    BackupInfoView(onBackupClickedCallback: {})
}

#Preview("ChooseBackupFolderView") {
    ChooseBackupFolderView(onFolderClickedCallback: {})
}

#Preview("RecoveryKeyInfoView") {
    RecoveryKeyInfoView(onViewKeyClicked: {})
}

#Preview("RecoveryKeyView") {
    RecoveryKeyView(
        copyToClipboardCallback: {},
        saveToPasswordManagerCallback: {},
        saveManuallyCallback: {}
    )
}
