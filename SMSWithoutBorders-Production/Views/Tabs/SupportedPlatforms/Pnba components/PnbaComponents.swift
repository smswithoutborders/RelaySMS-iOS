//
//  PnbaComponents.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 12/10/2026.
//

import SwiftUI

struct PnbaComponentsView: View {
    @Binding var phoneNumber: String
    @Binding var code: String
    @Binding var password: String
    
    @State var displayName: String
    @State var showCode: Bool
    @State var showPassword: Bool
    @State var errorMessage: String? = ""

    @State var onClick: () -> Void

    var body: some View {
        VStack {
            Text(displayName)
                .font(.headline)
            
            Text(errorMessage ?? "")
                .font(.caption)
                .foregroundColor(.red)
            
            Form {
                TextField(text: $phoneNumber, prompt: Text(String(localized: "Phone number"))) {
                    Text(String(localized: "Phone number"))
                }
                .disabled(showCode || showPassword)
                
                if showCode {
                    SecureField(text: $code, prompt: Text(String(localized: "Code"))) {
                        Text(String(localized: "Code"))
                    }
                    .disabled(showPassword)
                }
                
                if showPassword {
                    SecureField(text: $password, prompt: Text(String(localized: "Password"))) {
                        Text(String(localized: "Password"))
                    }
                }
            
            }
            
            let buttonText = if !showCode && !showPassword {
                String(localized: "Request code")
            } else {
                String(localized: "Submit")
            }
            
            Button(buttonText) {
                onClick()
            }
            .padding()
            .background(Color(.primary))
            .foregroundStyle(Color(.onPrimary))
            .clipShape(Capsule())
            
            if phoneNumber.count > 4 {
                Button(String(localized: "Already have code")) {
                    showCode = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var phoneNumber = "+237123456789"
    @Previewable @State var code = "code"
    @Previewable @State var password = "password"
    
    PnbaComponentsView(
        phoneNumber: $phoneNumber,
        code: $code,
        password: $password,
        displayName: "Telegram",
        showCode: true,
        showPassword: true,
        onClick: {}
    )
}
