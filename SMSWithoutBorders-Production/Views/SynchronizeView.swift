//
//  SynchronizeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/9/22.
//

import SwiftUI
import CoreData


struct SynchronizeView: View {
    @Environment(\.managedObjectContext) var datastore
    
    @State var syncSuccessful = false
    @State var gatewayServerURL: String = "";
    
    @State var gatewayServerPublicKey: String = ""
    @State var verificationURL: String = ""
    
    @State var privateKey: SecKey?
    
    
    var body: some View {
        return Group {
            if syncSuccessful {
                PasswordView(privateKey: privateKey, gatewayServerPublicKey: gatewayServerPublicKey, verificationURL: verificationURL)
                            .environment(\.managedObjectContext, datastore)
                
            }
            else {
                AppContentView(gatewayServerURL: gatewayServerURL, gatewayServerPublicKey: $gatewayServerPublicKey, verificationURL: $verificationURL, syncSuccessful: $syncSuccessful, privateKey: $privateKey)
            }
        }
    }
}

struct AppContentView: View {
    var gatewayServerURL: String;
    
    var smsWithoutBordersSyncUrl = "://smswithoutborders.com/dashboard/sync"
    
    @Binding var gatewayServerPublicKey: String;
    @Binding var verificationURL: String;
    
    @Binding var syncSuccessful: Bool
    
    @Binding var privateKey: SecKey?
    
    var body: some View {
        VStack {
            
            if gatewayServerURL.isEmpty {
                Link("Sign-up", destination: URL(string: "https://smswithoutborders.com/sign-up?ari=" + URL(string: "apps" + smsWithoutBordersSyncUrl)!.absoluteString)!)
                    .buttonStyle(.bordered)
                
                Link("Sign-in", destination: URL(string: "https" + smsWithoutBordersSyncUrl)!)
                    .buttonStyle(.bordered)
            }
            
            else {
                Button("Start Synchronization", action: {
                    // Should use this for signup and login
                    
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
                    
                    do {
                        let keyAssets = try generateRSAKeyPair()
                        
                        let publicKey: String = keyAssets.publicKey
                        privateKey = keyAssets.privateKey
                        
                        let task: URLSessionDataTask = synchronization.publicKeyExchange(
                            publicKey: publicKey, gatewayServerUrl: gatewayServerURL)
                        
                        task.resume()
                    }
                    catch {
                        print("Some error occured: \(error)")
                        return
                    }
                })
                .buttonStyle(.bordered)
            }
        }
    }
}


struct SynchronizeView_Previews: PreviewProvider {
    static var previews: some View {
        SynchronizeView()
    }
}
