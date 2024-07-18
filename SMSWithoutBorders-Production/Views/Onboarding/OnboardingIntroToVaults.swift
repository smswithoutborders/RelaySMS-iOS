//
//  OnboardingIntroToVaults.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingIntroToVaults: View {
    
    @State private var introTab = "introTab"
    @State private var exampleTab = "exampleTab"
    
    @State var loginSheetShown = false
    @State var signupSheetShown = false
    @State var authRequestSheetShown = false
    
    @State var completed: Bool = false
    @State var failed: Bool = false
    @State var availablePlatformsPresented: Bool = false
    
    @State private var showSheet = false
    @State private var sheetHeight: CGFloat = .zero
    
    @Binding var codeVerifier: String
    
    @Binding var backgroundLoading: Bool

    struct InnerHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = .zero
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }


    var body: some View {
        if(backgroundLoading) {
            ProgressView()
        }
        else {
            TabView(selection: completed ? $exampleTab : $introTab) {
                VStack {
                    Tab(buttonView:
                        Group {
                            Button("Login") {
                                loginSheetShown = true
                            }
                            .buttonStyle(.borderedProminent)
                            .sheet(isPresented: $loginSheetShown) {
                                VStack {
                                    LoginSheetView(completed: $completed, failed: $failed)
                                }
                            }
                            
                            Button("Create new") {
                                signupSheetShown = true
                            }
                            .sheet(isPresented: $signupSheetShown) {
                                SignupSheetView(completed: $completed, failed: $failed)
                            }
                            .buttonStyle(.borderedProminent)
                        },
                        title:"Let's get you started",
                        subTitle: "Introducing Vaults",
                        description: "RelaySMS Vaults keep secure access to your online accounts while you are offline",
                        imageName: "OnboardingVault",
                        subDescription: "Create a new RelaySMS Vault account or signup to your existing."
                    )
                }
                .tag(introTab)
                
                VStack {
                    Tab(buttonView:
                        Button("Add Accounts") {
                        self.availablePlatformsPresented = true
                        }
                        .sheet(isPresented: $availablePlatformsPresented) {
                            AvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
                        }
                        .buttonStyle(.borderedProminent),
                        title: "Add Accounts to Vault",
                        subTitle: "Let's get you started",
                        description: "You can add accounts your Vault. This accounts are accessible to you when you are offline",
                        imageName: "OnboardingVaultOpen",
                        subDescription: "The Vault supports storing for multiple online paltforms. Click Add Accounts storage to see the list"
                    )
                }
                .tag(exampleTab)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .task {
                do {
                    if(try !Vault.getLongLivedToken().isEmpty) {
                        self.completed = true
                    }
                } catch {
                    
                }
            }
        }
    }
}

#Preview {
    @State var codeVerifier: String = ""
    @State var isBackgroundLoading: Bool = true
    OnboardingIntroToVaults(codeVerifier: $codeVerifier, backgroundLoading: $isBackgroundLoading)
}
