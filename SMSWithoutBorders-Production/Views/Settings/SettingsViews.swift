//
//  SettingsViews.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 29/10/2026.
//

import SwiftUI

struct SettingsView: View {
    // 1. Persistent State Management using AppStorage
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme = "Blue"
    @AppStorage("username") private var username = "Apple Developer"
    @AppStorage("syncOverWifiOnly") private var syncOverWifiOnly = false
    
    let themes = ["Blue", "Green", "Red", "Orange", "Dark"]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Section
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Username", text: $username)
                                .font(.headline)
                            Text("Premium Member")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text(String(localized: "Stored tokens"))) {
                    Picker(
                        selection: $selectedTheme,
                        label: Label(
                            String(localized: "Backups"),
                            systemImage: ""
                        )) {
//                        ForEach(themes, id: \.self) { theme in
//                            Text(theme).tag(theme)
//                        }
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
                Section(header: Text("About")) {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0 (Build 42)")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com")!) {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
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
