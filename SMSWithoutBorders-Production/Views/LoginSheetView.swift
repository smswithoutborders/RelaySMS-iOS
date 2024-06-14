//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

struct LoginSheetView: View {
    @State private var phoneNumber: String = ""
    @State private var password: String = ""

    var body: some View {
        Form {
            TextField("Phone Number (e.g) +237123456789", text: $phoneNumber)
            SecureField("Password", text: $password)
            
            Button("Login") {
                
            }
        }
        
    }
}

#Preview {
    LoginSheetView()
}
