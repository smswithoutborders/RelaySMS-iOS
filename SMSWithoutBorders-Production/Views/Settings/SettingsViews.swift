//
//  SettingsViews.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 29/10/2026.
//

import SwiftUI

let supportedLanguages = [
    "en" : LocalizedStringResource("English"),
    "ar" : LocalizedStringResource("Arabic"),
    "fr" : LocalizedStringResource("French"),
    "de" : LocalizedStringResource("German"),
    "fa" : LocalizedStringResource("Persian"),
    "sn" : LocalizedStringResource("Shona"),
    "es" : LocalizedStringResource("Spanish"),
    "sw" : LocalizedStringResource("Swahili"),
    "tr" : LocalizedStringResource("Turkish"),
]


extension Bundle {
    var buildNumber: String {
        return object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
    
    var appVersion: String {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
}

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    
    @State private var backupSelected: Bool = false
    private let settingsLabel: LocalizedStringResource = "Settings"
    private let languageLabel: LocalizedStringResource = "Language"

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Stored tokens
                Section {
                    Picker(languageLabel, selection: $selectedLanguage) {
                        ForEach(supportedLanguages.keys.sorted(), id: \.self) { tag in
                            Text(supportedLanguages[tag]!).tag(tag)
                        }
                    }
                }
                
                Section(header: Text(LocalizedStringResource("About"))) {
                    HStack {
                        Label(LocalizedStringResource("Version"), systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0 (Build \(Bundle.main.buildNumber))")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: StaticVariables.App.privacyPolicy)!) {
                        Label(LocalizedStringResource("Privacy Policy"), systemImage: "lock.shield.fill")
                    }
                }
            }
            .navigationTitle(settingsLabel)
        }
    }
}

#Preview {
    SettingsView()
}
