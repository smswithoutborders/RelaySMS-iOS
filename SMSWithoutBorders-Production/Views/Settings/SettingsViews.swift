//
//  SettingsViews.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 29/10/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var backupSelected: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
//                Section(header: Text("Account")) {
//                    HStack {
//                        Image(systemName: "person.crop.circle.fill")
//                            .font(.system(size: 44))
//                            .foregroundColor(.blue)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            TextField("Username", text: $username)
//                                .font(.headline)
//                            Text("Premium Member")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                    .padding(.vertical, 4)
//                }
//                
                // MARK: - Stored tokens
                Section(header: Text(String(localized: "Stored tokens"))) {
                    Picker(
                        selection: $backupSelected,
                        label: Label(
                            String(localized: "Backups"),
                            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                        )) {
                    }
                    .pickerStyle(.navigationLink) // Pushes to a clean selection list sub-view
                }
                
//                // MARK: - Connectivity & Data Section
//                Section(header: Text("Preferences"), footer: Text("Disabling this allows backup sync over cellular networks.")) {
//                    Toggle(isOn: $notificationsEnabled) {
//                        Label("Push Notifications", systemImage: "bell.badge.fill")
//                    }
//                    
//                    Toggle(isOn: $syncOverWifiOnly) {
//                        Label("Sync Over Wi-Fi Only", systemImage: "wifi")
//                    }
//                }
                
                // MARK: - App Info Section
                Section(header: Text(String(localized: "About"))) {
                    HStack {
                        Label(String(localized: "Version"), systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0 (Build 42)")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: StaticVariables.App.privacyPolicy)!) {
                        Label(String(localized: "Privacy Policy"), systemImage: "lock.shield.fill")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
