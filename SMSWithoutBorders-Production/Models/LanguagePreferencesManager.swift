//
//  LanguagePreferencesManager.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/02/2025.
//

import SwiftUI

struct Language: Hashable {
    let label: String;
    let endonym: String;
    let code: String;
    var rtl: Bool = false;
}

class LanguagePreferencesManager: ObservableObject {
    @Published var currentLanguageCode: String
    @Published var currentLocale: Locale?
    @Published var needsRestart: Bool = false
    
    init() {
        self.currentLanguageCode = Self.getStoredLanguageCode()
    }
    
    func changeLanguage(to languageCode: String){
        // Store the new language preference
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        // Update the current language
        currentLanguageCode = languageCode
        currentLocale = Locale(identifier: currentLanguageCode)
    }
    
    
    static func getStoredLanguageCode() -> String {
        print("Attempting to get stored language code...")
        // Check for user selected language first
        if let languageArray = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
            let languageCode = languageArray.first {
                print("Gotten language from user defaults: \(languageCode)")
                return languageCode
            }
            // Fall back to systme language
            if #available(iOS 16.0, *) {
                print("Saved language not found, falling back to default system locale")
                return Locale.current.language.languageCode?.identifier ?? "en"
            } else {
                print("Saved language not found, falling back to default system locale")
                return Locale.current.languageCode ?? "en"
            }
        }
        
        func getLocaleForCurrentLanguage() -> Locale {
            return Locale(identifier: currentLanguageCode)
        }
        static func getLanguageFromCode(langCode: String) -> Language? {
            return LanguagePreferencesManager.availableLanguages.first{ $0.code == langCode}
        }

    static let availableLanguages: [Language] = [
        Language(label: "English", endonym: "English", code: "en"),
        Language(label: "French", endonym: "Français", code: "fr"),
        Language(label: "Spanish", endonym: "Español", code: "es"),
        Language(label: "German", endonym: "Deutsch", code: "de"),
        Language(label: "Arabic", endonym: "العربية", code: "ar", rtl: true),
        Language(label: "Farsi", endonym: "فارسی", code: "fa", rtl: true),
        Language(label: "Turkish", endonym: "Türkçe", code: "tr"),
        Language(label: "Swahili", endonym: "Kiswahili", code: "sw")
    ]
}

