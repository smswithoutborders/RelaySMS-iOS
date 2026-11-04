//
//  BackupView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

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
    var onCancelCallback: () -> Void
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

                Button(action: onCancelCallback) {
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

    @State var recoveryKey: String

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
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
                            .padding(.all, 10)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
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


enum BackupPage: String, Identifiable, CaseIterable {
    case info
    case recoveryKeyInfo
    case recoveryKeyView

    var id: String { rawValue }

    static var first: Self = .info
}

private var folderContentType: UTType {
    #if os(macOS)
    return .directory
    #else
    return .folder
    #endif
}

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    
    private let pages = BackupPage.allCases
    @State private var position: ScrollPosition = .init(idType: BackupPage.ID.self)
    @State private var backupFolderIsPresented: Bool = false
    @State private var isShowingFolderPicker: Bool = false
    
    @State private var viewModel = BackupRestoreViewModel()

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(pages) { page in
                    Group {
                        switch page {
                        case .info:
                            BackupInfoView(onBackupClickedCallback: {
                                backupFolderIsPresented.toggle()
                            })
                            .sheet(
                                isPresented: $backupFolderIsPresented,
                                onDismiss: {
                                    backupFolderIsPresented = false
                                    isShowingFolderPicker = false
                                }
                            ) {
                                if !viewModel.statusMessage.isEmpty {
                                    Section(String(localized: "Status")) {
                                        Text(viewModel.statusMessage)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                ChooseBackupFolderView(
                                    onFolderClickedCallback: {
                                        isShowingFolderPicker.toggle()
                                    },
                                    onCancelCallback: {
                                        backupFolderIsPresented = false
                                    }
                                )
                                .onChange(of: viewModel.recoveryKey) { _, newState in
                                    if !newState.isEmpty {
                                        scrollToPage(.recoveryKeyInfo)
                                    }
                                }
                                .presentationDetents([.medium])
                                .fileImporter(
                                    isPresented: $isShowingFolderPicker,
                                    allowedContentTypes: [folderContentType],
                                    allowsMultipleSelection: false
                                ) { result in
                                    saveToSelectedFolder(result: result)
                                }
                            }
                        case .recoveryKeyInfo:
                            RecoveryKeyInfoView(onViewKeyClicked: {
                                scrollToPage(.recoveryKeyView)
                            })
                        case .recoveryKeyView:
                            RecoveryKeyView(
                                copyToClipboardCallback: {},
                                saveToPasswordManagerCallback: {},
                                saveManuallyCallback: {},
                                recoveryKey: viewModel.recoveryKey
                            )
                        }
                    }
                    .containerRelativeFrame([.horizontal])
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition($position)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollDisabled(true)
        .onAppear {
            position.scrollTo(id: BackupPage.first.id)
        }
    }
    
    private func scrollToPage(_ page: BackupPage) {
        withAnimation {
            position.scrollTo(id: page.id)
        }
    }
    
    private func saveToSelectedFolder(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await viewModel.backup(
                    urls: urls,
                    into: modelContext.container
                )
            }
            
        case .failure(let error):
            print("Folder selection failed: \(error.localizedDescription)")
        }
    }
}

#Preview("BackupInfoView") {
    BackupInfoView(onBackupClickedCallback: {})
}

#Preview("ChooseBackupFolderView") {
    ChooseBackupFolderView(
        onFolderClickedCallback: {},
        onCancelCallback: {}
    )
}

#Preview("RecoveryKeyInfoView") {
    RecoveryKeyInfoView(onViewKeyClicked: {})
}

#Preview("RecoveryKeyView") {
    var recoveryKey: String = "1234567890123456789012345678901234567890123456789012345678901234"
    RecoveryKeyView(
        copyToClipboardCallback: {},
        saveToPasswordManagerCallback: {},
        saveManuallyCallback: {},
        recoveryKey: recoveryKey
    )
}
