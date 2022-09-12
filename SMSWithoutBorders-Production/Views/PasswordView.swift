//
//  PasswordView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/11/22.
//

import SwiftUI

struct PasswordView: View {
    @State public var userPassword: String = ""
    
    @State var privateKey: SecKey?
    
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
                    
                    if let error = error {
                        // self.handleClientError(error)
                            // return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode) else {
                        
                        // TODO: show an error message
                        return
                    }
                    
                    let jsonData: [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : Any]
                    
                    // Encrypted shared key, need to decrypt it with private RSA key
                    let sharedKey: String = jsonData["shared_key"] as! String
                    print(jsonData)
                    
                    print("My private key: \(privateKey)")
                    
                    let decryptedSharedKey = decryptWithRSAKeyPair(privateKey: privateKey!, encryptedData: sharedKey)
                    print("Decrypted Shared key: \(decryptedSharedKey)")
                    
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
