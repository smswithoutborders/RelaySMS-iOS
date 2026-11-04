//
//  RestoreView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 04/11/2026.
//

import SwiftUI

struct RestoreView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text(String(localized: "Restore on-device backup"))
                    .font(.title)
                    .padding()
                
                Text(String(localized: "Restore your saved accounts from the backup you saved on your device. If you don't restore now, you won't be able to restore later."))
                    .padding(.bottom, 20)
                
                Button(action: {}){
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
            .padding()
            .navigationTitle(String(localized: "Restore Backup"))
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct RestoreRecoveryKeyView: View {
    @State private var recoveryKey: String = ""
    var body: some View {
        NavigationStack {
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
                    
                    if recoveryKey.isEmpty {
                        Text(String(localized: "Recovery key"))
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
                
                HStack {
                    Spacer()
                    Button("Next") {
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 20)
            }
            .padding()
            .navigationTitle(String(localized: "Restore Backup"))
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

#Preview {
    RestoreView()
}

#Preview("RestoreRecoveryKeyView") {
    RestoreRecoveryKeyView()
}
