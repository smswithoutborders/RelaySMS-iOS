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
                

                Button("English", systemImage: "globe") {
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
                .cornerRadius(38.5)

                LanguageSelectorMenu()
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


// View
struct LanguageSelectorMenu: View {
    
    @EnvironmentObject var languagePreferencesManager: LanguagePreferencesManager
    @State private var selectedLang: Language
    
    let languageList: [Language] = [
        Language(label: "English", endonym: "English", code: "en"),
        Language(label: "French", endonym: "Français", code: "fr"),
        Language(label: "Spanish", endonym: "Español", code: "es"),
        Language(label: "Arabic", endonym: "العربية", code: "ar", rtl: true),
        Language(label: "Farsi", endonym: "فارسی", code: "fa", rtl: true),
        Language(label: "Turkish", endonym: "Türkçe", code: "tr")
    ]
    
    init() {
        let currentCode: String = LanguagePreferencesManager.getStoredLanguage()
        let currentLanguage = languageList.first { $0.code == currentCode }
        selectedLang = languageList.first { $0.code == currentCode } ??  Language(label: "English", endonym: "English", code: "en")
    }
    

    
    var body: some View {
            Menu {
                ForEach(languageList, id: \.code) { language in
                    Button(action: {
                        selectedLang = language;
                        LanguagePreferencesManager().changeLanguage(to: language.code)
                    }){
                        Text(language.endonym).frame(maxWidth: .infinity, alignment: language.rtl ? .trailing : .leading)
                    }
                }
            } label: {
                Label(selectedLang.endonym, systemImage: "globe").padding(12).background(Color.blue.opacity(0.1)).clipShape(Capsule())
            }.environment(\.locale, Locale(identifier: selectedLang.code))
    }
}


#Preview {
    LanguageSelectorMenu()
}

// Controller, this should be moved out of the view
class LanguagePreferencesManager: ObservableObject {
    @Published var currentLanguage: String

    init() {
        self.currentLanguage = Self.getStoredLanguage()
    }
    
    func changeLanguage(to languageCode: String){
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        objectWillChange.send()
    }
    
    func updateLanguageFromDefaults(){
        let newLanguage = Self.getStoredLanguage()
        if currentLanguage != newLanguage {
            currentLanguage = newLanguage
        }
    }
    
    static func getStoredLanguage() -> String {
        if let languageArray = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let languageCode = languageArray.first {
            return languageCode
        }
        
        if #available(iOS 16.0, *) {
            return Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            return Locale.current.languageCode ?? "en"
        }

    }
}
