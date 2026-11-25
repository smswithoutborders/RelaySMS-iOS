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
    @State var errorMessage: LocalizedStringResource? = ""

    @State var onClick: () -> Void
    
    @State private var phoneNumberStr = LocalizedStringResource("Phone number")

    var body: some View {
        VStack {
            
            Form {
                Section(displayName){}
                
                Section {
                    TextField(text: $phoneNumber, prompt: Text(phoneNumberStr)) {
                        Text(phoneNumberStr)
                    }
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .autocorrectionDisabled(true)
                    .disabled(showCode || showPassword)
                } header: {
                    Text(phoneNumberStr)
                    Text(errorMessage ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                } footer: {
                    Text(LocalizedStringResource("Enter phone number with dialing code e.g +237123456789"))
                }
                
                if showCode {
                    SecureField(text: $code, prompt: Text(LocalizedStringResource("Code"))) {
                        Text(LocalizedStringResource("Code"))
                    }
                    .disabled(showPassword)
                }
                
                if showPassword {
                    SecureField(text: $password, prompt: Text(LocalizedStringResource("Password"))) {
                        Text(LocalizedStringResource("Password"))
                    }
                }
            }
            
            let buttonText = if !showCode && !showPassword {
                LocalizedStringResource("Request code")
            } else {
                LocalizedStringResource("Submit")
            }
            
            Button(buttonText) {
                onClick()
            }
            .padding()
            .background(Color(.primary))
            .foregroundStyle(Color(.onPrimary))
            .clipShape(Capsule())
            
            if phoneNumber.count > 4 {
                Button(LocalizedStringResource("Already have code")) {
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
