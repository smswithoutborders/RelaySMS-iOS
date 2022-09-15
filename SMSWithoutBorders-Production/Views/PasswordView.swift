//
//  PasswordView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/11/22.
//

import SwiftUI
import CoreData

struct PasswordView: View {
    @Environment(\.managedObjectContext) var datastore
    
    @State var authenticated: Bool = false
    @State var privateKey: SecKey?
    
    @State var gatewayServerPublicKey: String = ""
    @State var verificationURL: String = ""
    
    var body: some View {
        return Group {
            if authenticated {
                AvailablePlatformsView()
                    .environment(\.managedObjectContext, datastore)
            }
            else {
                AppContentPasswordView(privateKey: privateKey, gatewayServerPublicKey: gatewayServerPublicKey, verificationURL: verificationURL, authenticated: $authenticated)
                    .environment(\.managedObjectContext, datastore)
            }
        }
    }
}


struct AppContentPasswordView: View {
    @Environment(\.managedObjectContext) var datastore
    
    @FetchRequest(entity: PlatformsEntity.entity(), sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @State var userPassword: String = ""
    @State var privateKey: SecKey?
    
    @State var gatewayServerPublicKey: String;
    @State var verificationURL: String;
    
    @Binding var authenticated: Bool;
    
    
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
                let encryptedPassword = encryptWithRSAKeyPair(
                    publicKeyStr: gatewayServerPublicKey, data: userPassword)
                
                let synchronization = Synchronization(callbackFunction: { data, response, error in
                    if error != nil {
                        // self.handleClientError(error)
                            // return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode) else {
                        
                        // TODO: show an error message
                        print("Check your password might be wrong")
                        return
                    }
                    
                    let jsonData: [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : Any]
                    
                    // Encrypted shared key, need to decrypt it with private RSA key
                    let sharedKey: String = jsonData["shared_key"] as! String
                    
                    let decryptedSharedKey = decryptWithRSAKeyPair(privateKey: privateKey!, encryptedData: sharedKey)
                    storeSharedKeyInKeyChain(decryptedSharedKey: decryptedSharedKey)
                    
                    
                    let platformsData = jsonData["user_platforms"] as! Array<Dictionary<String, Any>>
                    
                    resetPlatforms(platforms: platforms, datastore: datastore)
                    storePlatforms(platformsData: platformsData, datastore: datastore)
                    self.authenticated = true
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

func resetPlatforms(platforms: FetchedResults<PlatformsEntity>, datastore: NSManagedObjectContext) {
    for platform in platforms {
        datastore.delete(platform)
    }
    print("Datastore reset complete")
}

func storeSharedKeyInKeyChain(decryptedSharedKey: String) {
    print("Decrypted Shared key: \(decryptedSharedKey)")
    
    let cSecurity = CSecurity()
    if !cSecurity.storeInKeyChain(sharedKey: decryptedSharedKey) {
        print("Failed to store shared key, depending on the issue - should modify")
        
        return
    }
    
    print("Stored data in keychain successfully")
}

func storePlatforms(platformsData: Array<Dictionary<String, Any>>, datastore: NSManagedObjectContext) {
    for platformData in platformsData {
        let platform = PlatformsEntity(context: datastore)
        platform.platform_name = platformData["name"] as? String
        platform.type = platformData["type"] as? String
        platform.platform_letter = platformData["letter"] as? String
        
        print("Storing platform: \(String(describing: platform.platform_name))")
            
        do {
            try datastore.save()
        }
        catch {
            print("Failed to store platform: \(error)")
        }
    }
}

struct PasswordView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordView()
    }
}
