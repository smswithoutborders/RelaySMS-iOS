//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

nonisolated func authenticate(phoneNumber: String, password: String) async throws -> Vault_V1_AuthenticateEntityResponse {
    let vault = Vault()
    return try vault.authenticateEntity(phoneNumber: phoneNumber, password: password)
}

struct LoginSheetView: View {
    
    #if DEBUG
        @State private var phoneNumber: String = "+2371234567"
        @State private var password: String = "dummy_password"
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
                                let response = try await authenticate(phoneNumber: phoneNumber, password: password)
                                self.otpRetryTimer = Int(response.nextAttemptTimestamp)
                                OTPRequired = response.requiresOwnershipProof
                            } catch {
                                
                                print("Something went wrong authenticating: \(error)")
                                isLoading = false
                                failed = true
                            }
                        }
                    }
                    .alert(isPresented: $failed) {
                        Alert(title: Text("Error"), message: Text("Something wen't wrong"))
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
