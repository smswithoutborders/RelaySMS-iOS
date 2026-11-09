//
//  RestoreView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftUI
import SwiftData


struct RestoreRecoveryKeyView: View {
    @Environment(\.modelContext) private var modelContext
    @State var backupData: Data
    
    @State private var recoveryKey: String = ""
    @State private var enableNext: Bool = false

    @State private var viewModel = BackupRestoreViewModel()
    @State var onNextCallback: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(String(localized: "Enter your recovery key"))
                .font(.title)
                .padding()
            
            Text(String(localized: "Your recovery key is a 64-character code required to recover your data."))
                .padding(.bottom, 20)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $recoveryKey)
                    .textInputAutocapitalization(.sentences)
                    .scrollContentBackground(.hidden)
                    .frame(height: 180)
                    .padding(8)
                    .disabled(recoveryKey.count == 64)
                
                if recoveryKey.isEmpty {
                    Text(String(localized: "Recovery key"))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.top, 16)
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                } else if recoveryKey.count == 64 {
                    Text(recoveryKey)
                        .foregroundColor(Color(.systemGray3))
                        .padding(.top, 16)
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                }
                
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button(String(localized: "Next")) {
                    onNextCallback()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!enableNext)
            }
            .padding(.top, 20)
        }
        .padding()
        .navigationTitle(String(localized: "Restore Backup"))
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: recoveryKey) {
            if recoveryKey.count == 64 {
                viewModel.statusMessage = ""
                Task {
                    viewModel.decryptBackup(
                        into: modelContext.container,
                        data: backupData,
                        recoveryKey: recoveryKey
                    )
                    
                    enableNext = true
                }
            } else {
                viewModel.statusMessage = String(localized: "Recovery key is a 64-characters long")
            }
        }
    
    }
}


struct RestoreBackupView: View {
    @AppStorage("isOnboarded") private var isOnboarded = false
    @State private var showPicker: Bool = false
    @State private var onboardingIsPresent: Bool = false
    @State private var status: String = ""
    
    @State private var viewModel = BackupRestoreViewModel()

    var body: some View {

        if viewModel.backupData != nil {
            RestoreRecoveryKeyView(
                backupData: viewModel.backupData!,
                onNextCallback: { onboardingIsPresent = true }
            )
            .navigationDestination(isPresented: $onboardingIsPresent) {
                OnboardingView(
                    startPosition: OnboardingPage.privacy,
                    onboardingCompletedCallback: { isOnboarded = true }
                )
            }
        } else {
            VStack(alignment: .leading) {
                Text(String(localized: "Restore on-device backup"))
                    .font(.title)
                    .padding()
                
                Text(String(localized: "Restore your saved accounts from the backup you saved on your device. If you don't restore now, you won't be able to restore later."))
                    .padding(.bottom, 20)
                
                Button(action: { showPicker = true }){
                    GroupBox {
                        HStack {
                            Image(systemName: "document")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                            VStack(alignment: .leading) {
                                Text(String(localized: "Choose your backup file"))
                                    .font(.headline)
                                Text(String(localized: "Select the file on your device where your backup is stored"))
                            }
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let url = try result.get().first else { return }
                    try viewModel.readBackupFile(from: url)
                } catch {
                    status = error.localizedDescription
                }
            }
            .padding()
            .navigationTitle(String(localized: "Restore Backup"))
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    
    }
}


#Preview {
    RestoreBackupView()
}

#Preview("RestoreRecoveryKeyView") {
    RestoreRecoveryKeyView(
        backupData: Data(),
        onNextCallback: {}
    )
}
