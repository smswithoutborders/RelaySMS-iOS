//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

func authenticate(phoneNumber: String, password: String) throws -> Vault_V1_AuthenticateEntityResponse {
    let vault = Vault()
    return try vault.authenticateEntity(phoneNumber: phoneNumber, password: password)
}

struct LoginSheetView: View {
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var OTPRequired = false
    @State private var countryCode: String? = nil

    @State var work: Task<Void, Never>?

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPSheetView.TYPE.AUTHENTICATE,
                         phoneNumber: $phoneNumber,
                         countryCode: $countryCode,
                         password: $password)
        }
        else {
            Form {
                TextField("Phone Number (e.g) +237123456789", text: $phoneNumber)
                SecureField("Password", text: $password)
                
                Button("Login") {
                    work = Task {
                        do {
                            OTPRequired = try authenticate(phoneNumber: phoneNumber, password: password).requiresOwnershipProof
                        } catch {
                            print("Something went wrong authenticating: \(error)")
                        }
                    }
                }
            }
            
        }
    }
}

#Preview {
    LoginSheetView()
}
