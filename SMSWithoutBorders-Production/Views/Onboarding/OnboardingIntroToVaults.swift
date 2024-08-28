//
//  OnboardingIntroToVaults.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct signupLoginOnboardingView: View {
    @Binding var loginSheetShown: Bool
    @Binding var signupSheetShown: Bool
    
    @Binding var completed: Bool
    @Binding var failed: Bool

    var body: some View {
        VStack {
            Tab(buttonView:
                Group {
                    Button {
                        signupSheetShown = true
                    } label: {
                        Text("Create Acocunt")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 10)
                    .sheet(isPresented: $signupSheetShown) {
                        SignupSheetView(completed: $completed, failed: $failed)
                    }

                    Button {
                        loginSheetShown = true
                    } label: {
                        Text("Login")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.bottom, 10)
                    .sheet(isPresented: $loginSheetShown) {
                        VStack {
                            LoginSheetView(completed: $completed, failed: $failed)
                        }
                    }
                    
                },
                title:"Let's get you started",
                subTitle: "Introducing Vaults",
                description: "RelaySMS Vaults keep secure access to your online accounts while you are offline",
                imageName: "OnboardingVault",
                subDescription: "Create a new RelaySMS Vault account or signup to your existing."
            )
        }
    }
}

struct addAccountsView: View {
    @Binding var codeVerifier: String
    @Binding var availablePlatformsPresented: Bool
    
    @State var title: String = "Available platforms"
    @State var description = "Select a platform to save it for offline use"
    
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    
    @Binding var onboardingIndex: Int

    var body: some View {
        VStack {
            Tab(buttonView:
                Button {
                    self.availablePlatformsPresented = true
                } label: {
                    Text("Save Accounts to Vault")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .sheet(isPresented: $availablePlatformsPresented) {
                    AvailablePlatformsSheetsView(codeVerifier: $codeVerifier, title: title, description: description)
                }
                .controlSize(.large)
                .padding(.bottom, 10)
                .buttonStyle(.borderedProminent),
                title: "Add Accounts to Vault",
                subTitle: "Let's get you started",
                description: "You can add accounts to Vault. This accounts are accessible to you when you are offline",
                imageName: "OnboardingVaultOpen",
                subDescription: "The Vault supports storing for multiple online platforms. Click Save Accounts to Vault to see the list"
            )
        }
        .task {
            do {
                if try !Vault.getLongLivedToken().isEmpty && !storedPlatforms.isEmpty {
                    onboardingIndex += 1
                }
            } catch {
                print("Some error adding accounts views: \(error)")
            }
        }
    }
}

struct OnboardingIntroToVaults: View {
    @State var loginSheetShown = false
    @State var signupSheetShown = false
    @State var authRequestSheetShown = false
    
    @State var onboardingIntroComplete: Bool = false
    @State var failed: Bool = false
    @State var availablePlatformsPresented: Bool = false
    
    @State private var showSheet = false
    @State private var sheetHeight: CGFloat = .zero
    
    @Binding var codeVerifier: String
    @Binding var backgroundLoading: Bool
    @Binding var onboardingIndex: Int

    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>


    var body: some View {
        if(backgroundLoading) {
            ProgressView()
        }
        else {
            Group {
                if(onboardingIntroComplete) {
                    addAccountsView(codeVerifier: $codeVerifier,
                                    availablePlatformsPresented: $availablePlatformsPresented, onboardingIndex: $onboardingIndex)
                } else {
                    signupLoginOnboardingView(loginSheetShown: $loginSheetShown,
                              signupSheetShown: $signupSheetShown,
                              completed: $onboardingIntroComplete,
                              failed: $failed)
                }
            }
        }
    }
}


struct OnboardingIntroVaults_Preview: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier: String = ""
        @State var isBackgroundLoading: Bool = false
        @State var completed: Bool = true
        @State var onboardingIndex: Int = 0
        OnboardingIntroToVaults(
            codeVerifier: $codeVerifier,
            backgroundLoading: $isBackgroundLoading,
            onboardingIndex: $onboardingIndex )
    }
}

struct AddAccounts_Preview: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier: String = ""
        @State var isBackgroundLoading: Bool = false
        @State var completed: Bool = true
        @State var onboardingIndex: Int = 0
        @State var availablePlatformsPresented: Bool = false
        addAccountsView(
            codeVerifier: $codeVerifier,
            availablePlatformsPresented: $availablePlatformsPresented,
            onboardingIndex: $onboardingIndex )
    }
}
