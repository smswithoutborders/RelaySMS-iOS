//
//  RecoverySheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 07/08/2024.
//

import SwiftUI
import CountryPicker

struct RecoverySheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    @State private var country: Country? = Country(isoCode: "CM")
    
    #if DEBUG
        @State private var phoneNumber = "1123457528"
        @State private var password: String = "dMd2Kmo9#"
        @State private var rePassword: String = "dMd2Kmo9#"
        @State private var selectedCountryCodeText: String? = "CM"
    #else
        @State private var phoneNumber = ""
        @State private var password: String = ""
        @State private var rePassword: String = ""
        @State private var selectedCountryCodeText: String? = "Select country"
    #endif
    

    @State private var countryCode: String = Country(isoCode: "CM").isoCode
    @State private var showCountryPicker = false
    @State private var isLoading = false
    @State private var otpRequired = false
    @State var failed: Bool = false
    @State private var acceptTermsConditions: Bool = false
    @State private var passwordsNotMatch: Bool = false
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""
    @State var callbackText: String = "Recovered successfully!"
    @State var completedSuccessfully: Bool = false
    @State var type = OTPAuthType.TYPE.RECOVER

    @Binding var isRecovered: Bool

    var body: some View {
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
            
            if(completedSuccessfully) {
                SuccessAnimations( callbackText: $callbackText ) {
                    do {
                        let vault = Vault()
                        let llt = try Vault.getLongLivedToken()
                        try vault.refreshStoredTokens(
                            llt: llt,
                            context: context
                        )
                    } catch {
                        print("Error refreshing tokens: \(error)")
                        failed = true
                        errorMessage = error.localizedDescription
                    }
                } callback: {
                    isRecovered = true
                    dismiss()
                }
            } else {
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
                                 let flag = countryCode
                                 Text(flag.getFlag() + "+" + country!.phoneCode)
                                    .foregroundColor(Color.secondary)
                             }.sheet(isPresented: $showCountryPicker) {
                                 CountryPicker(country: $country, selectedCountryCodeText: $selectedCountryCodeText)
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
                                        
                                        self.phoneNumber = getPhoneNumber()
                                        self.otpRequired = true
                                    } catch Vault.Exceptions.requestNotOK(let status){
                                        print("Something went wrong authenticating: \(status)")
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
                                self.phoneNumber = getPhoneNumber()
                                otpRequired = true
                            }
                            .disabled(phoneNumber.isEmpty)
                        }
                    }
                    .padding()
                }
            
            }
        }
    }
    
    private func getPhoneNumber() -> String {
        return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
    }
}

struct RecoverySheetView_Preview: PreviewProvider {

    static var previews: some View {
        @State var completed: Bool = false
        @State var isRecovered: Bool = false
        @State var failed: Bool = false
        RecoverySheetView(isRecovered: $isRecovered)
    }
}
