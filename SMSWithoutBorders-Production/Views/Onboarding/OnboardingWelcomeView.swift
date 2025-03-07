//
//  SwiftUIView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @Environment(\.locale) var locale
    @Binding var pageIndex: Int
    
    @State private var showLanguageChangeConfirmationAlert = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    showLanguageChangeConfirmationAlert = true
                } label: {
                    if #available(iOS 16, *) {
                        if let languageCode = locale.language.languageCode?.identifier,
                           let languageName = Locale.current.localizedString(forLanguageCode: languageCode) {
                            Label(languageName, systemImage: "globe")
                                .padding(12)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                    } else {
                        if let languageCode = locale.languageCode,
                           let languageName = Locale.current.localizedString(forLanguageCode: languageCode) {
                            Label(languageName, systemImage: "globe")
                                .padding(12)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }.padding(16)
                .alert("Change App Language", isPresented: $showLanguageChangeConfirmationAlert) {
                    Button("Cancel", role: .cancel){
                        showLanguageChangeConfirmationAlert = false
                    }
                    Button("Open Settings"){
                        // Open language settings page instead
                        if let url: URL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                        
                    }
                } message: {
                    Text(String(localized: "Continue to iOS settings and select your preferred language for RelaySMS.", comment: "Instructions for chnaging application langueg via system settings.") )
                }
            }
            Text("Welcome to RelaySMS!")
                .font(RelayTypography.headlineSmall)
                .padding(.top, 30)
                
                
            VStack {
                Image("1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                    .padding(.bottom, 20)


                Text(String(localized: "Use SMS to make a post, send emails and messages with no internet connection", comment: "Explains that you can use Relay to make posts, and send emails and messages without an internet conenction"))
                    .font(RelayTypography.titleLarge)
                    .padding(.bottom, 10)
                    .multilineTextAlignment(.center)
                

            }.padding()
            
            Button {
                pageIndex += 1
            } label: {
                Text("Learn how it works")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(Capsule())
            .padding()

            Button {
            } label: {
                Text("Read our privacy policy")
            }
        }
    }
}

#Preview {
    @State var pageIndex = 0
    OnboardingWelcomeView(pageIndex: $pageIndex)
}

