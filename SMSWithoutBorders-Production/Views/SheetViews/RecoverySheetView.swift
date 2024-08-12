//
//  RecoverySheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 07/08/2024.
//

import SwiftUI
import CountryPicker

struct RecoverySheetView: View {
    #if DEBUG
        @State private var phoneNumber: String = "1234567"
        @State private var password: String = "LL<O3ZG~=z-epkv"
        @State private var rePassword: String = "LL<O3ZG~=z-epkv"
        @State private var selectedCountryCodeText: String? = "CM"
    #else
        @State private var phoneNumber: String = ""
        @State private var password: String = ""
        @State private var rePassword: String = ""
        @State private var selectedCountryCodeText: String? = "Select country"
    #endif

    @State private var country: Country?
    @State private var showCountryPicker = false
    
    @State private var isLoading = false
    
    @State private var OTPRequired = false
    
    @Binding var completed: Bool
    @Binding var failed: Bool
    
    @State private var acceptTermsConditions: Bool = false
    @State private var passwordsNotMatch: Bool = false

    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPAuthType.TYPE.RECOVER,
                         retryTimer: otpRetryTimer,
                         phoneNumber: getPhoneNumber(),
                         countryCode: $selectedCountryCodeText,
                         password: $password,
                         completed: $completed,
                         failed: $failed)
        }
        else {
            VStack {
                VStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 75, height: 75)
                        .padding()

                    Text("Forgot password?")
                        .font(.title)
                        .bold()
                        .padding()
                    
                    Group {
                        Text("If you forgot your password")
                        Text("Enter your phone number and new passwords")
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }
                .padding(.bottom, 30)
                
                VStack {
                    HStack {
                         Button {
                             showCountryPicker = true
                         } label: {
                             let flag = country?.isoCode ?? Country.init(isoCode: "CM").isoCode
                             Text(flag.getFlag() + "+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                                .foregroundColor(Color.secondary)
                         }.sheet(isPresented: $showCountryPicker) {
                             CountryPicker(country: $country,
                                           selectedCountryCodeText: $selectedCountryCodeText)
                         }
                         Spacer()
                         TextField("Phone Number", text: $phoneNumber)
                             .keyboardType(.numberPad)
                             .textContentType(.emailAddress)
                             .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    SecureField("Password", text: $password)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    SecureField("Re-enter password", text: $rePassword)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                    if passwordsNotMatch {
                        Text("Passwords don't match")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .padding()
                Spacer()
                
                VStack {
                    if(self.isLoading) {
                        ProgressView()
                        Spacer()
                    } else {
                        Button {
                            if password != rePassword {
                                passwordsNotMatch = true
                                return
                            }
                            self.isLoading = true
                            Task {
                                do {
                                    self.otpRetryTimer = try await signupAuthenticateRecover(
                                        phoneNumber: getPhoneNumber(),
                                        countryCode: "",
                                        password: password,
                                        type: OTPAuthType.TYPE.RECOVER)
                                    
                                    self.OTPRequired = true
                                } catch Vault.Exceptions.requestNotOK(let status){
                                    print("Something went wrong authenticating: \(status)")
                                    isLoading = false
                                    failed = true
                                    errorMessage = status.message!
                                    phoneNumber = ""
                                } catch {
                                    isLoading = false
                                    failed = true
                                    errorMessage = error.localizedDescription
                                    phoneNumber = ""
                                }
                            }
                        } label: {
                            Text("Continue")
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: 35)
                        }
                        .buttonStyle(.borderedProminent)
                        .alert(isPresented: $failed) {
                            Alert(title: Text("Error"), message: Text(errorMessage))
                        }
                        .padding(.bottom, 20)
                        Button("Already got SMS code") {
                            OTPRequired = true
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func getPhoneNumber() -> String {
        return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
    }
}

#Preview {
    @State var completed: Bool = false
    @State var failed: Bool = false
    RecoverySheetView(completed: $completed, failed: $failed)
}
