//
//  SwiftUIView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to RelaySMS")
                .font(.title)
                .fontWeight(.semibold)
                
                
            VStack {
                Text("Use SMS to make a post, send emails and messages with no internet connection")
                    .font(.subheadline)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Image("Recents")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 20)
                
                LanguageSelectorButtonView()
            }.padding()
            
            
            Spacer()
        }
            
    }
}

#Preview {
    OnboardingWelcomeView()
}




struct Language: Hashable {
    let label: String;
    let endonym: String;
    let code: String;
    var rtl: Bool = false;
}




struct LanguageSelectorButtonView: View {
    @EnvironmentObject var languageManager: LanguagePreferencesManager
    @State private var selectedLang: Language
    @State private var showLanguageChangeConfirmationAlert = false
    
    init() {
        // Gets current language code from user preferences
        let currentCode: String = LanguagePreferencesManager.getStoredLanguageCode()
        // Sets selectedLanguage code as current language or defaults to English
       selectedLang = LanguagePreferencesManager.getLanguageFromCode(langCode: currentCode) ?? Language(label: "English", endonym: "English", code: "en") // Should refactor this to use some sort of enhanced enums
        _selectedLang = State(initialValue: selectedLang)
    }
    

    var body: some View {
        Button(
            action: {
                showLanguageChangeConfirmationAlert = true
            },
            label: {
                Label(LanguagePreferencesManager.getLanguageFromCode(langCode: String(languageManager.currentLanguageCode.split(separator: "-").first ?? "n/a"))?.endonym ?? "Select Language", systemImage: "globe")
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            })
        .alert("Change App Language", isPresented: $showLanguageChangeConfirmationAlert) {
            Button("Cancel", role: .cancel){
                showLanguageChangeConfirmationAlert = false
            }
            Button("Open Settings"){
                // Method 1: Change the language when the user confirms.
                // languageManager.changeLanguage(to: selectedLang.code)
                // Method 2: open language settings page instead
                if let url: URL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                
            }
        } message: {
            Text(String(localized: "Continue to iOS settings and select your preferred language for RelaySMS.", comment: "Instructions for chnaging application langueg via system settings.") )
        }
    }
}

#Preview {
    LanguageSelectorButtonView()
}
