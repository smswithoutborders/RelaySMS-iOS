//
//  SynchronizeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/9/22.
//

import SwiftUI



struct SynchronizeView: View {
    @State var syncSuccessful = false
    @State var gatewayServerURL: String = "";
    @State var syncStatement: String = "Sync Account now"
    
    @State var gatewayServerPublicKey: String = ""
    @State var verificationURL: String = ""
    
    var body: some View {
        return Group {
            if syncSuccessful {
                PasswordView(gatewayServerPublicKey: gatewayServerPublicKey, verificationURL: verificationURL)
            }
            else {
                AppContentView(gatewayServerURL: gatewayServerURL, syncStatement: syncStatement, gatewayServerPublicKey: $gatewayServerPublicKey, verificationURL: $verificationURL, syncSuccessful: $syncSuccessful)
            }
        }
    }
}

struct AppContentView: View {
    var gatewayServerURL: String;
    var syncStatement: String
    
    @Binding var gatewayServerPublicKey: String;
    @Binding var verificationURL: String;
    
    @Binding var syncSuccessful: Bool
    
    var body: some View {
        VStack {
            Button(syncStatement, action: {
                // Should use this for signup and login
                // UIApplication.shared.open(NSURL(string: gatewayServerURL)! as URL)
                
                let gatewayServerURLObj = URL(string: self.gatewayServerURL)
                if(gatewayServerURLObj == nil) {
                    print("Not valid gateway server url")
                    return
                }
                
                let synchronization = Synchronization(callbackFunction: { data, response, error in
                    do {
                        let jsonData: [String:String] = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : String]
                        
                        let gatewayPEMPublicKey: String = jsonData["public_key"]!;
                        let verificationPath: String = jsonData["verification_url"]!;
                        
                        
                        
                        let scheme: String = (gatewayServerURLObj?.scheme)!
                        let host: String = (gatewayServerURLObj?.host)!
                        let port: Int = (gatewayServerURLObj?.port)!
                        
                        self.gatewayServerPublicKey = removePEMFormatsInKey(publicKey: gatewayPEMPublicKey)
                        self.verificationURL = "\(scheme)://\(host):\(port)\(verificationPath)"
                        
                        print("Gateway Server public-key: \(gatewayServerPublicKey)")
                        print("Verification URL: \(verificationURL)")
                        self.syncSuccessful = true
                    }
                    catch {
                        print("Some error occured: \(error)")
                    }
                })
                
                let task: URLSessionDataTask = synchronization.publicKeyExchange(
                    gatewayServerUrl: gatewayServerURL)
                
                task.resume()
                
            })
            .buttonStyle(.bordered)
        }
    }
}


struct SynchronizeView_Previews: PreviewProvider {
    static var previews: some View {
        SynchronizeView()
    }
}
