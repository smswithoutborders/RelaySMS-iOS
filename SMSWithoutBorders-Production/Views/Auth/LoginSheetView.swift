//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import CountryPicker
import SwiftUI

struct LoginSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    #if DEBUG
        @State private var phoneNumber = "1123457528"
        @State private var password: String = "dMd2Kmo9#"
    #else
        @State private var phoneNumber: String = ""
        @State private var password: String = ""
    #endif

    @Binding var isLoggedIn: Bool
    @Binding var createAccountRequested: Bool
    @Binding var passwordRecoveryRequired: Bool

    @State var otpRequired: Bool = false
    
    @State private var countryCode: String = ""
    @State private var isLoading = false
    @State var work: Task<Void, Never>?
    @State private var failed: Bool = false
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""
    @State private var country: Country?
    @State private var showCountryPicker = false
    
    @State var callbackText = "Welcome back!"
    @State var completedSuccessfully = false

    @State var type = OTPAuthType.TYPE.AUTHENTICATE

    //@State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName

    var body: some View {
        ScrollView {
            VStack {
                NavigationLink(
                    destination:
                        OTPSheetView(
                            countryCode: $countryCode,
                            phoneNumber: $phoneNumber,
                            password: $password,
                            failed: $failed,
                            completedSuccessfully: $completedSuccessfully,
                            type: $type
                        ),
                    isActive: $otpRequired
                ) {
                    EmptyView()
                }
                VStack(alignment: .center) {
                    if completedSuccessfully {
                        Spacer()
                        SuccessAnimations(callbackText: $callbackText) {
                            do {
                                let vault = Vault()
                                let llt = try Vault.getLongLivedToken()
                                try vault.refreshStoredTokens(
                                    llt: llt,
                                    context: context,
                                    storedTokenEntities: nil
                                )
                            } catch {
                                print("Error refreshing tokens: \(error)")
                                failed = true
                                errorMessage = error.localizedDescription
                            }
                        } callback: {
                            isLoggedIn = true
                            dismiss()
                        }
                    } else {
                        VStack {
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 75, height: 75)
                                .padding()

                            Text("Login")
                                .font(RelayTypography.titleLarge)
                                .padding()

                            Group {
                                Text("Welcome back")
                                Text("Sign in to continue with existing account")
                            }
                            .foregroundStyle(.secondary)
                            .font(RelayTypography.bodyMedium)
                        }
                        .padding(.bottom, 30)

                        RelayContactField(
                            label: "Phone Number",
                            initialValue: phoneNumber,
                            onPhoneNumberInputted: { relayContact in
                                print("Phone number received from contact field callback: \(relayContact.rawValue)")
                                self.phoneNumber = relayContact.internationalPhoneNumber
                            }
                        )

                        Button {
                            passwordRecoveryRequired = true
                        } label: {
                            Text("Forgot password?")
                        }
                        .padding(.top, 25)
                        .font(RelayTypography.bodyMedium)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        RelayPasswordField(text: $password)

                        Spacer(minLength: 24)

                        Button {
                            isLoading = true
                            Task {
                                do {
                                    self.otpRetryTimer =
                                        try await signupAuthenticateRecover(
                                            phoneNumber: phoneNumber,
                                            countryCode: "",
                                            password: password,
                                            type: OTPAuthType.TYPE.AUTHENTICATE,
                                            context: context
                                        )
                                    self.otpRequired = true
                                } catch Vault.Exceptions.requestNotOK(
                                    let status)
                                {
                                    print(
                                        "Something went wrong authenticating: \(status)"
                                    )
                                    isLoading = false
                                    failed = true
                                    errorMessage = status.message!
                                } catch {
                                    isLoading = false
                                    failed = true
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Login").font(RelayTypography.bodyMedium).bold()
                            }
                        }
                        .buttonStyle(.relayButton(variant: .primary))
                        .alert("Error", isPresented: $failed) {
                            Button(role: .destructive) {
                                failed = false
                            } label: {
                                Text("Okay!")
                            }
                        } message: {
                            Text(errorMessage)
                        }

                        Button {
                            self.otpRequired = true
                        } label: {
                            Text("Already got code")
                        }
                        .padding(.top, 10)
                        .font(RelayTypography.bodyMedium)
                        .disabled(phoneNumber.isEmpty)

                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Button {
                                createAccountRequested = true
                            } label: {
                                Text("Create account")
                                    .bold()
                            }
                        }
                        .font(RelayTypography.bodyMedium)
                        .padding()
                    }

                }
                .padding([.horizontal], 16)
                .onChange(of: failed) { v in
                    if v {
                        isLoading = false
                        otpRequired = false
                    }
                }
            }
        }


    }
}

struct LoginSheetView_Preview: PreviewProvider {
    static var previews: some View {
        @State var completed: Bool = false
        @State var failed: Bool = false
        @State var createAccountRequested: Bool = false
        LoginSheetView(
            isLoggedIn: $completed,
            createAccountRequested: $createAccountRequested,
            passwordRecoveryRequired: $createAccountRequested
        )
    }
}

struct LoginSheetViewSuccess_Preview: PreviewProvider {
    static var previews: some View {
        @State var completed: Bool = true
        @State var failed: Bool = false
        @State var createAccountRequested: Bool = false
        LoginSheetView(
            isLoggedIn: $completed,
            createAccountRequested: $createAccountRequested,
            passwordRecoveryRequired: $createAccountRequested
        )
    }
}
