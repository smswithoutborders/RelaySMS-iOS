//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

struct LoginSheetView: View {
    
    #if DEBUG
        @State private var phoneNumber: String = "+2371234567"
        @State private var password: String = "LL<O3ZG~=z-epkv"
    #else
        @State private var phoneNumber: String = ""
        @State private var password: String = ""
    #endif
    
    @State private var OTPRequired = false
    @State private var countryCode: String? = nil
    
    @State private var isLoading = false

    @State var work: Task<Void, Never>?
    
    @Binding var completed: Bool
    @Binding var failed: Bool
    
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPAuthType.TYPE.AUTHENTICATE,
                         retryTimer: otpRetryTimer, phoneNumber: $phoneNumber,
                         countryCode: $countryCode,
                         password: $password,
                         completed: $completed,
                         failed: $failed)
        }
        else {
            Form {
                TextField("Phone Number (e.g) +237123456789", text: $phoneNumber)
                SecureField("Password", text: $password)
                
                if(isLoading) {
                    ProgressView()
                }
                else {
                    Button("Login") {
                        isLoading = true
                        Task {
                            do {
                                self.otpRetryTimer = try await signupOrAuthenticate(
                                    phoneNumber: phoneNumber,
                                    countryCode: "",
                                    password: password,
                                    type: OTPAuthType.TYPE.AUTHENTICATE)
                                self.OTPRequired = true
                            } catch Vault.Exceptions.requestNotOK(let status){
                                print("Something went wrong authenticating: \(status)")
                                isLoading = false
                                failed = true
                                var (field, message) = Vault.parseErrorMessage(message: status.message) ?? (nil, status.message)
                                errorMessage = message!
                            }
                        }
                    }
                    .alert(isPresented: $failed) {
                        Alert(title: Text("Error"), message: Text(errorMessage))
                    }
                }
            }
            
        }
    }
}

#Preview {
    
    @State var completed: Bool = false
    @State var failed: Bool = false
    LoginSheetView(completed: $completed, failed: $failed)
}
