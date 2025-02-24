//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI
import CountryPicker


struct LoginSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    #if DEBUG
//        @State private var phoneNumber: String = "123456"
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

    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName

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
            
            VStack {
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
                            .font(.title)
                            .bold()
                            .padding()
                        
                        Group {
                            Text("Welcome back")
                            Text("Sign in to continue with existing account")
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
                        .padding(.bottom, 10)
                        Rectangle().frame(height: 1).foregroundColor(.secondary)
                        
                        Button {
                            passwordRecoveryRequired = true
                        } label: {
                            Text("Forgot password?")
                                .bold()
                        }
                        .padding(.top, 25)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        SecureField("Password", text: $password)
                            .padding(.bottom, 10)
                        Rectangle().frame(height: 1).foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()

                    VStack{
                        if(isLoading) {
                            ProgressView()
                        }
                        else {
                            Button {
                                isLoading = true
                                Task {
                                    do {
                                        self.otpRetryTimer = try await signupAuthenticateRecover(
                                            phoneNumber: getPhoneNumber(),
                                            countryCode: "",
                                            password: password,
                                            type: OTPAuthType.TYPE.AUTHENTICATE,
                                            context: context
                                        )
                                        
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
                                Text("Login")
                                    .bold()
                                    .frame(maxWidth: .infinity, maxHeight: 35)
        //                                .frame(width: 200 , height: 50, alignment: .center)
                            }
                            .buttonStyle(.borderedProminent)
                            .alert(isPresented: $failed) {
                                Alert(title: Text("Error"), message: Text(errorMessage))
                            }
                            
                            Button {
                                self.otpRequired = true
                            } label: {
                                Text("Already got code")
                            }
                            .padding(.top, 10)
                            .font(.subheadline)
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
                            .font(.subheadline)
                            .padding()
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
