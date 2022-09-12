//
//  PasswordView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/11/22.
//

import SwiftUI

struct PasswordView: View {
    @State public var userPassword: String = ""
    
    public var gatewayServerPublicKey: String;
    public var verificationURL: String;
    
    var body: some View {
        VStack {
            Spacer()
            Text("Enter your password")
                .font(.title)
                .bold()
            
            SecureField("password...", text: $userPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign-in", action: {
                // TODO: encrypt the password with server's pub key
                // TODO: send encrypted password to server
                
                print("Plain password: \(userPassword)")
                print("Gateway server pubkey: \(gatewayServerPublicKey)")
                
                let encryptedPassword = encryptWithRSAKeyPair(
                    publicKeyStr: gatewayServerPublicKey, data: userPassword)
                print("Encrypted password: \(encryptedPassword)")
                
                let synchronization = Synchronization(callbackFunction: { data, response, error in
                    print("data: \(data)")
                    print("response: \(response)")
                })
                
                let task = synchronization.passwordVerification(
                    userPassword: encryptedPassword, verificationURL: verificationURL)
                
                task.resume()
            })
                .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }
}

struct PasswordView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordView(gatewayServerPublicKey: "", verificationURL: "")
    }
}
