//
//  SynchronizeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/9/22.
//

import SwiftUI


func removePEMFormatsInKey(publicKey: String) -> String {
    var formattedPublicKey: String  = publicKey.replacingOccurrences(
        of: "-----BEGIN PUBLIC KEY-----\\n",
        with: "")
    
    formattedPublicKey = formattedPublicKey.replacingOccurrences(
        of: "\\n-----END PUBLIC KEY-----",
        with: "")
    
    return formattedPublicKey
}

struct SynchronizeView: View {
    var gatewayServerURL: String = "";
    @State var syncStatement: String = "Goto sync link"
    
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
                        
                        let gatewayServerPublicKey = removePEMFormatsInKey(publicKey: gatewayPEMPublicKey)
                        
                        print("Gateway Server public-key: \(gatewayServerPublicKey)")
                        
                        
                        let scheme: String = (gatewayServerURLObj?.scheme)!
                        let host: String = (gatewayServerURLObj?.host)!
                        let port: Int = (gatewayServerURLObj?.port)!
                        
                        let verificationURL = "\(scheme)://\(host):\(port)\(verificationPath)"
                        print("Verification URL: \(verificationURL)")
                        
                        // TODO: password should be sent to this URL,
                        // TODO: navigate out of here and ask for the password
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
